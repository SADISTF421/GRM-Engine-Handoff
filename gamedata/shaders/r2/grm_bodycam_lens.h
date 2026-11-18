// GRM: modest bodycam-style lens, DX9 R2; no custom shader uniforms.
#ifndef GRM_BODYCAM_LENS_H
#define GRM_BODYCAM_LENS_H
float2 grm_bodycam_uv(float2 uv)
{
    float2 d = uv - float2(0.5, 0.5);
    float r2 = dot(d, d);
    return saturate(float2(0.5, 0.5) + d * (0.94 + 0.10 * r2));
}
half4 grm_bodycam_edges(half4 color, float2 uv)
{
    float2 p = (uv - float2(0.5, 0.5)) * float2(1.0, 1.15);
    float edge = saturate(dot(p,p) * 2.0);
    color.rgb *= 1.0 - 0.12 * edge * edge;
    return color;
}
#endif
