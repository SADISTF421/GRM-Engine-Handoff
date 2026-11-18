from pathlib import Path
import re,hashlib,json
root=Path('/data/grm/gore_cleanup'); d=root/'payload'; d.mkdir(exist_ok=True)
inputs=[('/data/grm/chance75/package/GRM_Chance75/grm_gore_test.script','100_popup_old'),('/data/grm/fasthead/grm_gore_fast.script','50_popup_old'),('/data/grm/cleanpatch/package/GRM_CleanDiag/gore0.script','100_quiet_old'),('/data/grm/cleanpatch/package/GRM_CleanDiag/gore1.script','50_quiet_old'),('/data/grm/corpsegore/package/GRM_Corpse/gore0.script','100_corpse_old'),('/data/grm/corpsegore/package/GRM_Corpse/gore1.script','50_corpse_old')]+[(str(f),f.stem+'_transition') for f in sorted(Path('/data/grm/particle_transition_fix/package/GRM_ParticleTransition').glob('*.script'))]
sha=lambda x:hashlib.sha256(x).hexdigest(); rows=[]
for fn,name in inputs:
 raw=Path(fn).read_bytes(); txt=raw.decode('cp1251'); nl='\r\n' if '\r\n' in txt else '\n';s=txt.replace('\r\n','\n')
 a=s.index('local function notice(text)'); b=s.index('\nlocal function setup()',a)
 s=s[:a]+'''-- Подробные сообщения включаются только на время диагностики.
local GORE_DEBUG = false
local reported_errors = {}
local function notice(text)
    local message = tostring(text)
    local is_error = message:find("FAIL", 1, true) or message:find("ERROR", 1, true)
    if not GORE_DEBUG and not is_error then return end
    if not GORE_DEBUG then
        local key = message:match("^[^ ]+ [^ ]+") or message
        if reported_errors[key] then return end
        reported_errors[key] = true
    end
    pcall(function() if type(printf) == "function" then printf("[GRM_GORE] %s", message) end end)
end''' +s[b:]
 a=s.index('local held_particles, particle_pool = {}, {}');b=s.index('\nlocal function play_particle(',a)
 s=s[:a]+'''-- У каждой частицы одна сильная ссылка; работающие частицы не уничтожаются.
local particle_pool = {}
local particle_actor, particle_level, particle_sweep = nil, nil, 0
local particle_limits = {
    ["grm_restore\\\\suicide_backup_head"] = 8,
    ["hit_fx\\\\group_items\\\\hit_blood_puff_head"] = 32,
    ["hit_fx\\\\group_items\\\\hit_blood_drops_headshoot_00"] = 16,
    ["hit_fx\\\\group_items\\\\hit_blood_drops_headshoot_01"] = 16,
    ["hit_fx\\\\group_items\\\\hit_blood_drops_01"] = 16,
    ["hit_fx\\\\group_items\\\\hit_blood_drops_02"] = 16
}
local function particle_sync()
    local actor = db and db.actor
    if not actor then return false end
    local map = level.name()
    if not rawequal(actor, particle_actor) or map ~= particle_level then
        -- Старые объекты нельзя опрашивать после выгрузки карты.
        particle_pool = {}
        particle_actor, particle_level, particle_sweep = actor, map, 0
    end
    return true
end
local function particle_cleanup(now)
    if not particle_sync() then return end
    if now >= particle_sweep and now < particle_sweep + 2000 then return end
    particle_sweep = now
    for effect, pool in pairs(particle_pool) do
        for i = #pool, 1, -1 do
            local entry = pool[i]
            if (now < entry.started or now - entry.started >= 10000) and not entry.fx:playing() then
                table.remove(pool, i)
            end
        end
        if #pool == 0 then particle_pool[effect] = nil end
    end
end
function particle_at(effect, pos)
    if not pos or not particle_sync() then return false end
    local now = time_global()
    local pool = particle_pool[effect]
    if not pool then pool = {}; particle_pool[effect] = pool end
    local entry = nil
    for _, candidate in ipairs(pool) do
        if not candidate.fx:playing() then entry = candidate; break end
    end
    if not entry and #pool < (particle_limits[effect] or 0) then
        local fx = particles_object(effect)
        if fx then entry = {fx = fx, started = now}; pool[#pool + 1] = entry end
    end
    if not entry then return false end
    entry.started = now
    entry.fx:play_at_pos(pos)
    return true
end''' + s[b:]
 a=s.index('    if tonumber(bone) == id then',s.index('function hit(')); b=s.index('\nend\n',a)
 s=s[:a]+'''    -- Последнее подтверждённое попадание в тело отменяет попадание в голову.
    local target = binder.object
    local id_ok, who_id = pcall(function() return who:id() end)
    if not id_ok then binder.grm_gore_test = nil; return end
    binder.grm_gore_test = {
        time = time_global(), who = who_id, npc = target:id(), kind = kind,
        section = section, head = tonumber(bone) == id
    }
    if tonumber(bone) ~= id then binder.grm_gore_aim = nil end''' +s[b:]
 s=s.replace('''    local record = binder.grm_gore_test
    binder.grm_gore_test = nil
    local kind, section = actor_weapon(who)''','''    local record = binder.grm_gore_test
    local saved_aim = binder.grm_gore_aim
    binder.grm_gore_test = nil
    binder.grm_gore_aim = nil
    local kind, section = actor_weapon(who)''',1)
 s=s.replace('''    local is_head = record and record.who == who_id and record.section == section
        and now >= record.time and now - record.time <= 300
    local route = "HIT"
    local saved_aim = binder.grm_gore_aim
    binder.grm_gore_aim = nil''','''    local recent = record and record.who == who_id and record.npc == binder.object:id()
        and record.section == section and now >= record.time and now - record.time <= 300
    -- Достоверное попадание в тело не заменяется старым результатом прицеливания.
    if recent and not record.head then return end
    local is_head = recent and record.head
    local route = "HIT"''',1)
 assert 'local saved_aim = binder.grm_gore_aim' in s and 'local old = binder.grm_gore_test' not in s
 s=s.replace('if not kind then binder.grm_gore_test = nil; return end', 'if not kind then binder.grm_gore_test = nil; binder.grm_gore_aim = nil; return end', 1)
 s=s.replace('''local function play_particle(npc, effect)
    pcall(function()
        local neck = npc:bone_position("bip01_neck")
        if not neck then return end
        particle_at(effect, vector():set(neck.x, neck.y, neck.z))
    end)
end''','''local function play_particle(npc, effect)
    local ok, err = pcall(function()
        local neck = npc:bone_position("bip01_neck")
        if not neck then return end
        particle_at(effect, vector():set(neck.x, neck.y, neck.z))
    end)
    if not ok then notice("PARTICLE ERROR " .. tostring(err)) end
end''',1)
 old='''    local obj = binder.object
    if obj:alive() then
        track_aim(binder, obj, time_global())'''
 new='''    local obj = binder.object
    local stamp = time_global()
    local clean_ok, clean_err = pcall(particle_cleanup, stamp)
    if not clean_ok then notice("PARTICLE ERROR " .. tostring(clean_err)) end
    if obj:alive() then
        local record = binder.grm_gore_test
        if record and (stamp < record.time or stamp - record.time > 300) then binder.grm_gore_test = nil end
        track_aim(binder, obj, stamp)'''
 assert old in s;s=s.replace(old,new,1)
 data=s.replace('\n',nl).encode('cp1251');(d/(name+'.script')).write_bytes(data); rows.append({'old':sha(raw),'new':sha(data),'file':name+'.script'})
(root/'rows.json').write_text(json.dumps(rows,indent=2)); print('generated',len(rows))
