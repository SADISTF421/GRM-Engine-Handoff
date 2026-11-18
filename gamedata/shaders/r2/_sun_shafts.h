/*  Volumetric Sunlights aka GodRays aka Sunshafts
	made by K.D. (OGSE team)
	used papers:
	1) GPU Gems 3. Volumetric Light Scattering as a Post-Process (Kenny Mitchell)
	2) Реализация процессора эффектов постобработки. Часть 2 - Создание пост-эффектов. (Владимир Дьячков «Nikola Tesla»)
	3) Crysis shaders :)  */

#ifndef	_SUN_SHAFTS_H
	#define _SUN_SHAFTS_H
	
	// 21:42 07.01.2016
	
	#include "common.h"
	
	//#define USE_SUN_SHAFTS
	#define SS_FARPLANE float(180.0)
	//#define SS_DENSITY 1.1
	//#define SS_SAMPLES 100
	//#define SS_BLEND_FACTOR 0.9
	//#define SS_BLUR
	
	#if !defined(SS_QUALITY)		// dis
		#define SS_SAMPLES int(120)
	#elif SS_QUALITY==1				// low
		#define SS_SAMPLES int(80)
	#elif SS_QUALITY==2			// medium
		#define SS_SAMPLES int(100)
	#elif SS_QUALITY==3	// high
		#define SS_SAMPLES int(120)
	#endif	// SS_QUALITY

	uniform float4 		common_params2;
	uniform sampler2D 		s_jitter_0;			// 	стандартный шум, 64x64
	uniform sampler2D 		s_jitter_1;			// 	стандартный шум, 64x64
	uniform sampler2D 		s_jitter_5;			// 	шум высокого разрешения, 1024x1024
		
	float normalize_depth(float depth) {
		return (saturate(depth/SS_FARPLANE));
	}
	
	float3 blend_soft_light(float3 a, float3 b) {
		float3 c = 2 * a * b + a * a * (1 - 2 * b);
		float3 d = sqrt(a) * (2 * b - 1) + 2 * a * (1 - b);
		return ( b < 0.5 )? c : d;
	}
	
//	uniform float4 		sunshafts_params; 		// x - intensity; y - density

	float3 sunshafts(float2 tc, float3 init_color) {  
		float3 out_color = float3(0,0,0);
		float sun_dist = SS_FARPLANE / (sqrt(1 - L_sun_dir_w.y * L_sun_dir_w.y));
		float4 sun_pos_projected = mul( m_VP, float4( sun_dist * L_sun_dir_w + eye_position, 1 ) );
		float4 sun_pos_screen = convert_to_screen_space(sun_pos_projected)/sun_pos_projected.w;
		float2 sun_vec_screen = sun_pos_screen.xy - tc;

		float angle_cos = dot(-eye_direction, normalize(L_sun_dir_w));
		float ray_fade = saturate(saturate(angle_cos)*(1 - saturate(sun_vec_screen))*saturate(length(sun_vec_screen)*1000));
		float2 init_tc = tc;
			
		float3 pos = tex2D(s_position, tc);
		float dep = pos.z;
		float mask = (saturate(angle_cos*0.1 + 0.9) + normalize_depth(pos.z) - 0.99999) * (SS_LENGHT * sunshafts_params.y);
		sun_vec_screen *= angle_cos * (SS_LENGHT * sunshafts_params.y ) / SS_SAMPLES;
		float depth_accum = 0;
		
		for (float i = 0; i < SS_SAMPLES; i++) { 
			tc += sun_vec_screen;
			#if defined(SS_BLUR) && !defined(SS_DUST)
				float blur_delta = 2 * (.5f/1024.f);	
				out_color += (tex2Dlod(s_image, float4(tc + blur_delta,0,0)) + tex2Dlod(s_image, float4(tc - blur_delta,0,0))) * (1.f/2.f) * SS_BLEND_FACTOR;
			#else // SS_BLUR
				out_color += SS_OUTCOLOR_COEFF;
			#endif // SS_BLUR
			depth_accum += saturate(1 - tex2D(s_position, tc).z*1000);
		}			
		out_color *= saturate(depth_accum/SS_SAMPLES);
	#if defined(SS_DUST) && !defined(SS_BLUR)
		float dust_size = 8/SS_DUST_SIZE;
		float3 jit;
		float2 jtc = init_tc;
		float2 sun_dir_e = L_sun_dir_e.xy;
		sun_dir_e /= sin(common_params2.x);
		sun_dir_e *= common_params2.y;
		jtc.x += sun_dir_e.x;
		jtc.y -= sun_dir_e.y;
		jtc.x = (jtc.x > 1.0)?(jtc.x-1.0):jtc.x;
		jtc.y = (jtc.y < 0.0)?(1.0-jtc.y):jtc.y;
		jit.x = tex2D(s_jitter_0, float2(jtc.x, jtc.y + timers.x*0.01*SS_DUST_SPEED)*dust_size).x;
		jit.y = tex2D(s_jitter_1, float2(jtc.x + timers.x*0.01*SS_DUST_SPEED, jtc.y)*dust_size).y;
		jit.z = tex2D(s_jitter_5, jtc).x;
		jit.z = saturate(jit.z + SS_DUST_DENSITY - 1);
		float3 dust = saturate(float3(jit.x, jit.x, jit.x)*float3(jit.y, jit.y, jit.y)*float3(jit.z, jit.z, jit.z));
		float len = length(dust);
		dust *= SS_DUST_INTENSITY;
		dust = lerp(0, dust, (1 - saturate(dep * 0.2)) * (1 - saturate((0.001 - dep)*10000.0)));
		dust += float3(1,1,1);
	#else // SS_DUST
		float3 dust = float3(1,1,1);
	#endif // SS_DUST
		out_color *= 2 * ray_fade / SS_SAMPLES * dust;
		out_color = init_color + out_color * L_sun_color * ((SS_INTENSITY * sunshafts_params.x) - init_color);
		out_color = blend_soft_light(out_color, L_sun_color * mask * -0.1 + 0.5) - init_color;
		return out_color;
	}  
	float3 calc_sunshafts(float2 tc, float3 init_color) {
		#ifndef	SS_QUALITY
			return 0;
		#else // SS_QUALITY
			if(sunshafts_params.x && sunshafts_params.y > 0.0) {
				return sunshafts(tc, init_color);
				
			} else {
				return 0;
				
			}
			//return sunshafts(tc, init_color);
		#endif	// SS_QUALITY
	}	
#endif // _SUN_SHAFTS_H