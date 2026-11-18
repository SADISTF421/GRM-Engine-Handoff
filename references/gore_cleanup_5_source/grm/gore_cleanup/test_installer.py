from pathlib import Path
import json,hashlib,shutil,subprocess
r=Path('/data/grm/gore_cleanup');p=r/'package';m=r/'mock';shutil.rmtree(m,ignore_errors=True);shutil.copytree(p,m);(m/'bin').mkdir();(m/'gamedata/scripts').mkdir(parents=True)
exe=m/'bin/XR_3DA.exe';dll=m/'bin/xrGame.dll';script=m/'gamedata/scripts/grm_gore_test.script';exe.write_bytes(Path('/data/grm/newbin_last/bin/XR_3DA.exe').read_bytes())
dfiles=['/data/grm/newbin_last/bin/xrGame.dll','/data/grm/ogsrpose/package/GRM_OGSR_POSE/xrGame.dll','/data/grm/corpsegore/package/GRM_Corpse/engine0.dll','/data/grm/corpsegore/package/GRM_Corpse/engine1.dll']; originals=[Path(x).read_bytes() for x in dfiles]
for x in originals[:]:
 n=bytearray(x)
 for off in (0x7285e,0x728b5):n[off:off+7]=bytes.fromhex('8b842418200000')
 originals.append(bytes(n))
sfiles=['/data/grm/chance75/package/GRM_Chance75/grm_gore_test.script','/data/grm/fasthead/grm_gore_fast.script','/data/grm/cleanpatch/package/GRM_CleanDiag/gore0.script','/data/grm/cleanpatch/package/GRM_CleanDiag/gore1.script','/data/grm/corpsegore/package/GRM_Corpse/gore0.script','/data/grm/corpsegore/package/GRM_Corpse/gore1.script']+[str(x) for x in sorted(Path('/data/grm/particle_transition_fix/package/GRM_ParticleTransition').glob('*.script'))]; rows=json.loads((r/'rows.json').read_text()); drows=json.loads((r/'dllrows.json').read_text())
cmd=['/data/pwsh/pwsh','-NoProfile','-File',str(m/'GRM_Cleanup.ps1')];sha=lambda b:hashlib.sha256(b).hexdigest()
def run():return subprocess.run(cmd,capture_output=True,text=True)
for s,row in zip(sfiles,rows):
 dll.write_bytes(originals[0]);script.write_bytes(Path(s).read_bytes());q=run();assert q.returncode==0,(s,q.stdout,q.stderr);assert sha(script.read_bytes())==row['new'] and sha(dll.read_bytes())==drows[0]['new'];q=run();assert q.returncode==0,(q.stdout,q.stderr)
print('PASS 12 scripts, installation, repeat')
for d,row in zip(originals,drows):
 dll.write_bytes(d);script.write_bytes(Path(sfiles[0]).read_bytes());q=run();assert q.returncode==0,(q.stdout,q.stderr);assert sha(dll.read_bytes())==row['new']
print('PASS 8 DLL versions')
for type in ('exe','dll','script','payload'):
 dll.write_bytes(originals[0]);script.write_bytes(Path(sfiles[0]).read_bytes());exe.write_bytes(Path('/data/grm/newbin_last/bin/XR_3DA.exe').read_bytes());payload=m/'GRM_Cleanup'/rows[0]['file'];payload.write_bytes((p/'GRM_Cleanup'/rows[0]['file']).read_bytes());target={'exe':exe,'dll':dll,'script':script,'payload':payload}[type];target.write_bytes(b'unknown');before=(exe.read_bytes(),dll.read_bytes(),script.read_bytes());q=run();assert q.returncode!=0 and before==(exe.read_bytes(),dll.read_bytes(),script.read_bytes()),(type,q.stdout,q.stderr)
print('PASS refuses mismatches and damaged payload without changes')
