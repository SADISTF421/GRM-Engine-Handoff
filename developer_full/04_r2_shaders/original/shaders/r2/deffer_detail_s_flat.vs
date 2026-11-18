#include "common.h"
#include "grm_grass_view_bend.h"

uniform float4 		consts; // {1/quant,1/quant,diffusescale,ambient}
uniform float4 		array	[200] : register(c12);

p_flat 	main (v_detail v)
{
	p_flat 		O;
	// index
	int 	i 	= v.misc.w;
	float4  m0 	= array[i+0];
	float4  m1 	= array[i+1];
	float4  m2 	= array[i+2];
	float4  c0 	= array[i+3];

	// Transform pos to world coords
	float4 	pos;
 	pos.x 		= dot	(m0, v.pos);
 	pos.y 		= dot	(m1, v.pos);
 	pos.z 		= dot	(m2, v.pos);
	pos.w 		= 1;
	// Нормаль освещения берём до ветра и пригибания.
	float3 grm_light_pos = pos.xyz;

	// Проверка: временно без пригибания травы возле камеры.

	// Normal in world coords
	float3 	norm;	
		norm.x 	= grm_light_pos.x - m0.w	;
		norm.y 	= grm_light_pos.y - m1.w	+ .75f;	// avoid zero
		norm.z	= grm_light_pos.z - m2.w	;

	// Final out
	float4	Pp 	= mul		(m_WVP,	pos				);
	O.hpos 		= Pp;
	O.N 		= mul		(m_WV,  normalize(norm)	);
	float3	Pe	= mul		(m_WV,  pos				);
	O.tcdh 		= float4	((v.misc * consts).xyyy	);

# if defined(USE_R2_STATIC_SUN)
	O.tcdh.w	= c0.x;								// (,,,dir-occlusion)
# endif

#ifdef USE_GRASS_WAVE
    // Та же неподвижная вариация для неподвижных деталей.
    float grm_hash = sin(dot(float2(m0.w,m2.w), float2(12.9898f,78.233f))) * 43758.5453f;
    float grm_var = grm_hash - floor(grm_hash);
    O.tcdh.z = 0.96f + 0.08f * grm_var;
#endif

	O.position	= float4	(Pe, 		c0.w		);

	return O;
}
FXVS;
