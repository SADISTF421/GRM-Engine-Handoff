#ifndef GRM_GRASS_VIEW_BEND_H
#define GRM_GRASS_VIEW_BEND_H
// Приближение для камеры: используем только уже подключённую матрицу m_WV.
// Это не данные актёра, NPC или аномалий; доступно только для detail-травы.
float4 grm_bend_near_view(float4 p, float3 root)
{
    float3 root_view = mul(m_WV, float4(root, 1.0f));
    float3 root_from_view = mul(root_view, (float3x3)m_WV);
    float2 horizontal = root_from_view.xz;
    float distance2 = dot(horizontal, horizontal);
    float distance_xz = sqrt(distance2);
    float near_mask = 1.0f - smoothstep(0.30f, 1.35f, distance_xz);
    float height_mask = 1.0f - smoothstep(1.8f, 3.1f, abs(root_from_view.y));
    float top = saturate((p.y - root.y) * 1.5f);
    float bend = near_mask * height_mask * top;
    float2 direction = horizontal * rsqrt(max(distance2, 0.0001f));
    p.xz += direction * (0.24f * bend);
    p.y -= 0.08f * bend;
    return p;
}
#endif
