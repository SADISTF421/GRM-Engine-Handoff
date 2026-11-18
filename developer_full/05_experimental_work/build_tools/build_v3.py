from pathlib import Path
import shutil, hashlib, difflib
D=Path('/data/grm'); O=D/'v3'; base=D/'current2026/scripts.rar/scripts'; v2=D/'big_v2/INSTALL/payload'; payload=O/'INSTALL/payload'
# CP1251 round-trip: bytes not touched outside precisely selected changes.
def read(p):return p.read_bytes().decode('cp1251')
def write(p,s):p.write_bytes(s.encode('cp1251'))
def change(s,old,new):
 assert s.count(old)==1,(old[:100],s.count(old));return s.replace(old,new,1)
s=read(base/'grm_gore_test.script')
s=change(s,'        notice("ENGINE BONE MODE")','        pcall(function() if type(printf) == "function" then printf("[GRM_GORE] runtime started") end end)')
s=change(s,'local particle_pool = {}','''local particle_pool = {}
-- Лимит относится только к частицам отрыва головы, не к чужим системам.
local MAX_ACTIVE_GORE_PARTICLES = 16
local function gore_particle_count()
    local count = 0
    for key, pool in pairs(particle_pool) do
        if key:sub(1, 5) == "gore:" then count = count + #pool end
    end
    return count
end

-- Только локальные маркеры конкретного NPC. Состояние скрытой головы в движке не трогаем.
function reset_binder(binder)
    if not binder then return end
    binder.grm_gore_test = nil
    binder.grm_gore_aim = nil
    binder.grm_gore_aim_next = nil
    binder.grm_gore_pending = nil
    binder.grm_gore_blood = nil
    binder.grm_gore_anchored = nil
    binder.grm_gore_refresh = nil
    binder.grm_gore_map = nil
end''')
s=change(s,'function particle_at(effect, pos)','function particle_at(effect, pos, gore_owned)')
s=change(s,'''    local pool = particle_pool[effect]
    if not pool then pool = {}; particle_pool[effect] = pool end''','''    local key = (gore_owned and "gore:" or "shared:") .. effect
    local pool = particle_pool[key]
    if not pool then pool = {}; particle_pool[key] = pool end''')
s=change(s,'    if not entry and #pool < (particle_limits[effect] or 0) then','    if not entry and #pool < (particle_limits[effect] or 0)\n        and (not gore_owned or gore_particle_count() < MAX_ACTIVE_GORE_PARTICLES) then')
s=change(s,'        particle_at(effect, vector():set(neck.x, neck.y, neck.z))','        particle_at(effect, vector():set(neck.x, neck.y, neck.z), true)')
write(payload/'grm_gore_test.script',s)
m=read(v2/'xr_motivator.script')
m=change(m,'function motivator_binder:reinit()\n','function motivator_binder:reinit()\n\tpcall(function() grm_gore_test.reset_binder(self) end)\n')
m=change(m,'function motivator_binder:net_destroy()\n','function motivator_binder:net_destroy()\n\tpcall(function() grm_gore_test.reset_binder(self) end)\n')
for line in ["\tprintf(\"motivator_binder:net_spawn(): self.object:name()='%s'\", self.object:name())", "\tprintf(\"motivator_binder:save(): self.object:name()='%s'\", self.object:name())", "\tprintf(\"motivator_binder:load(): self.object:name()='%s'\", self.object:name())", "\tprintf(\"motivator_binder:object_binder.load(): self.object:name()='%s'\", self.object:name())"]:
 m=change(m,line,'')
write(payload/'xr_motivator.script',m)
for name,orig in [('grm_gore_test.script',base/'grm_gore_test.script'),('xr_motivator.script',v2/'xr_motivator.script')]:
 shutil.copy2(payload/name,O/'SOURCE'/name)
 a=read(orig).splitlines(keepends=True);b=read(payload/name).splitlines(keepends=True)
 (O/'SOURCE'/(name+'.diff')).write_text(''.join(difflib.unified_diff(a,b,fromfile='base/'+name,tofile='v3/'+name)),encoding='utf-8')
for name in ['GRM_SaveSafety.ps1','SAVE_SNAPSHOT.bat','GRM_SaveValidator.ps1','GRM_SaveValidator.bat','CHECK_VERSIONS.ps1','CHECK_VERSIONS.bat']:
 shutil.copy2(D/'big_v2/TOOLS'/name,O/'TOOLS'/name)
shutil.copy2(D/'big_v2/SOURCE/TESTS/run_lua_file.py',O/'SOURCE/TESTS/run_lua_file.py')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
print('BASE / PATCH:')
for n,o in [('grm_gore_test.script',base/'grm_gore_test.script'),('xr_motivator.script',v2/'xr_motivator.script'),('bind_stalker.script',v2/'bind_stalker.script'),('task_manager.script',v2/'task_manager.script')]:
 print(n,sha(o),sha(payload/n) if (payload/n).exists() else '-')
