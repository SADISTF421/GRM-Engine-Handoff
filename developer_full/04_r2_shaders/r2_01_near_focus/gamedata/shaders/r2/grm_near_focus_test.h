#ifndef GRM_NEAR_FOCUS_TEST_H
#define GRM_NEAR_FOCUS_TEST_H
// Эксперимент R2. Фокус по центральной глубине; состояние боя здесь недоступно.
// Нативную сцену и соседние глубины используем без изменения FOV.
half3 grm_near_focus(half3 scene, float2 uv, float2 image_uv, float3 position_eye)
{
    float focus = tex2D(s_position, float2(0.5f, 0.5f)).z;
    float activation = smoothstep(0.15f, 0.30f, focus) * (1.0f - smoothstep(0.65f, 1.25f, focus));
    float far_mask = smoothstep(focus + 0.30f, focus + 1.60f, position_eye.z);
    float2 pixel = max(float2(abs(ddx(uv.x)), abs(ddy(uv.y))), float2(0.000001f, 0.000001f));
    float2 delta = pixel * 2.0f;
    float2 bound_lo = pixel * 0.5f;
    float2 bound_hi = 1.0f - bound_lo;
    float2 p0 = clamp(image_uv + float2(-delta.x, 0.0f), bound_lo, bound_hi);
    float2 p1 = clamp(image_uv + float2( delta.x, 0.0f), bound_lo, bound_hi);
    float2 p2 = clamp(image_uv + float2(0.0f, -delta.y), bound_lo, bound_hi);
    float2 p3 = clamp(image_uv + float2(0.0f,  delta.y), bound_lo, bound_hi);
    float d0 = tex2D(s_position,p0).z;
    float d1 = tex2D(s_position,p1).z;
    float d2 = tex2D(s_position,p2).z;
    float d3 = tex2D(s_position,p3).z;
    half w0 = (half)smoothstep(focus + 0.18f, focus + 0.55f, d0);
    half w1 = (half)smoothstep(focus + 0.18f, focus + 0.55f, d1);
    half w2 = (half)smoothstep(focus + 0.18f, focus + 0.55f, d2);
    half w3 = (half)smoothstep(focus + 0.18f, focus + 0.55f, d3);
    half weight = w0+w1+w2+w3;
    half3 blur = (tex2D(s_image,p0).rgb*w0 + tex2D(s_image,p1).rgb*w1 + tex2D(s_image,p2).rgb*w2 + tex2D(s_image,p3).rgb*w3) / max(weight,0.001h);
    return lerp(scene, blur, (half)(0.30f * activation * far_mask * step(0.01f,weight)));
}
#endif
