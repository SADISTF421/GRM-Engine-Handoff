#include "r1_common.h"

struct vf
{
	float4 hpos	: POSITION;
	float2 tc0	: TEXCOORD0;
	float3 c0	: COLOR0;
};

vf main (v_lmap v)
{
	vf 		o;

	
	o.hpos 		= mul			(m_VP, v.pos);	// xform, input in world coords
	o.tc0		= unpack_tc_lmap	(v.tc1);	// copy tc 
	o.c0		= L_hemi_color*v.norm.w + L_ambient;	// just hemisphere + ambient

	return o;
}
