from pathlib import Path
import subprocess, tempfile, shutil, hashlib
base=Path('/data/grm/particle_transition_fix');pkg=base/'package';out=pkg/'GRM_ParticleTransition'
cases=[('100ms_popup','chance75/test.lua'),('50ms_popup','fasthead/test.lua'),('100ms_quiet','cleanpatch/test_gore0.lua'),('50ms_quiet','cleanpatch/test_gore1.lua'),('100ms_corpse','corpsegore/test_gore_corpse0.lua'),('50ms_corpse','corpsegore/test_gore_corpse1.lua')]
import re
for variant,test in cases:
 text=(Path('/data/grm')/test).read_text();text=re.sub(r"dofile\('[^']+'\)","dofile('"+str(out/(variant+'.script'))+"')",text,count=1); p=base/(variant+'.lua');p.write_text(text)
 subprocess.run(['python3','/data/grm/run_lua_file.py',str(p)],check=True)
 retention='''local map='level0'; local created,freed=0,0
local actor={}; db={actor=actor}; level={name=function() return map end}; function printf() end
function particles_object() created=created+1; return setmetatable({playing=function() return false end,play_at_pos=function() end},{__gc=function() freed=freed+1 end}) end
dofile('PATH')
local function heldcount() for i=1,30 do local n,v=debug.getupvalue(particle_at,i); if n=='held_particles' then return #v end end; error('no held') end
for i=1,100 do map='level'..i; assert(particle_at('grm_restore\\\\suicide_backup_head',{})); assert(heldcount()==1) end
collectgarbage('collect'); assert(created==100 and freed==99,created..' '..freed)
for i=1,100 do assert(particle_at('grm_restore\\\\suicide_backup_head',{})) end
assert(created==100 and heldcount()==1)
db.actor={}; assert(particle_at('grm_restore\\\\suicide_backup_head',{})); collectgarbage('collect'); assert(created==101 and freed==100 and heldcount()==1)
print('PASS map reset, reuse and actor reset')
'''.replace('PATH',str(out/(variant+'.script')))
 p.write_text(retention);subprocess.run(['python3','/data/grm/run_lua_file.py',str(p)],check=True)
# Installer simulated in copies with PowerShell 7.4; hashes and no-change checks
mock=base/'mock';shutil.rmtree(mock,ignore_errors=True);shutil.copytree(pkg,mock);(mock/'bin').mkdir();(mock/'gamedata/scripts').mkdir(parents=True)
shutil.copy('/data/grm/newbin_last/bin/XR_3DA.exe',mock/'bin/XR_3DA.exe');shutil.copy('/data/grm/newbin_last/bin/xrGame.dll',mock/'bin/xrGame.dll')
inputs=['/data/grm/chance75/package/GRM_Chance75/grm_gore_test.script','/data/grm/fasthead/grm_gore_fast.script','/data/grm/cleanpatch/package/GRM_CleanDiag/gore0.script','/data/grm/cleanpatch/package/GRM_CleanDiag/gore1.script','/data/grm/corpsegore/package/GRM_Corpse/gore0.script','/data/grm/corpsegore/package/GRM_Corpse/gore1.script']
target=mock/'gamedata/scripts/grm_gore_test.script';cmd=['/data/pwsh/pwsh','-NoProfile','-File',str(mock/'GRM_ParticleTransition.ps1')]
for (v,_),src in zip(cases,inputs):
 shutil.copy(src,target); r=subprocess.run(cmd,capture_output=True,text=True); assert r.returncode==0,(v,r.stdout,r.stderr); assert target.read_bytes()==(out/(v+'.script')).read_bytes(); r=subprocess.run(cmd,capture_output=True,text=True);assert r.returncode==0;print('PASS installer and repeat:',v)
target.write_bytes(b'unknown version');r=subprocess.run(cmd,capture_output=True,text=True);assert r.returncode!=0 and target.read_bytes()==b'unknown version';print('PASS rejects unknown script')
shutil.copy(inputs[0],target);before=target.read_bytes();(mock/'bin/xrGame.dll').write_bytes(b'wrong');r=subprocess.run(cmd,capture_output=True,text=True);assert r.returncode!=0 and target.read_bytes()==before;print('PASS rejects unknown engine')
shutil.copy('/data/grm/newbin_last/bin/xrGame.dll',mock/'bin/xrGame.dll');(mock/'GRM_ParticleTransition/100ms_popup.script').unlink();r=subprocess.run(cmd,capture_output=True,text=True);assert r.returncode!=0 and target.read_bytes()==before;print('PASS rejects missing payload')
