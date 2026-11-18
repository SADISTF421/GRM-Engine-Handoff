#ifndef F42_WEATHER_H
#define F42_WEATHER_H
// TEST4: paired LTX stores 2+wetness in hemi_color.w. RGB keeps its lighting meaning.
// Stock alpha=1: no extra night response, no puddles, no horizon replacement.
// No new engine constants or samplers; verify this channel on the installed engine.
// ћетка —валки не должна измен€ть силу влажности.
half grm_weather_hemi_w()
{
    return L_hemi_color.w >= 5.5h ? L_hemi_color.w - 4.0h : L_hemi_color.w;
}
half f42_weather_active()
{
    return smoothstep(1.50h,1.95h,grm_weather_hemi_w());
}
half f42_weather_wetness()
{
    return saturate(grm_weather_hemi_w()-2.0h)*f42_weather_active();
}
half f42_weather_night()
{
    half hemi_max=max(L_hemi_color.r,max(L_hemi_color.g,L_hemi_color.b));
    return (1.0h-smoothstep(0.48h,0.60h,hemi_max))*f42_weather_active();
}

// TEST6: this EXE derives native fog bounds from far_plane, NOT fog_distance.
// Recover native density from (-near*r,r,r,r); shorten only tagged-weather fog.
// Native bindings verified at XR_3DA 0x47bb00, mixer 0x42edd8..0x42ee24.
float f42_weather_fog(float eye_distance)
{
    float native_fog = saturate(eye_distance*fog_params.w + fog_params.x);
    float near_far_ratio = saturate(-fog_params.x/max(1.0f-fog_params.x,0.0001f));
    float density = saturate(1.0f-near_far_ratio*(0.99f/0.85f));
    float heavy = smoothstep(0.72f,0.94f,density);
    float range_scale = lerp(0.78f,0.42f,heavy);
    range_scale *= lerp(1.0f,0.86f,(float)f42_weather_wetness());
    float weather_fog = saturate((eye_distance/range_scale)*fog_params.w + fog_params.x);
    weather_fog *= 1.15f-0.15f*weather_fog;
    // Keep the immediate foreground and first-person weapon free of extra fog.
    float local_clear = smoothstep(8.0f,25.0f,eye_distance);
    weather_fog = lerp(native_fog,weather_fog,local_clear);
    return lerp(native_fog,weather_fog,(float)f42_weather_active());
}

