#ifndef GRM_FOREGROUND_GLITCH_H
#define GRM_FOREGROUND_GLITCH_H

// Погодная метка Свалки; при переходах сила меняется плавно.
float grm_garbage_tag()
{
    return smoothstep(5.50f, 5.95f, (float)L_hemi_color.w);
}

// Время отсчитывается от общего таймера движка, а не от входа на Свалку.
// Интервалы: 15, 14, 13, 12, 11, затем по 10 минут.
float2 grm_event_schedule(float t)
{
    // Без возвратов из ветвлений: совместимость с компилятором PS 3.0.
    float s2 = step(1740.0f, t);
    float s3 = step(2520.0f, t);
    float s4 = step(3240.0f, t);
    float s5 = step(3900.0f, t);
    float s6 = step(4500.0f, t);
    float repeated = floor(max(t - 4500.0f, 0.0f) / 600.0f);
    float cycle = 1.0f + s2 + s3 + s4 + s5 + s6 * (1.0f + repeated);
    float begin = 900.0f + s2 * 840.0f + s3 * 780.0f + s4 * 720.0f
                + s5 * 660.0f + s6 * (600.0f + repeated * 600.0f);
    float phase = lerp(-1000.0f, t - begin, step(900.0f, t));
    return float2(phase, cycle);
}

half3 grm_foreground_glitch(half3 scene, float2 uv, float2 image_uv, float3 position_eye)
{
    float t = (float)timers.x;
    float2 schedule = grm_event_schedule(t);
    float phase = schedule.x;
    float cycle = schedule.y;
    float seed = frac(sin((cycle + 1.0f) * 12.9898f + 1.2f) * 43758.5453f);
    float start = seed * 30.0f;
    float pulse = smoothstep(start, start + 0.35f, phase) * (1.0f - smoothstep(start + 4.6f, start + 5.4f, phase));
    pulse *= grm_garbage_tag();
    float mode = floor(seed * 3.0f);
    float mode_tear = 1.0f - step(0.5f, mode);
    float mode_split = step(0.5f, mode) * (1.0f - step(1.5f, mode));
    float mode_flicker = step(1.5f, mode);
    float row = floor(uv.y * lerp(64.0f, 34.0f, mode_flicker));
    float flicker = floor(t * 18.0f);
    float rnd = frac(sin(row * 12.9898f + flicker * 78.233f + seed * 19.0f) * 43758.5453f);
    float stripe = step(0.46f, rnd);
    float shift = (rnd - 0.5f) * 0.020f;
    float vertical_shift = mode_flicker * (rnd - 0.5f) * 0.004f;
    float2 uv_a = saturate(image_uv + float2(shift, vertical_shift));
    float2 uv_b = saturate(image_uv - float2(shift, vertical_shift));
    float dist = length(position_eye);
    float dist_a = length((float3)tex2D(s_position, uv_a).xyz);
    float dist_b = length((float3)tex2D(s_position, uv_b).xyz);
    float near_mask = smoothstep(0.015f, 0.08f, dist) * (1.0f - smoothstep(0.65f, 1.50f, dist));
    float mask_a = smoothstep(0.015f, 0.08f, dist_a) * (1.0f - smoothstep(0.65f, 1.50f, dist_a));
    float mask_b = smoothstep(0.015f, 0.08f, dist_b) * (1.0f - smoothstep(0.65f, 1.50f, dist_b));
    float amount = pulse * stripe * near_mask * smoothstep(0.32f, 0.52f, uv.y);
    half3 sample_a = tex2D(s_image, uv_a).rgb;
    half3 sample_b = tex2D(s_image, uv_b).rgb;
    half3 tear = lerp(scene, sample_a, (half)(0.55f * mask_a));
    half3 split = scene;
    split.r = lerp(scene.r, sample_a.r, (half)(0.45f * mask_a));
    split.b = lerp(scene.b, sample_b.b, (half)(0.45f * mask_b));
    half3 flickering = lerp(scene, sample_a, (half)(0.28f * mask_a));
    flickering *= (half)(0.90f + 0.10f * rnd);
    half3 glitched = tear * (half)mode_tear + split * (half)mode_split + flickering * (half)mode_flicker;
    return lerp(scene, glitched, (half)amount);
}
half3 grm_metal_interference(half3 scene, float2 uv, float3 position_eye)
{
    float t = (float)timers.x;
    float2 schedule = grm_event_schedule(t);
    float phase = schedule.x;
    float cycle = schedule.y;
    float seed = frac(sin((cycle + 2.0f) * 41.47f) * 19341.37f);
    float start = seed * 30.0f;
    float pulse = smoothstep(start, start + 0.55f, phase) * (1.0f - smoothstep(start + 6.5f, start + 7.5f, phase));
    pulse *= grm_garbage_tag();
    float dist = length(position_eye);
    float near_mask = smoothstep(0.015f, 0.08f, dist) * (1.0f - smoothstep(0.65f, 1.50f, dist));
    float lower = smoothstep(0.32f, 0.52f, uv.y);
    float2 cell = floor(uv * float2(580.0f, 340.0f) + float2(floor(t * 12.0f), floor(t * 3.0f)));
    float noise = frac(sin(dot(cell, float2(12.9898f, 78.233f))) * 43758.5453f);
    float speckle = smoothstep(0.60f, 0.94f, noise);
    float darkening = 0.22f * pulse * near_mask * lower * speckle;
    return scene * (half)(1.0f - darkening);
}

#endif
