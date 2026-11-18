from pathlib import Path
import shutil,subprocess
r=Path('/data/grm/gore_cleanup');m=r/'atomic';shutil.rmtree(m,ignore_errors=True);shutil.copytree(r/'package',m);(m/'bin').mkdir();(m/'gamedata/scripts').mkdir(parents=True)
exe=m/'bin/XR_3DA.exe';dll=m/'bin/xrGame.dll';script=m/'gamedata/scripts/grm_gore_test.script';exe.write_bytes(Path('/data/grm/render_neck/package/GRM_RenderNeck/XR_3DA.patched').read_bytes());dll.write_bytes(Path('/data/grm/newbin_last/bin/xrGame.dll').read_bytes());script.write_bytes(Path('/data/grm/fasthead/grm_gore_fast.script').read_bytes());before=(dll.read_bytes(),script.read_bytes())
ps=m/'GRM_Cleanup.ps1';s=ps.read_text(encoding='utf-8-sig');old='[IO.File]::Replace($w.temp,$w.target,$w.backup);$w.done=$true; if';assert old in s;s=s.replace(old,"[IO.File]::Replace($w.temp,$w.target,$w.backup);$w.done=$true; throw 'injected'; if");ps.write_text(s,encoding='utf-8-sig')
q=subprocess.run(['/data/pwsh/pwsh','-NoProfile','-File',str(ps)],capture_output=True,text=True);assert q.returncode and before==(dll.read_bytes(),script.read_bytes()),(q.stdout,q.stderr);print('PASS transactional failure restore; accepts modified EXE')
