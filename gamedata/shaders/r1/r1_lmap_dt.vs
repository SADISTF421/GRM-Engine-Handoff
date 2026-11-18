#include "r1_common.h"

struct vf
{
	float4 hpos	: POSITION;
	float2 tc0	: TEXCOORD0;
	float2 tc1	: TEXCOORD1;
	float2 tc2	: TEXCOORD2;
	float4 c0	: COLOR0;		// c0=hemi+v-lights, 	c0.a = dt*
	float4 c1	: COLOR1;		// c1=sun, 		c1.a = dt+
	float  fog	: FOG;
};

vf main (v_lmap v)
{
	vf 		o;

	float2 	dt 	= calc_detail		(v.pos);
	float3  L_hemi  = L_hemi_color*v.norm.w+L_ambient;			// just hemisphere
	float3  L_sun 	= L_sun_color*dot(unpack_normal(v.norm),-L_sun_dir_w);  // sun
	
	o.hpos 		= mul			(m_VP, v.pos);			// xform, input in world coords
	o.tc0		= unpack_tc_base	(v.tc0);			// copy tc
	o.tc1		= unpack_tc_lmap	(v.tc1);			// copy tc 
	o.tc2		= o.tc0*dt_params;					// dt tc
	o.c0		= float4 		(L_hemi,dt.x);			// c0=hemi+v-lights, 	c0.a = dt*
	o.c1 		= float4 		(L_sun,	dt.y);			// c1=sun, 		c1.a = dt+
	o.fog 		= calc_fogging 		(v.pos);			// fog, input in world coords

	return o;
}
