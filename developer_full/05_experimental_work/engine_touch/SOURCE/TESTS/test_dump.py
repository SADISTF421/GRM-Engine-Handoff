import sys,struct,uuid,os
sys.path.insert(0,os.path.join(os.path.dirname(__file__),'..','..','TOOLS'))
from dump_rva import read_modules
x=bytearray(300);struct.pack_into('<IIII',x,0,0x504d444d,0,1,32);struct.pack_into('<III',x,32,4,112,44);struct.pack_into('<I',x,44,1)
name='C:\\Game\\xrGame.dll'.encode('utf-16le');struct.pack_into('<QIIII',x,48,0x05f00000,0x100000,0,0,170);struct.pack_into('<I',x,170,len(name));x[174:174+len(name)]=name
rsds=b'RSDS'+uuid.UUID('724c6851-5c9e-40f9-bb95-fc13b75f7e67').bytes_le+struct.pack('<I',22)+b'xrGame.pdb\0'
struct.pack_into('<II',x,48+76,len(rsds),230);x[230:230+len(rsds)]=rsds
m=read_modules(x);assert len(m)==1 and m[0][1]==0x05f00000 and 'age 22' in m[0][3];assert 0x05fbdcfb-m[0][1]==0xbdcfb
for i in [0,10,45,80]:
 try: read_modules(x[:i]);raise AssertionError('truncation accepted')
 except ValueError: pass
print('PASS synthetic minidump: RVA, RSDS age, truncated bounds; not actual crash')