// Soft world-locked variation, not a binary puddle mask or new material map.
float f42_wet_hash(float2 p)
{
    float3 q = frac(float3(p.x,p.y,p.x)*0.1031f);
    q += dot(q,q.yzx+33.33f);
    return frac((q.x+q.y)*q.z);
}
float f42_wet_noise(float2 p)
{
    float2 i=floor(p), f=frac(p);
    float2 u=f*f*(3.0f-2.0f*f);
    float a=f42_wet_hash(i), b=f42_wet_hash(i+float2(1,0));
    float c=f42_wet_hash(i+float2(0,1)), d=f42_wet_hash(i+float2(1,1));
    return lerp(lerp(a,b,u.x),lerp(c,d,u.x),u.y);
}
// FLAT+DETAIL paths only. Bump paths and alpha foliage paths are unchanged.
// Hemi is a sky-exposure approximation, NOT exact per-pixel rain occlusion.
void f42_wet_flat_ground(inout half3 albedo, inout half gloss,
                         half3 normal_eye, float3 position_eye, half hemi
#ifdef GRM_PUDDLE_REFLECTION
                         , out half grm_reflection_pool
#endif
#ifdef GRM_PUDDLE_RIPPLE
                         , out half3 grm_ripple_eye
#endif
                         )
{
#ifdef GRM_PUDDLE_REFLECTION
    grm_reflection_pool = 0.h;
#endif
#ifdef GRM_PUDDLE_RIPPLE
    grm_ripple_eye = half3(0.h,0.h,0.h);
#endif
    float3 normal_world = mul((float3)normal_eye,(float3x3)m_V);
    normal_world *= rsqrt(max(dot(normal_world,normal_world),1e-8f));
    half slope=(half)smoothstep(0.92f,0.985f,normal_world.y);
    half exposed=smoothstep(0.08h,0.55h,saturate(hemi));
    half away=(half)smoothstep(2.0f,5.0f,length(position_eye));
#ifdef SL_STATIC_WET_TRIAL
    // Static detail ground only; no new textures, samplers, engine APIs or Lua.
    // Exposure is approximate: roofs/sheltered areas are not semantically classified.
    half humidity=f42_weather_wetness();
    half wet=humidity*slope*exposed*away;
    float3 world=mul(position_eye,(float3x3)m_V)+eye_position;
    float broad=f42_wet_noise(world.xz*0.31f);
    // Waterline, not an all-over gloss mask. Shrinks continuously as humidity falls.
    float fine=f42_wet_noise(world.xz*0.93f+float2(7.1f,19.3f));
    half basin=(half)(0.78f*broad+0.22f*fine);
    half level=0.08h+0.24h*humidity;
    half pool=(1.0h-smoothstep(level-0.035h,level+0.035h,basin));
    pool*=smoothstep(0.25h,0.80h,humidity)*slope*slope*exposed*exposed*away;
#ifdef GRM_PUDDLE_REFLECTION
    // ѕередаЄм уже существующую форму лужи, не расшир€€ еЄ.
    grm_reflection_pool = pool;
#endif
    // No emissive lift: multiply existing albedo, leaving shadows dependent on light.
    half readability=1.0h+0.025h*slope*exposed*away;
    albedo*=readability*(1.0h-0.09h*wet-0.075h*pool);
    half damp_gloss=lerp(0.035h,0.085h,(half)fine);
    gloss=lerp(gloss,max(gloss,damp_gloss),wet);
    // ”силиваем блик именно в лужах, без насто€щего экранного отражени€.
    float3 view_dir = -position_eye * rsqrt(max(dot(position_eye,position_eye),1e-8f));
    half water_grazing = (half)pow(1.0f-saturate(abs(dot((float3)normal_eye,view_dir))), 3.0f);
    half water_gloss = 0.74h + 0.12h*water_grazing;
    gloss=lerp(gloss,max(gloss,water_gloss),pool);
#ifdef GRM_PUDDLE_RIPPLE
    // Subtle animated water-normal variation, restricted to the existing pools.
    // No additional samplers, textures, or renderer constants are required.
    // –едкие расход€щиес€ круги мен€ют блик только внутри лужи.
    float2 uv = world.xz * 1.45f;
    float2 cell = floor(uv), local_uv = frac(uv);
    float2 drop = 0.25f + 0.5f*float2(f42_wet_hash(cell+float2(5.1f,2.3f)), f42_wet_hash(cell+float2(8.7f,9.4f)));
    float2 radial = local_uv - drop;
    float radius = length(radial);
    float phase = frac((float)timers.x * 0.55f + f42_wet_hash(cell+float2(3.4f,7.8f)));
    float ring = (1.0f-smoothstep(0.025f,0.09f,abs(radius-phase*0.48f))) * (1.0f-phase);
    float boundary = min(min(local_uv.x,1.0f-local_uv.x),min(local_uv.y,1.0f-local_uv.y));
    ring *= smoothstep(0.02f,0.13f,boundary);
    float3 ripple_world = float3(radial.x,0.0f,radial.y) * (0.07f * ring * (float)pool);
    grm_ripple_eye = (half3)mul((float3x3)m_V, ripple_world);
    gloss = saturate(gloss + (half)(0.06f * ring * (float)pool));
#endif
#else
    half wet=f42_weather_wetness()*slope*exposed*away;
    float3 world=mul(position_eye,(float3x3)m_V)+eye_position;
    half variation=(half)f42_wet_noise(world.xz*0.16f);
    // No zero/one cutouts: the whole exposed plane gets a restrained wet sheen.
    half target=lerp(0.10h,0.20h,variation);
    albedo *= 1.0h-0.05h*wet*(0.8h+0.2h*variation);
    gloss=lerp(gloss,max(gloss,target),wet);
#endif
}


// TEST7: weather-coloured inscatter; bounded chroma from existing sky resources.
// No new constants, texture assets, screen noise, or material recolouring.
half3 f42_weather_fog_colour(half3 sky_hint)
{
    half sky_Y=dot(max(sky_hint,0.0h),half3(0.2126h,0.7152h,0.0722h));
    half3 chroma=clamp(sky_hint/max(sky_Y,0.03h),0.75h,1.25h);
    half3 response=0.92h*lerp(half3(1.0h,1.0h,1.0h),chroma,0.12h);
    return lerp(fog_color.rgb,fog_color.rgb*response,f42_weather_active());
}

#endif
