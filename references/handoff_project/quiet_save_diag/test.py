from pathlib import Path
import shutil,subprocess
p=Path('/data/grm/quiet_save_diag');mock=p/'mock';shutil.rmtree(mock,ignore_errors=True);shutil.copytree(p/'package',mock);(mock/'bin').mkdir();shutil.copy('/data/grm/newbin_last/bin/XR_3DA.exe',mock/'bin/XR_3DA.exe');target=mock/'bin/xrGame.dll'
fs=['/data/grm/newbin_last/bin/xrGame.dll','/data/grm/ogsrpose/package/GRM_OGSR_POSE/xrGame.dll','/data/grm/corpsegore/package/GRM_Corpse/engine0.dll','/data/grm/corpsegore/package/GRM_Corpse/engine1.dll'];cmd=['/data/pwsh/pwsh','-NoProfile','-File',str(mock/'GRM_QuietSaveDiag.ps1')]
for f in fs:
 old=Path(f).read_bytes();target.write_bytes(old);r=subprocess.run(cmd,capture_output=True,text=True);assert r.returncode==0,(r.stdout,r.stderr);new=target.read_bytes();expected=bytearray(old)
 for offset in (0x7285e,0x728b5):expected[offset:offset+7]=bytes.fromhex('8b842418200000')
 assert new==expected; r=subprocess.run(cmd,capture_output=True,text=True);assert r.returncode==0;print('PASS: patch, only 14 bytes, idempotent',f)
target.write_bytes(b'bad dll');r=subprocess.run(cmd,capture_output=True,text=True);assert r.returncode!=0 and target.read_bytes()==b'bad dll';print('PASS: unknown DLL rejected without changes')
shutil.copy(fs[0],target); (mock/'bin/XR_3DA.exe').write_bytes(b'bad');r=subprocess.run(cmd,capture_output=True,text=True);assert r.returncode!=0 and target.read_bytes()==Path(fs[0]).read_bytes();print('PASS: unknown EXE rejected without changes')
