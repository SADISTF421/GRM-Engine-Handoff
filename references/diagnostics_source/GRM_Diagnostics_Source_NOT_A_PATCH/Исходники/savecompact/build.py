from pathlib import Path
import hashlib
src=Path('/data/grm/current/scripts.rar/scripts/task_manager.script').read_bytes();assert hashlib.sha256(src).hexdigest()=='2d7faa7f503adaf2eee425a17b329e2b48310396a33c2b47e913f156d24a7e09'
start=src.index(b'function CRandomTask:save(p)'); end=src.index(b'function CRandomTask:gen_phrase_id()',start)
old=src[start:end];Path('/data/grm/savecompact/old_part.lua').write_bytes(old)
new='''-- Компактный формат хранит те же данные задач и читает старые сохранения.
local grm_status_to_id = {normal = 0, selected = 1, completed = 2, refused = 3, failed = 4, rewarded = 5}
local grm_id_to_status = {[0] = "normal", [1] = "selected", [2] = "completed", [3] = "refused", [4] = "failed", [5] = "rewarded"}
local grm_magic1, grm_magic2 = 21844551, 558910787

function CRandomTask:save(p)
    local count, gain = 0, 0
    for k, v in pairs(self.task_info) do
        count = count + 1
        if grm_status_to_id[v.status] ~= nil then
            gain = gain + 2 + string.len(v.status)
        else
            gain = gain + 1
        end
    end
    local active = 0
    for k, v in pairs(self.active_task_by_type) do active = active + 1 end
    if count > 65535 then error("Слишком много задач для сохранения") end
    if active > 255 then error("Слишком много активных задач для сохранения") end
    -- Старый формат оставляем, если новый не уменьшает размер.
    local compact = count > 255 or gain > 10
    if compact then
        p:w_u8(255)
        p:w_u32(grm_magic1)
        p:w_u32(grm_magic2)
        p:w_u16(count)
    else
        p:w_u8(count)
    end
    for k, v in pairs(self.task_info) do
        p:w_stringZ(k)
        if compact then
            local code = grm_status_to_id[v.status]
            if code == nil then code = 7 end
            local packed = code
            if v.enabled then packed = packed + 8 end
            if v.enabled_props then packed = packed + 16 end
            p:w_u8(packed)
            if code == 7 then p:w_stringZ(v.status) end
        else
            p:w_bool(v.enabled)
            p:w_bool(v.enabled_props)
            p:w_stringZ(v.status)
        end
        p:w_u32(v.selected_target or -1)
        utils.w_CTime(p, v.last_task_time)
    end
    p:w_u8(active)
    for k, v in pairs(self.active_task_by_type) do
        p:w_stringZ(k)
        p:w_stringZ(v)
    end
end

function CRandomTask:load(p)
    local count = p:r_u8()
    local compact = false
    if count == 255 and p:r_elapsed() >= 8 then
        local start = p:r_tell()
        if p:r_u32() == grm_magic1 and p:r_u32() == grm_magic2 then
            compact = true
            count = p:r_u16()
        else
            p:r_seek(start)
        end
    end
    for k = 1, count do
        local id = p:r_stringZ()
        if compact then
            local packed = p:r_u8()
            local code = packed % 8
            self.task_info[id].enabled = math.floor(packed / 8) % 2 == 1
            self.task_info[id].enabled_props = math.floor(packed / 16) % 2 == 1
            if code == 7 then
                self.task_info[id].status = p:r_stringZ()
            else
                local status = grm_id_to_status[code]
                if status == nil then error("Неизвестный формат статуса задачи") end
                self.task_info[id].status = status
            end
        else
            self.task_info[id].enabled = p:r_bool()
            self.task_info[id].enabled_props = p:r_bool()
            self.task_info[id].status = p:r_stringZ()
        end
        local selected_target = p:r_u32()
        if selected_target ~= -1 then
            self.task_info[id].selected_target = selected_target
        end
        self.task_info[id].last_task_time = utils.r_CTime(p)
        if self.task_info[id].type == "defend_lager" then
            local defend_object = alife():object(self.task_info[id].selected_target)
            local sm_ini = defend_object:spawn_ini()
            self.task_info[id].defend_target = utils.cfg_get_number(sm_ini, "random_task", "defend_target", nil, true)
        end
    end
    local active = p:r_u8()
    for k = 1, active do
        local id = p:r_stringZ()
        self.active_task_by_type[id] = p:r_stringZ()
    end
end

-- Исходное формирование идентификаторов фраз.
'''
if b'\r\n' in src:new=new.replace('\n','\r\n')
out=src[:start]+new.encode('cp1251')+src[end:]
Path('/data/grm/savecompact/payload/task_manager.script').write_bytes(out)
print('original',len(src),'patched',len(out),'sha',hashlib.sha256(out).hexdigest(),'removed',len(old)); assert out[:start]==src[:start] and out.endswith(src[end:])
