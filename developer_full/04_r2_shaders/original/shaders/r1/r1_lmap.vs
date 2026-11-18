#include "r1_common.h"

struct vf
{
	float4 hpos	: POSITION;
	float2 tc0	: TEXCOORD0;
	float2 tc1	: TEXCOORD1;
	float3 c0	: COLOR0;		// c0=hemi+v-lights, 	c0.a = dt*
	float3 c1	: COLOR1;		// c1=sun, 		c1.a = dt+
	float  fog	: FOG;
};

vf main (v_lmap v)
{
	vf 		o;

	o.hpos 		= mul			(m_VP, v.pos);			// xform, input in world coords
	o.tc0		= unpack_tc_base	(v.tc0);			// copy tc
	o.tc1		= unpack_tc_lmap	(v.tc1);			// copy tc 
	o.c0		= L_hemi_color*v.norm.w+L_ambient;			// just hemisphere
	o.c1 		= L_sun_color*dot(unpack_normal(v.norm),-L_sun_dir_w);  // sun
	o.fog 		= calc_fogging 		(v.pos);			// fog, input in world coords

	return o;
}
