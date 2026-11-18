#ifndef AO_H
	#define AO_H
	
	// 16:24 07.01.2016
	
	// implementation by daemonjax
	#define SSAO_PASSES int(5)				// amount of SSAO sample passes.  Each pass takes 6 samples. Use a minimum of two (since actual number of passes is one less than this number)
//	#define SSAO_HIGH_QUALITY					// increases the number of unique samples for each pass to 12
	#define SAO_DENSITY int(1024)	// higher values increase sao definitition while reducing its size. No performance cost.  As you increase the number of passes,  you'll want to increase density
	
	// for testing
//	#define SSAO_NOLOOP					// performs only 1 pass.  Same as SSAO_PASSES = 2, except it also removes the forloop in the code.  If defined, SSAO_PASSES has no effect
	
//////////////////////////////////////////////////////////////////////////////////////////
// daemonjax' SSAO algorithm

float calc_ssao (float3 P, float3 N, float2 tc)
{
//	#ifndef SSAO
//		return 1.h;
//	#else
		
		float2 scale = float2(.5f / SAO_DENSITY, .67f / SAO_DENSITY)*(150/max(P.z,1.3));
		
		float 	occ	 = 0.0h;	
		float num_dir = 0.0h;
		
		#ifndef SSAO_NOLOOP
		for (int a = 1; a < SSAO_PASSES; ++a)
		#else
			int a = 1;
		#endif
		{
			float2	scale_tmp = scale*a;		
			float3 	dir 	= tex2D	(s_position,tc + float2(-0.416212f, -0.665810f)*scale_tmp).xyz-P.xyz;
			float 	occ_factor = saturate(length(dir));
			float 	infl 	= saturate(dot(normalize(dir), N.xyz));
			
			occ += (infl+0.01)*lerp( 1, occ_factor, infl)/(occ_factor+0.1);
			num_dir += (infl+0.01)/(occ_factor+0.1);		

			
			dir 	= tex2D	(s_position,tc +float2(0.432340f,-0.093580f)*scale_tmp).xyz-P.xyz;
			occ_factor = saturate(length(dir));
			infl 	= saturate(dot(normalize(dir), N.xyz));			
			occ += (infl+0.01)*lerp( 1, occ_factor, infl)/(occ_factor+0.1);
			num_dir += (infl+0.01)/(occ_factor+0.1);
			
			dir 	= tex2D	(s_position,tc +float2(-0.455914f,0.647137f)*scale_tmp).xyz-P.xyz;
			occ_factor = saturate(length(dir));
			infl 	= saturate(dot(normalize(dir), N.xyz));			
			occ += (infl+0.01)*lerp( 1, occ_factor, infl)/(occ_factor+0.1);
			num_dir += (infl+0.01)/(occ_factor+0.1);
			
			dir 	= tex2D	(s_position,tc +float2(0.479456f,0.627022f)*scale_tmp).xyz-P.xyz;
			occ_factor = saturate(length(dir));
			infl 	= saturate(dot(normalize(dir), N.xyz));			
			occ += (infl+0.01)*lerp( 1, occ_factor, infl)/(occ_factor+0.1);
			num_dir += (infl+0.01)/(occ_factor+0.1);
						
			dir 	= tex2D	(s_position,tc +float2(-0.492340f,0.090983f)*scale_tmp).xyz-P.xyz;
			occ_factor = saturate(length(dir));
			infl 	= saturate(dot(normalize(dir), N.xyz));			
			occ += (infl+0.01)*lerp( 1, occ_factor, infl)/(occ_factor+0.1);
			num_dir += (infl+0.01)/(occ_factor+0.1);
			
			dir 	= tex2D	(s_position,tc +float2(0.413434f,-0.680026f)*scale_tmp).xyz-P.xyz;
			occ_factor = saturate(length(dir));
			infl 	= saturate(dot(normalize(dir), N.xyz));			
			occ += (infl+0.01)*lerp( 1, occ_factor, infl)/(occ_factor+0.1);
			num_dir += (infl+0.01)/(occ_factor+0.1);
						
			#ifdef SSAO_HIGH_QUALITY
			
				dir 	= tex2D	(s_position,tc +float2(0.726212f, 0.305810f)*scale_tmp).xyz-P.xyz;
				occ_factor = saturate(length(dir));
				infl 	= saturate(dot(normalize(dir), N.xyz));			
				occ += (infl+0.01)*lerp( 1, occ_factor, infl)/(occ_factor+0.1);
				num_dir += (infl+0.01)/(occ_factor+0.1);
				
				dir 	= tex2D	(s_position,tc +float2(-0.742340f,0.173580f)*scale_tmp).xyz-P.xyz;
				occ_factor = saturate(length(dir));
				infl 	= saturate(dot(normalize(dir), N.xyz));			
				occ += (infl+0.01)*lerp( 1, occ_factor, infl)/(occ_factor+0.1);
				num_dir += (infl+0.01)/(occ_factor+0.1);
				
				dir 	= tex2D	(s_position,tc +float2(0.395914f,-0.757137f)*scale_tmp).xyz-P.xyz;
				occ_factor = saturate(length(dir));
				infl 	= saturate(dot(normalize(dir), N.xyz));			
				occ += (infl+0.01)*lerp( 1, occ_factor, infl)/(occ_factor+0.1);
				num_dir += (infl+0.01)/(occ_factor+0.1);
				
				dir 	= tex2D	(s_position,tc +float2(-0.719456f,-0.367022f)*scale_tmp).xyz-P.xyz;
				occ_factor = saturate(length(dir));
				infl 	= saturate(dot(normalize(dir), N.xyz));			
				occ += (infl+0.01)*lerp( 1, occ_factor, infl)/(occ_factor+0.1);
				num_dir += (infl+0.01)/(occ_factor+0.1);
							
				dir 	= tex2D	(s_position,tc +float2(0.772340f,-0.094983f)*scale_tmp).xyz-P.xyz;
				occ_factor = saturate(length(dir));
				infl 	= saturate(dot(normalize(dir), N.xyz));			
				occ += (infl+0.01)*lerp( 1, occ_factor, infl)/(occ_factor+0.1);
				num_dir += (infl+0.01)/(occ_factor+0.1);
				
				dir 	= tex2D	(s_position,tc +float2(-0.373434f,0.780026f)*scale_tmp).xyz-P.xyz;
				occ_factor = saturate(length(dir));
				infl 	= saturate(dot(normalize(dir), N.xyz));			
				occ += (infl+0.01)*lerp( 1, occ_factor, infl)/(occ_factor+0.1);
				num_dir += (infl+0.01)/(occ_factor+0.1);
				

			#endif
		}
		return (occ / num_dir);
//	#endif
}	
	
#endif // AO_H	