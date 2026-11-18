#ifndef SLOAD_H
#define SLOAD_H

#include "common.h"

// Native GRM HQ _bump_d wrappers mark s_detail as packed bump data.
// Do not multiply albedo or detail-alpha gloss by that texture.
// Keep the base s_bump/s_bumpX normal, gloss, height and parallax unchanged.
// Flat / single-detail terrain and ordinary diffuse-detail paths stay unchanged.

//////////////////////////////////////////////////////////////////////////////////////////
// Bumped surface loader                //
//////////////////////////////////////////////////////////////////////////////////////////
struct        surface_bumped
{
        half4         	base;
        half3         	normal;
        half         	gloss;
        half         	height;
};

half4   tbase                 (float2 tc)        {
        return                 tex2D                (s_base,         tc);
}


#ifdef         USE_PARALLAX
surface_bumped                sload_i         ( p_bumped I)        // + texld, mad, nrm(3), mad  = 1+1+3+1 = 6, 15+6=21, OK
{
        surface_bumped      S;
        // Ограниченный POM для рельефных материалов R2: 4 шага и интерполяция.
        // Действует только там, где включён USE_PARALLAX и привязан s_bumpX.
        float grm_eye_len2 = dot(I.eye, I.eye);
        float2 grm_eye_xy = I.eye.xy * rsqrt(max(grm_eye_len2, 0.0001f));
        float grm_fade = 1.0f - smoothstep(25.0f, 55.0f, abs(I.position.z));
        float2 grm_ray = clamp(parallax.x * grm_eye_xy * grm_fade, -0.04f, 0.04f);
        float2 grm_start = I.tcdh.xy + 0.5f * grm_ray;
        float2 grm_prev_uv = grm_start;
        float grm_prev_d = saturate(tex2D(s_bumpX, grm_start).w) - 1.0f;
        float2 grm_hit_uv = grm_start - grm_ray;
        float grm_found = 0.0f;
        // Шаг 1/4: развёрнут вручную для компилятора DirectX 9.
        float2 grm_uv1 = grm_start - grm_ray * 0.25f;
        float grm_d1 = saturate(tex2D(s_bumpX, grm_uv1).w) + 0.25f - 1.0f;
        float grm_cross1 = (1.0f - grm_found) * step(0.0f, grm_d1);
        float grm_fraction1 = saturate(-grm_prev_d / max(grm_d1 - grm_prev_d, 0.0001f));
        grm_hit_uv = lerp(grm_hit_uv, lerp(grm_prev_uv, grm_uv1, grm_fraction1), grm_cross1);
        grm_found += grm_cross1;
        grm_prev_uv = grm_uv1;
        grm_prev_d = grm_d1;
        // Шаг 2/4: развёрнут вручную для компилятора DirectX 9.
        float2 grm_uv2 = grm_start - grm_ray * 0.50f;
        float grm_d2 = saturate(tex2D(s_bumpX, grm_uv2).w) + 0.50f - 1.0f;
        float grm_cross2 = (1.0f - grm_found) * step(0.0f, grm_d2);
        float grm_fraction2 = saturate(-grm_prev_d / max(grm_d2 - grm_prev_d, 0.0001f));
        grm_hit_uv = lerp(grm_hit_uv, lerp(grm_prev_uv, grm_uv2, grm_fraction2), grm_cross2);
        grm_found += grm_cross2;
        grm_prev_uv = grm_uv2;
        grm_prev_d = grm_d2;
        // Шаг 3/4: развёрнут вручную для компилятора DirectX 9.
        float2 grm_uv3 = grm_start - grm_ray * 0.75f;
        float grm_d3 = saturate(tex2D(s_bumpX, grm_uv3).w) + 0.75f - 1.0f;
        float grm_cross3 = (1.0f - grm_found) * step(0.0f, grm_d3);
        float grm_fraction3 = saturate(-grm_prev_d / max(grm_d3 - grm_prev_d, 0.0001f));
        grm_hit_uv = lerp(grm_hit_uv, lerp(grm_prev_uv, grm_uv3, grm_fraction3), grm_cross3);
        grm_found += grm_cross3;
        grm_prev_uv = grm_uv3;
        grm_prev_d = grm_d3;
        // Шаг 4/4: развёрнут вручную для компилятора DirectX 9.
        float2 grm_uv4 = grm_start - grm_ray * 1.00f;
        float grm_d4 = saturate(tex2D(s_bumpX, grm_uv4).w) + 1.00f - 1.0f;
        float grm_cross4 = (1.0f - grm_found) * step(0.0f, grm_d4);
        float grm_fraction4 = saturate(-grm_prev_d / max(grm_d4 - grm_prev_d, 0.0001f));
        grm_hit_uv = lerp(grm_hit_uv, lerp(grm_prev_uv, grm_uv4, grm_fraction4), grm_cross4);
        grm_found += grm_cross4;
        grm_prev_uv = grm_uv4;
        grm_prev_d = grm_d4;
        float2 new_tc = grm_hit_uv;
        half4       Nu      =       tex2D		(s_bump,         new_tc);                // IN:  normal.gloss
        half4       NuE     =       tex2D      	(s_bumpX,       new_tc);                // IN:         normal_error.height
        S.base              =       tbase                (new_tc);                                // IN:  rgb.a
        S.normal            = 		Nu.wzyx + (NuE.xyz - 1.0h);							 // (Nu.wzyx - .5h) + (E-.5)
        S.gloss             =       Nu.x	;                                        //        S.gloss             =        Nu.x*Nu.x;
        //S.gloss           =       Nu.x*Nu.x	;                                        //        S.gloss             =        Nu.x*Nu.x;

        S.height            =       NuE.z       ;

	#if defined(USE_TDETAIL) && !defined(F42_GRM_DETAIL_IS_BUMP)
        // Совмещаю детализацию с тем же смещением, что и основную текстуру.
        float2 grm_detail_uv = I.tcdbump + (new_tc - I.tcdh.xy) * dt_params.xy;
        half4       detail  = tex2D(s_detail, grm_detail_uv);
        S.base.rgb = S.base.rgb * det_fix(detail.rgb, s_detail, grm_detail_uv) * 2;
        S.gloss = S.gloss * f42_detail_gloss(detail, s_detail, grm_detail_uv);
	#endif//USE_TDETAIL

        return                S;
}
#else //USE_PARALLAX
surface_bumped                sload_i         ( p_bumped I)
{
        surface_bumped        S;
        half4 Nu 			=		tex2D                (s_bump, I.tcdh);                        // IN:  normal.gloss
        half4 NuE           =		tex2D                (s_bumpX,I.tcdh);                        // IN:         normal_error.height
        S.base              =		tbase                (I.tcdh)		;                         // IN:  rgb.a
        S.normal            =		Nu.wzyx + (NuE.xyz - 1.0h)			;
        S.gloss             =		Nu.x							;                         //        S.gloss             =        Nu.x*Nu.x;
        S.height            = 		NuE.z;

	#if defined(USE_TDETAIL) && !defined(F42_GRM_DETAIL_IS_BUMP)

	#ifdef USE_TDETAIL_BUMP
	half4 NDetail		= tex2D( s_detailBump, I.tcdbump);
	half4 NDetailX		= tex2D( s_detailBumpX, I.tcdbump);
	S.gloss				= S.gloss * NDetail.x * 2;
	S.normal			+= NDetail.wzy + NDetailX.xyz - 1.0h; //	(Nu.wzyx - .5h) + (E-.5)
	half4 detail		= tex2D( s_detail, I.tcdbump);
	S.base.rgb			= S.base.rgb * det_fix(detail.rgb, s_detail, I.tcdbump) * 2;
	#else //USE_TDETAIL_BUMP

        half4 detail		=        tex2D(s_detail,I.tcdbump)    ;
        S.base.rgb          =      	S.base.rgb*det_fix(detail.rgb, s_detail, I.tcdbump)        	*2      ;
        S.gloss = S.gloss * f42_detail_gloss(detail,s_detail,I.tcdbump);
	#endif //USE_TDETAIL_BUMP

	#endif //USE_TDETAIL

        return              S;
}
#endif //USE_PARALLAX


surface_bumped		sload	 	( p_bumped I)
{
	surface_bumped	S 	= sload_i(I);

	#ifdef USE_SHARP_BUMP
	//из ЧН усиление мелкого бампа. Чем меньше, тем сильнее эффект.
	S.normal.z *=	0.5; //. make bump twice as contrast (fake, remove me if possible)
	// S.normal.z *=0.25;//перебор
	#endif //USE_SHARP_BUMP

    // Gloss only: preserve base RGB, normal, height and parallax from new sources.
    S.gloss = f42_gloss_response(S.gloss);

	return	S;
}

#endif//#ifndef SLOAD_H
