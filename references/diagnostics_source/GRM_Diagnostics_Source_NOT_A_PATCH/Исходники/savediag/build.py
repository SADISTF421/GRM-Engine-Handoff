from pathlib import Path
import struct, hashlib
P=Path('/data/grm/savediag'); sha=lambda b:hashlib.sha256(b).hexdigest(); hook=(P/'hook.bin').read_bytes()
for label,src in [('original','/data/grm/current/bin.rar/bin/xrGame.dll'),('particlefixed','/data/grm/enginefix/xrGame-test.dll')]:
 b=bytearray(Path(src).read_bytes()); before=sha(b);pe=struct.unpack_from('<I',b,0x3c)[0];n=struct.unpack_from('<H',b,pe+6)[0];optsz=struct.unpack_from('<H',b,pe+20)[0]; sh=pe+24+optsz; sections=[]
 for i in range(n):
  s=sh+40*i; name=bytes(b[s:s+8]).rstrip(b'\0');vsz,va,rawsz,raw=struct.unpack_from('<IIII',b,s+8);sections.append((name,vsz,va,rawsz,raw,s))
 name,vsz,va,rawsz,raw,s=sections[-1]; assert (name,vsz,va,rawsz,raw)==(b'.grm',0x1a9,0x61f000,0x200,0x603400);assert len(b)==raw+rawsz
 assert len(hook)<=0x200
 b.extend(bytes(0x200)); b[raw+0x200:raw+0x200+len(hook)]=hook
 struct.pack_into('<I',b,s+8,0x200+len(hook));struct.pack_into('<I',b,s+16,0x400)
 for target in (0x1007345e,0x100734b5):
  off=target-0x10001000+0x400; assert b[off:off+7]==bytes.fromhex('8b842418200000')
  rel=0x1061f200-(target+5);b[off:off+7]=b'\xe8'+struct.pack('<i',rel)+b'\x90\x90'
 (P/(label+'.dll')).write_bytes(b)
 print(label,'input',before,'output',sha(b),'size',hex(len(b)), 'sectionheader',hex(s),'hook',hex(raw+0x200))
