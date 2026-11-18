import struct
from pathlib import Path
b=Path('/data/grm/current/bin.rar/bin/xrGame.dll').read_bytes()
def u16(o):return struct.unpack_from('<H',b,o)[0]
def u32(o):return struct.unpack_from('<I',b,o)[0]
e=u32(0x3c);ns=u16(e+6);op=e+24;opt=u16(e+20);image=u32(op+28);imp=u32(op+96+8); sections=[]
for i in range(ns):
 p=op+opt+i*40; n=b[p:p+8].split(b'\0')[0]; sz,va,rawsz,raw=struct.unpack_from('<IIII',b,p+8);sections.append((va,va+max(sz,rawsz),raw,n))
def off(r):
 for s,t,raw,n in sections:
  if s<=r<t:return raw+r-s
 raise ValueError(hex(r))
def st(r):
 o=off(r);return b[o:b.index(b'\0',o)].decode(errors='replace')
p=off(imp)
while u32(p) or u32(p+16):
 orig,_,_,name,first=struct.unpack_from('<IIIII',b,p)
 i=0
 while 1:
  v=u32(off((orig or first)+4*i))
  if not v:break
  if not v&0x80000000:
   n=st(v+2)
   if 'LL_SetBoneVisible' in n or 'LL_BoneID' in n:
    print(st(name), n, 'IAT',hex(image+first+4*i))
  i+=1
 p+=20
