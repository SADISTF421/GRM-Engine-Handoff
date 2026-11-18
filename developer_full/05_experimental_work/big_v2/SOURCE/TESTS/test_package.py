from pathlib import Path
import hashlib,json,sys
r=Path(__file__).resolve().parents[2]; rows=json.loads((r/'SOURCE/hashes.json').read_text());sha=lambda b:hashlib.sha256(b).hexdigest();installer=(r/'INSTALL/INSTALL_GRM.ps1').read_text(encoding='utf-8-sig');tool=(r/'TOOLS/CHECK_VERSIONS.ps1').read_text(encoding='utf-8-sig')
assert len(rows)==3 and len({x['name'] for x in rows})==3
for x in rows:
 p=(r/'INSTALL/payload'/x['name']).read_bytes();assert sha(p)==x['new'];assert p==(r/'SOURCE'/x['name']).read_bytes()
 assert x['old'] in installer and x['new'] in installer and x['old'] in tool and x['new'] in tool
if len(sys.argv)>1:
 base=Path(sys.argv[1]);orig=base/'scripts.rar/scripts';engine=base/'bin.rar/bin/xrGame.dll';exe=base/'bin.rar/bin/XR_3DA.exe'
 for x in rows: assert sha((orig/x['name']).read_bytes())==x['old']
 b=engine.read_bytes();assert sha(b)=='7526ad7042e1ad3eead1a89baf15d1ac7be1dcae71bc27db2b0f24010c690d45'
 assert sha(exe.read_bytes())=='ae91b0b55e7e9d80a5dee21213ae4224d6d6809fbe99d1fbac5dd54f8cbbc525'
 assert b[0x7285e:0x72865]==b'\x8b\x84\x24\x18\x20\x00\x00' and b[0x728b5:0x728bc]==b'\x8b\x84\x24\x18\x20\x00\x00' and b[0x6038ee:0x6038f0]==b'\xeb\x2b'
 print('PASS input hashes and reference instruction bytes, no binary changes')
assert (r/'SOURCE/INSTALL_GRM_source.ps1').read_bytes()==(r/'INSTALL/INSTALL_GRM.ps1').read_bytes()
for n in ['GRM_SaveValidator.ps1','GRM_SaveRepair.ps1','CHECK_VERSIONS.ps1','GRM_SaveSafety.ps1']:
 assert (r/'SOURCE'/(Path(n).stem+'_source.ps1')).read_bytes()==(r/'TOOLS'/n).read_bytes()
print('PASS payload hashes, script source copies, installer and tool source equality')
