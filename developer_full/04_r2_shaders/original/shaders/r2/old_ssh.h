#ifndef OLD_SSH_H
	#define OLD_SSH_H

	#include "common.h"
	
	// 22:08 07.01.2016
	#if !defined(SSO_QUALITY)		// dis
		#define RAY_SAMPLES int(20)
	#elif SSO_QUALITY==1		// low
		#define RAY_SAMPLES int(15)
	#elif SSO_QUALITY==2		// high
		#define RAY_SAMPLES int(20)
	#endif	
	
//////////////////////////////////////////////////////////////////////////////////////////
// The below code is copyright of Sky4CE

float4 	SunShafts (float2 tc , float4 tcJ )
{	
	float3 P = tex2D(s_position, tc).xyz;
	float4	J0 	= tex2D		(jitter0,tcJ);
	float coeff = (RAY_SAMPLES - 2*J0.x)/(RAY_SAMPLES*RAY_SAMPLES) ;		
	float3 direction = P*coeff;
	float4 current	= mul (m_shadow,float4(P,1));
	float4 delta 	= mul (m_shadow, float4(direction,0));
	float res = 0;
	float density = (SSO_INTENSITY * sunshafts_params.x)/RAY_SAMPLES;
	for ( int i=0; i<RAY_SAMPLES; ++i )
	{
	#ifdef	USE_HWSMAP
		#ifdef USE_FETCH4
			res += density*( sample_hw_f4(current,float4(0,0,0,0)) );
			#else
			res += density*( sample_hw_pcf(current,float4(0,0,0,0)) );
			#endif
	#else
			res += density*( sample_sw(current.xy/current.w,float2(0,0),current.z) );
	#endif
			current -= delta;
	}
	return res*Ldynamic_color;
}	
	
#endif // OLD_SSH_H	