from pathlib import Path
import hashlib, shutil, subprocess
r=Path('/data/grm/render_neck'); pkg=r/'package';mock=r/'mock';shutil.rmtree(mock,ignore_errors=True);shutil.copytree(pkg,mock)
(mock/'bin').mkdir(); (mock/'gamedata/scripts').mkdir(parents=True);exe=mock/'bin/XR_3DA.exe';dll=mock/'bin/xrGame.dll';script=mock/'gamedata/scripts/grm_gore_test.script'
orig=Path('/data/grm/newbin_last/bin/XR_3DA.exe').read_bytes(); patched=(pkg/'GRM_RenderNeck/XR_3DA.patched').read_bytes()
ins=['/data/grm/chance75/package/GRM_Chance75/grm_gore_test.script','/data/grm/fasthead/grm_gore_fast.script','/data/grm/cleanpatch/package/GRM_CleanDiag/gore0.script','/data/grm/cleanpatch/package/GRM_CleanDiag/gore1.script','/data/grm/corpsegore/package/GRM_Corpse/gore0.script','/data/grm/corpsegore/package/GRM_Corpse/gore1.script']+[str(x) for x in Path('/data/grm/particle_transition_fix/package/GRM_ParticleTransition').glob('*.script')]
dlls=[Path(x).read_bytes() for x in ['/data/grm/newbin_last/bin/xrGame.dll','/data/grm/ogsrpose/package/GRM_OGSR_POSE/xrGame.dll','/data/grm/corpsegore/package/GRM_Corpse/engine0.dll','/data/grm/corpsegore/package/GRM_Corpse/engine1.dll']]
for x in list(dlls):
 y=bytearray(x)
 for pos in (0x7285e,0x728b5):y[pos:pos+7]=bytes.fromhex('8b842418200000')
 dlls.append(bytes(y))
cmd=['/data/pwsh/pwsh','-NoProfile','-File',str(mock/'GRM_RenderNeck.ps1')]
def run(): return subprocess.run(cmd,capture_output=True,text=True)
for s in ins:
 exe.write_bytes(orig);dll.write_bytes(dlls[0]);script.write_bytes(Path(s).read_bytes());q=run();assert q.returncode==0 and exe.read_bytes()==patched,(s,q.stdout,q.stderr)
 q=run();assert q.returncode==0 and exe.read_bytes()==patched,(q.stdout,q.stderr)
print('PASS 12 script versions and repeat')
for d in dlls:
 exe.write_bytes(orig);dll.write_bytes(d);q=run();assert q.returncode==0 and exe.read_bytes()==patched,(hashlib.sha256(d).hexdigest(),q.stdout,q.stderr)
print('PASS 8 dll variants')
for what in ('exe','dll','script','payload'):
 exe.write_bytes(orig);dll.write_bytes(dlls[0]);script.write_bytes(Path(ins[0]).read_bytes());pay=mock/'GRM_RenderNeck/XR_3DA.patched';pay.write_bytes(patched)
 target={'exe':exe,'dll':dll,'script':script,'payload':pay}[what];target.write_bytes(b'wrong');before=exe.read_bytes();q=run();assert q.returncode!=0 and exe.read_bytes()==before,(what,q.stdout,q.stderr)
print('PASS mismatch refuses modification')
