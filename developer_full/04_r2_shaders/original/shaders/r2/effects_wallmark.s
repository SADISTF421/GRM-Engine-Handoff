-- R2 experimental wallmark route. Native material: priority 1, mode 6,
-- clamp, Z-test on, Z-write off, no light/fog. Applies to effects/wallmark.
function normal(shader, t_base, t_second, t_detail)
    local ps = "sl_wm_uv_normal"
    if (type(t_base) == "string" and string.sub(t_base, 1, 18) == "wm\\grm_painter125\\") or
       t_base == "wm\\wm_blood_1" or
        t_base == "wm\\wm_blood_1_1" or
        t_base == "wm\\wm_blood_1_2" or
        t_base == "wm\\wm_blood_1_3" or
        t_base == "wm\\wm_blood_2" or
        t_base == "wm\\wm_blood_3" or
        t_base == "wm\\wm_blood_drop_1" or
        t_base == "wm\\wm_blood_drop_2" or
        t_base == "wm\\wm_blood_drop_3" or
        t_base == "wm\\wm_blood_drop_4" then
        ps = "sl_wm_uv_blood"
    end
    shader:begin("sl_wm_uv_lit", ps)
        :sorting(1, false)
        :blend(true, blend.destcolor, blend.srccolor)
        :aref(false, 0)
        :zb(true, false)
        :fog(false)
        :wmark(true)
    shader:sampler("s_base"):texture(t_base):clamp()
end
