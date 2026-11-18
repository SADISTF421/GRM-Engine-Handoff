from pathlib import Path
import hashlib,json
r=Path(__file__).resolve().parents[2];variants=json.loads((r/'SOURCE/variants.json').read_text())
def h(p):return hashlib.sha256(p.read_bytes()).hexdigest()
installer=(r/'INSTALL/INSTALL_GRM.ps1').read_text(encoding='utf-8-sig')
for v in variants:
 p=r/'INSTALL/payload'/v['payload'];assert h(p)==v['new'];assert p.read_bytes()==(r/'SOURCE'/v['payload']).read_bytes();assert v['old'] in installer and v['new'] in installer
mgr=r/'INSTALL/payload/sl_sidecar_manager.script'; assert mgr.read_bytes()==(r/'SOURCE'/mgr.name).read_bytes();assert h(mgr) in installer
assert all(p.suffix=='.script' for p in (r/'INSTALL/payload').iterdir())
assert all((r/p).exists() for p in ['MANIFEST.txt','ROLLBACK_EXACT','TOOLS/SAVE_SNAPSHOT.bat'])
for name in ['grm_gore_test__original.script','grm_gore_test__previousV3.script']:
 s=(r/'INSTALL/payload'/name).read_bytes();assert b'sl_sidecar_manager.mark_hidden(obj)' in s
assert b'io.open' in mgr.read_bytes() and b'function load_gore_data' in mgr.read_bytes()
print('PASS: script variants, source copies, hashes in installer, manager and folder layout')
