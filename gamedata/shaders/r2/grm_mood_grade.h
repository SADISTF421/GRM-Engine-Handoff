// ѕриглушаю цвета и немного охлаждаю тени.
#ifndef GRM_MOOD_GRADE_H
#define GRM_MOOD_GRADE_H
half4 grm_mood_grade(half4 scene)
{
    half luma = dot(scene.rgb, half3(0.2126h, 0.7152h, 0.0722h));
    half3 color = lerp(half3(luma, luma, luma), scene.rgb, 0.89h);
    half3 tint = lerp(half3(0.92h, 0.96h, 1.00h), half3(1.04h, 1.01h, 0.98h), saturate(luma));
    color *= tint * 0.98h;
    // ќпредел€ю погоду —кладов по сочетанию цвета тумана и освещени€.
    // Ёто приблизительна€ проверка: при другой погоде эффект может ослабнуть.
    float3 grm_fog = (float3)fog_color.rgb / max((float)fog_color.g, 0.001f);
    float3 grm_hemi = (float3)L_hemi_color.rgb / max((float)L_hemi_color.g, 0.001f);
    float grm_fog_error = max(abs(grm_fog.r - 0.89155f), abs(grm_fog.b - 1.13402f));
    float grm_hemi_error = max(abs(grm_hemi.r - 0.92092f), abs(grm_hemi.b - 1.10204f));
    float grm_sklady = 1.0f - smoothstep(0.008f, 0.025f, max(grm_fog_error, grm_hemi_error));
    // ƒобавл€ю лЄгкий холодный оттенок поверх текущей цветокоррекции.
    color *= lerp(half3(1.0h, 1.0h, 1.0h), half3(0.910h, 0.940h, 1.000h), (half)grm_sklady);
    // „уть приглушаю цвета, чтобы атмосфера была мрачнее.
    half grm_seriy = dot(color, half3(0.2126h, 0.7152h, 0.0722h));
    color = lerp(color, half3(grm_seriy, grm_seriy, grm_seriy), (half)grm_sklady * 0.16h);
    // ћ€гка€ плЄночна€ крива€ и землистый оттенок без подн€ти€ чЄрного.
    half3 grm_film = max(color, half3(0.h, 0.h, 0.h));
    half grm_y = dot(grm_film, half3(0.2126h, 0.7152h, 0.0722h));
    half grm_level = saturate(grm_y);
    half grm_shadow = 1.0h - smoothstep(0.02h, 0.50h, grm_level);
    half grm_mid = grm_level * (1.0h - grm_level);
    half grm_curve = 1.0h + 0.22h * grm_mid * (grm_level - 0.45h) + 0.060h * grm_shadow;
    grm_film *= grm_curve;
    half grm_high = smoothstep(0.45h, 1.0h, grm_level);
    half3 grm_film_tint = lerp(half3(1.050h, 1.012h, 0.945h), half3(1.025h, 1.008h, 0.980h), grm_high);
    grm_film *= grm_film_tint;
    // ћ€гко сдерживаю €ркие участки, не мен€€ резкость.
    grm_film *= 1.0h - 0.070h * smoothstep(0.85h, 1.50h, grm_y);
    half grm_film_gray = dot(grm_film, half3(0.2126h, 0.7152h, 0.0722h));
    grm_film = lerp(half3(grm_film_gray, grm_film_gray, grm_film_gray), grm_film, 0.94h);
    color = lerp(color, grm_film, 0.85h);
    // ѕриблизительно определ€ю тЄмную погоду по освещению неба и солнца.
    // Ёто не игровые часы: в пасмурный день коррекци€ тоже может про€витьс€.
    half grm_sky_light = dot(L_hemi_color.rgb, half3(0.2126h, 0.7152h, 0.0722h));
    half grm_sun_light = dot(L_sun_color.rgb, half3(0.2126h, 0.7152h, 0.0722h));
    half grm_night = (1.0h - smoothstep(0.12h, 0.36h, grm_sky_light));
    grm_night *= 1.0h - smoothstep(0.015h, 0.080h, grm_sun_light);
    // „уть возвращаю цвет и холод в полутона; чЄрный не поднимаю.
    half grm_night_y = dot(color, half3(0.2126h, 0.7152h, 0.0722h));
    half grm_color_mask = smoothstep(0.015h, 0.12h, grm_night_y);
    half3 grm_night_gray = half3(grm_night_y, grm_night_y, grm_night_y);
    color = lerp(color, grm_night_gray + (color - grm_night_gray) * 1.16h, grm_night * grm_color_mask);
    color *= lerp(half3(1.0h, 1.0h, 1.0h), half3(0.995h, 1.005h, 1.035h), grm_night * grm_color_mask);
    // —держиваю только €ркие зеленоватые пиксели; серый туман не затемн€ю.
    half grm_green = smoothstep(0.01h, 0.12h, color.g - max(color.r, color.b));
    half grm_bright = smoothstep(0.18h, 0.65h, grm_night_y);
    color *= 1.0h - 0.09h * grm_night * grm_green * grm_bright;
    return half4(max(color, half3(0.h, 0.h, 0.h)), scene.a);
}
#endif
