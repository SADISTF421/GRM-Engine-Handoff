from pathlib import Path
import hashlib,struct
root=Path('/data/grm/enginefix'); src=Path('/data/grm/current/bin.rar/bin/xrGame.dll'); b=bytearray(src.read_bytes());
sha=lambda x:hashlib.sha256(x).hexdigest()
assert sha(b)=='15a71719936493aeb534538e12b74235baded7466f7b1d9e4b0defee46716751'
def jmp(pc,target):return b'\xe9'+struct.pack('<i',target-(pc+5))
a=bytes.fromhex('8b81ac000000 85c0 7405 31d2 895004')+jmp(0x1019390f,0x1045ece2)
a=a.ljust(32,b'\xcc')
z=bytes.fromhex('8b81ac000000 85c0 7410 31d2 895004 8991ac000000')+jmp(0x10193935,0x1045ecdc)+b'\xc3'
z=z.ljust(32,b'\xcc')
assert len(a)==len(z)==32
old1=bytes.fromhex('8b81ac000000c7400400000000ff25fc684610')+b'\xcc'*13
old2=bytes.fromhex('8b81ac000000c7400400000000ff2500694610')+b'\xcc'*13
assert b[0x192d00:0x192d20]==old1 and b[0x192d20:0x192d40]==old2
assert b[0x57e9aa:0x57e9ae]==bytes.fromhex('0f392f39')
b[0x192d00:0x192d20]=a;b[0x192d20:0x192d40]=z;b[0x57e9aa:0x57e9ae]=bytes.fromhex('0f092f09')
(root/'xrGame-test.dll').write_bytes(b);(root/'code1.bin').write_bytes(a);(root/'code2.bin').write_bytes(z)
print('new SHA',sha(b));print('new1',a.hex());print('new2',z.hex());print('only bytes changed:',sum(x!=y for x,y in zip(src.read_bytes(),b)))
