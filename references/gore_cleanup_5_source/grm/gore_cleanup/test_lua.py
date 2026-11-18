from pathlib import Path
import subprocess,re
r=Path('/data/grm/gore_cleanup'); payload=r/'payload'
cases=[('100_popup_old','chance75/test.lua'),('50_popup_old','fasthead/test.lua'),('100_quiet_old','cleanpatch/test_gore0.lua'),('50_quiet_old','cleanpatch/test_gore1.lua'),('100_corpse_old','corpsegore/test_gore_corpse0.lua'),('50_corpse_old','corpsegore/test_gore_corpse1.lua'),('100ms_popup_transition','chance75/test.lua'),('50ms_popup_transition','fasthead/test.lua'),('100ms_quiet_transition','cleanpatch/test_gore0.lua'),('50ms_quiet_transition','cleanpatch/test_gore1.lua'),('100ms_corpse_transition','corpsegore/test_gore_corpse0.lua'),('50ms_corpse_transition','corpsegore/test_gore_corpse1.lua')]
for variant,test in cases:
 text=(Path('/data/grm')/test).read_text(); text=re.sub(r"dofile\('[^']+'\)","dofile('"+str(payload/(variant+'.script'))+"')",text,count=1); t=r/'temp.lua';t.write_text(text)
 q=subprocess.run(['python3','/data/grm/run_lua_file.py',str(t)],capture_output=True,text=True)
 if q.returncode: print('FAILED',variant, q.stdout, q.stderr);raise SystemExit(1)
 print('PASS',variant,q.stdout.strip())
