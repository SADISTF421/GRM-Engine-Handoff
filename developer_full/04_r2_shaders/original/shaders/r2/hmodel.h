#ifndef        HMODEL_H
#define HMODEL_H

#include "common.h"
#include "f42_weather.h"

// Small multiplicative lift: zero illumination remains zero.
#define F42_DIFFUSE_LIFT 1.04h

uniform samplerCUBE         env_s0                ;
uniform samplerCUBE         env_s1                ;
uniform samplerCUBE         sky_s0                ;
uniform samplerCUBE         sky_s1                ;
uniform half4                         env_color        ;        // color.w  = lerp factor
uniform half3x4                        m_v2w                ;

// TEST5B: bounded view-angle weight for environment specular only.
// Front-facing: 0.78; grazing: 1.00. Diffuse and direct lights unchanged.
half f42_env_spec_angle(half3 normal, float3 point)
{
    float3 n = (float3)normal;
    float facing = saturate(-dot(n, point)
        * rsqrt(max(dot(n, n), 1e-8f))
        * rsqrt(max(dot(point, point), 1e-8f)));
    half rim = (half)(1.0f - facing);
    return 0.78h + 0.22h * rim * rim;
}

void        hmodel                 (out half3 hdiffuse, out half3 hspecular, half m, half h, half s, float3 point, half3 normal)
{
        // hscale - something like diffuse reflection
        half3         nw                         = f42_reflection_normal(mul((half3x3)m_v2w,normal));
        half         hscale                 = h;                                //. *        (.5h + .5h*nw.y);
#ifdef         USE_GAMMA_22
                        hscale                = (hscale*hscale);        // make it more linear
#endif

        // reflection vector
        float3        v2pointL        		= normalize        (point);
        half3         v2point               = mul                (m_v2w,v2pointL);
        half3        vreflect        		= reflect         (v2point,nw);
        half         hspec                 	= .5h+.5h*dot        (vreflect,v2point);

        // material
          half4         light                = tex3D                (s_material, half3(hscale, hspec, m) );                // sample material

        // diffuse color
        half3         e0d               = texCUBE         (env_s0,nw);
        half3         e1d               = texCUBE         (env_s1,nw);
        half3         env_d             = env_color.xyz*lerp(e0d,e1d,env_color.w)        ;
					// Reduce only the night cubemap's crushing square, only where sky is exposed.
                    // No additive glow, no change to specular, sun or flashlights.
                    half f42_open=smoothstep(0.08h,0.55h,saturate(h));
                    half f42_soft=0.55h*f42_weather_night()*f42_open;
                    env_d=lerp(env_d*env_d,env_d*0.42h,f42_soft);
        hdiffuse                        = (env_d * light.xyz + L_ambient.rgb)*F42_DIFFUSE_LIFT;

        // specular color
                        vreflect.y      = vreflect.y*2-1;                                                        // fake remapping
        half3         e0s               = texCUBE         (env_s0,vreflect);
        half3         e1s               = texCUBE         (env_s1,vreflect);
        half3         env_s             = env_color.xyz*lerp(e0s,e1s,env_color.w)        ;
					env_s*=env_s;		// contrast
        hspecular                       = env_s*light.w*s*lerp(F42_ENV_OCCLUSION_FLOOR,1.0h,saturate(h))*f42_env_spec_angle(normal, point);                //*h*m*s        ;        //env_s        *light.w         * s;
}

void         hmodel_table        (out half3 hdiffuse, out half3 hspecular, half m, half h, half s, half3 point, half3 normal)
{
        // hscale - something like diffuse reflection
        half         hscale         = h;

        // reflection vector
        half3         v2point        = normalize        (point);
        half3        vreflect= reflect         (v2point,normal);
        half         hspec         = .5h+.5h*dot        (vreflect,v2point);

        // material
          half4         light        = tex3D                (s_material, half3(hscale, hspec, m) );                // sample material

        // diffuse color
        half3         env_d         = texCUBE         (env_s0,normal);

        // specular color
        half3         env_s          = texCUBE         (env_s0,vreflect);

        //
        hdiffuse        = (env_d*light.xyz + L_ambient.rgb)*F42_DIFFUSE_LIFT;
        hspecular        = env_s*light.w*s*lerp(F42_ENV_OCCLUSION_FLOOR,1.0h,saturate(h));
}

#endif
