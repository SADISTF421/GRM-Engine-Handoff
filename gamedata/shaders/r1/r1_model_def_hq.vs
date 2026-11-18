#include "r1_common.h"

struct vf
{
	float4 hpos	: POSITION;
	float2 tc0	: TEXCOORD0;		// base
	float2 tc1	: TEXCOORD1;		// projected lmap
	float3 c0	: COLOR0;		// sun-color
	float  fog	: FOG;
};

uniform float4x4	m_plmap_xform;
uniform float4 		m_plmap_clamp;

vf main (v_model v)
{
	vf 		o;

	float4 	pos 	= v.pos;
	float3  pos_w 	= mul			(m_W, pos);
	float4  pos_w4 	= float4		(pos_w,1);
	float3 	norm_w 	= normalize 		(mul(m_W,v.norm));
	float4 	plmap 	= mul			(m_plmap_xform,pos_w4);	// calc plmap tc

	o.hpos 		= mul			(m_WVP, pos);		// xform, input in world coords
	o.tc0		= v.tc.xy;					// copy tc
	o.tc1		= clamp(plmap.xy / plmap.w, m_plmap_clamp.xy, m_plmap_clamp.zw);
	o.c0 		= L_sun_color*dot((norm_w),-L_sun_dir_w);  	// sun
	o.fog 		= calc_fogging 		(pos_w4);		// fog, input in world coords

	return o;
}
