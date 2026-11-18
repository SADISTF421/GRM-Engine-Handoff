#ifndef EFFECTS_POM_H
	#define EFFECTS_POM_H
	
	// 16:51 07.01.2016
	
	#if !defined(POM_QUALITY)		// dis
		#define MIN_SAMPLES int(5)				// number of maximum samples
		#define MAX_SAMPLES int(40)					// number of minimum samples
		#define FINAL_INTERSECTION_LOOPS int(5)			// quantity of cycles of accuracy
	#elif POM_QUALITY==1		// low
		#define MIN_SAMPLES int(2)
		#define MAX_SAMPLES int(16)
		#define FINAL_INTERSECTION_LOOPS int(2)
	#elif POM_QUALITY==2		// medium
		#define MIN_SAMPLES int(3)
		#define MAX_SAMPLES int(24)
		#define FINAL_INTERSECTION_LOOPS int(3)
	#elif POM_QUALITY==3		// high
		#define MIN_SAMPLES int(4)
		#define MAX_SAMPLES int(32)
		#define FINAL_INTERSECTION_LOOPS int(4)
	#elif POM_QUALITY==4		// maximum
		#define MIN_SAMPLES int(5)
		#define MAX_SAMPLES int(40)
		#define FINAL_INTERSECTION_LOOPS int(5)
	#endif

	// these options for algorithm of increase in contrast parallax maps	
	#define CONTRAST_COEF_Q1 float(0.6)
	#define CONTRAST_COEF_Q2 float(1)
	#define BRIGHTNESS_COEF float(0.25)
	
//////////////////////////////////////////////////////////////////////////////////////////
// The below code is copyright of Sky4CE

float2 lod(float3 eye,float2 tc,sampler2D s_base)
{
	half height	= tex2D(s_base, tc).w * 0.016 - 0.009;    
    return tc + height*normalize(eye);
}
float2 AdvancedParallax(float3 eye,float2 tc,sampler2D s_base)
{
	const int maxSamples = MAX_SAMPLES;
  	const int minSamples = MIN_SAMPLES;
	float fParallaxOffset = PARALLAX_OFFSET;
 	int nNumSteps = lerp( maxSamples, minSamples, normalize(eye).z );
  	float2 vDelta = -normalize(eye).xy * fParallaxOffset;
//  	#ifdef CORRECT_PERSPECTIVE
//  	vDelta /= normalize(eye).z;
//  	#endif
   	float fStepSize = 1.0 / nNumSteps;
   	float2 vTexOffsetPerStep = fStepSize * vDelta;
   	double2 vTexCurrentOffset = tc;
   	float fCurrHeight = 0;
   	float  fCurrentBound = 1.0;
   	float Q1 = CONTRAST_COEF_Q1;
   	float Q2 = CONTRAST_COEF_Q2;
   	float Brightness = BRIGHTNESS_COEF;
   	for(;fCurrHeight < fCurrentBound;fCurrentBound -= fStepSize)
   	{
   		vTexCurrentOffset.xy += vTexOffsetPerStep;
//   		#ifndef USE_TEXTURE_PACK
    	fCurrHeight = tex2Dlod( s_base, float4(vTexCurrentOffset.xy,0,0) ).a+Brightness;
    	if (fCurrHeight > Q2) fCurrHeight  = 1.0f;
    	else if (fCurrHeight < Q1) fCurrHeight = 0.0f;
    	else fCurrHeight = (fCurrHeight - Q1)/(Q2-Q1);
//    	#else
//    	fCurrHeight = tex2Dlod( s_base, float4(vTexCurrentOffset.xy,0,0) ).a;
//    	#endif
    }
    float4 offsetBest = float4(vTexCurrentOffset,0,0);
    vTexCurrentOffset.xy -= vTexOffsetPerStep;
//    #ifndef USE_TEXTURE_PACK
   	float fPrevHeight = tex2Dlod( s_base, float4(vTexCurrentOffset.xy,0,0) ).a+Brightness;
   	if (fPrevHeight > Q2) fPrevHeight = 1.0f;
  	else if (fPrevHeight < Q1) fPrevHeight = 0.0f;
  	else fPrevHeight = (fPrevHeight - Q1)/(Q2-Q1);
//  	#else
//  	float fPrevHeight = tex2Dlod( s_base, float4(vTexCurrentOffset.xy,0,0) ).a;
//  	#endif
    float error = 1.0;
    float t1 = fCurrentBound ;
    float t0 = t1 + fStepSize;
    float delta1 = t1 - fCurrHeight;
    float delta0 = t0 - fPrevHeight;
    float4 intersect = float4(vDelta, vDelta + tc);
    for (int i=0; i<FINAL_INTERSECTION_LOOPS && abs(error) > 0.01; i++)
    { 
      float denom = (delta1 - delta0);
      float t = (t0 * delta1 - t1 * delta0) / denom;
      offsetBest.xy = -t * intersect.xy + intersect.zw;
//      #ifndef USE_TEXTURE_PACK
      float NB = tex2Dlod(s_base, offsetBest).a+Brightness;
      if (NB > Q2) NB = 1.0f;
  	  else if (NB < Q1) NB = 0.0f;
  	  else NB = (NB - Q1)/(Q2-Q1);
//  	  #else
//  	  float NB = tex2Dlod(s_base, offsetBest).a;
//  	  #endif
      error = t - NB;
      if (error < 0)
      {
         delta1 = error;
         t1 = t;
      }
      else
      {
         delta0 = error;
         t0 = t;
      }
    }
    return offsetBest.xy;
}	
	
#endif // EFFECTS_POM_H	