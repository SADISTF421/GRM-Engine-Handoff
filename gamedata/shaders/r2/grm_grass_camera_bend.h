#ifndef GRM_GRASS_CAMERA_BEND_H
#define GRM_GRASS_CAMERA_BEND_H
// Приближение: камера используется вместо позиции игрока.
// Низ экземпляра остаётся на месте, верх мягко отклоняется от камеры.
float4 grm_grass_camera_bend(float4 p, float3 root_pos)
{
    float2 from_eye = root_pos.xz - eye_position.xz;
    float dist2 = dot(from_eye, from_eye);
    float dist = sqrt(dist2);
    float2 away = from_eye * rsqrt(max(dist2, 0.0001f));
    float near_mask = 1.0f - smoothstep(0.20f, 1.20f, dist);
    float height_mask = 1.0f - smoothstep(1.8f, 3.0f, abs(eye_position.y - root_pos.y));
    float top = saturate((p.y - root_pos.y) * 1.5f);
    float bend = near_mask * height_mask * top;
    p.xz += away * (0.16f * bend);
    p.y -= 0.06f * bend;
    return p;
}
#endif
