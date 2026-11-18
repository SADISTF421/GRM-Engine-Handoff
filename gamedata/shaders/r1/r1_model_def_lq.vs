#include "r1_common.h"

struct vf
{
	float4 hpos	: POSITION;
	float2 tc0	: TEXCOORD0;		// base
	float3 c0	: COLOR0;		// color
	float  fog	: FOG;
};

vf main (v_model v)
{
	vf 		o;

	float4 	pos 	= v.pos;
	float3  pos_w 	= mul			(m_W, pos);
	float3 	norm_w 	= normalize 		(mul(m_W,v.norm));

	o.hpos 		= mul			(m_WVP, pos);		// xform, input in world coords
	o.tc0		= v.tc.xy;					// copy tc
	o.c0 		= (norm_w.y*0.25f+0.75f)*SL_R1_MODEL_HEMI_MIN*L_hemi_color + SL_R1_MODEL_AMB_GAIN*L_ambient + 0.5f*L_sun_color*max(dot(norm_w,-L_sun_dir_w),0.0f);  	// sun
	o.fog 		= calc_fogging 		(float4(pos_w,1));	// fog, input in world coords

	return o;
}
