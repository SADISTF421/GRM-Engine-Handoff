from pathlib import Path
import hashlib,zipfile
r=Path(__file__).resolve().parents[2]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
checks={'grm_gore_test.script':'2f598d7fc6178de3d6b8f8ee813a23c5fbc0598ff3b854de32d295ce9575e85e','xr_motivator.script':'5cf24ef2a81dfe4e0a4c178dd0c6c893af3259f028a66df3410641625314e4bb'}
for name,h in checks.items():
 p=r/'INSTALL/payload'/name;assert sha(p)==h;assert p.read_bytes()==(r/'SOURCE'/name).read_bytes()
for p in (r/'INSTALL/payload').iterdir():assert p.suffix=='.script'
assert all((r/p).exists() for p in ['MANIFEST.txt','ROLLBACK_EXACT','TOOLS/SAVE_SNAPSHOT.bat','INSTALL/INSTALL_GRM.ps1'])
print('PASS: payload hashes, source copies, folder layout, only script payload')
