#include "sl_r1_test1.h"
uniform float3x4	m_W;
uniform float3x4	m_V;
uniform float3x4	m_WV;
uniform float4x4 	m_VP;
uniform float4x4 	m_WVP;
uniform float4x4 	m_spot;
uniform half4		fog_plane;
uniform	half2		fog_params;
uniform half3		L_sun_color;
uniform half3		L_sun_dir_w;
uniform half3		L_sun_dir_e;
uniform half3		L_lmap_color;
uniform half3		L_hemi_color;
uniform half3		L_ambient;
uniform half3		L_dynamic_color;	// dynamic light color 		- spot/point
uniform half4		L_dynamic_pos;		// dynamic light pos+1/range(w) - spot/point
uniform float3 		eye_position;
uniform half3		eye_direction;
uniform half3		eye_normal;
uniform	half4 		dt_params;

half3 	unpack_normal	(half3 v)	{ return 2.f*v-1.f; 		}
half2 	unpack_tc_base	(half2 tc)	{ return tc;			} // [uncompressed]
half2 	unpack_tc_lmap	(half2 tc)	{ return tc*(1.f/32768.f);	} // [-1  .. +1 ]
half  	calc_fogging 	(half4 w_pos)	{ 
	// Базовый расчет фактора тумана
	half fog = 1 - (dot(w_pos, fog_plane) - fog_params.x) * fog_params.y; 
	
	// ДЕПРЕССИЯ: Делаем туман более "вязким" на расстоянии через S-образную кривую.
	// При этом не заваливаем его в полную слепоту (saturate удержит значения в рамках 0..1).
	fog = saturate(fog);
	return fog * fog * (3.0h - 2.0h * fog); 
}

//half  	calc_fogging 	(half4 w_pos)	{ return 1-dot(w_pos,fog_plane); }
half2 	calc_detail 	(half3 w_pos)	{ 
	float  	dtl	= distance(w_pos,eye_position)*dt_params.w;
		dtl	= min(dtl*dtl, 1);
	half  	dt_mul	= 1  - dtl;	// dt*  [1 ..  0 ]
	half  	dt_add	= .5 * dtl;	// dt+	[0 .. 0.5]
	return	half2	(dt_mul,dt_add);
}
float2 	calc_xz_wave 	(float2 dir2D, float frac)		{
	// Beizer
	float2  ctrl_A	= float2(0.f,		0.f	);
	float2 	ctrl_B	= float2(dir2D.x,	dir2D.y	);
	return  lerp	(ctrl_A, ctrl_B, frac);
}
float3 	calc_spot 	(out float2 tc, float4 w_pos, float3 w_norm)	{
	float4 	s_pos	= mul	(m_spot, w_pos);
	tc 		= s_pos.xy/s_pos.w;
	float3 	L_dir 	= w_pos - L_dynamic_pos.xyz;
	float 	L_dir_l	= length(L_dir);
	float3 	L_dir_n = L_dir/L_dir_l;
	float 	L_scale	= dot(w_norm,-L_dir_n);
	float 	L_att	= 1 - L_dir_l * L_dynamic_pos.w;
	return 	L_dynamic_color*max(L_scale,0)*max(L_att,0)*saturate(calc_fogging(w_pos));
}

struct 	v_lmap
{
	float4 	pos	: POSITION;	// (float,float,float,1)
	float4	norm	: NORMAL;	// (nx,ny,nz,hemi occlusion)
	float2 	tc0	: TEXCOORD0;	// (base)
	float2	tc1	: TEXCOORD1;	// (lmap/compressed)
};
struct	v_vert
{
	float4 	pos	: POSITION;	// (float,float,float,1)
	float4	norm	: NORMAL;	// (nx,ny,nz,hemi occlusion)
	float4	color	: COLOR0;	// (r,g,b,dir-occlusion)
	float2 	tc	: TEXCOORD0;	// (u0,v0)
};
struct 	v_model
{
	float4 	pos	: POSITION;	// (float,float,float,1)
	float3	norm	: NORMAL;	// (nx,ny,nz)
	float2	tc	: TEXCOORD0;	// (u,v)
};

//////////////////////////////////////////////////////////////////////////////////////////
uniform sampler2D 	s_lmap;
uniform sampler2D 	s_base;
uniform sampler2D 	s_detail;
