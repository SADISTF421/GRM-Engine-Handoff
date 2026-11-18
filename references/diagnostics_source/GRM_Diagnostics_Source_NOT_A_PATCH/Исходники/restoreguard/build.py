from pathlib import Path
import struct,hashlib
root=Path('/data/grm/restoreguard'); hook=(root/'hook.bin').read_bytes(); sha=lambda b:hashlib.sha256(b).hexdigest()
for label in ('original','particlefixed'):
 b=bytearray((Path('/data/grm/savediag')/(label+'.dll')).read_bytes()); inp=sha(b)
 assert b[0x1f1b9a:0x1f1ba0]==bytes.fromhex('8d9b00000000')
 assert b[0x603670:0x603670+len(hook)]==bytes(len(hook))
 assert struct.unpack_from('<I',b,0x2c0)[0]==0x261
 off=0x1f1b9a; start=0x101f279a; dst=0x1061f270
 b[off:off+6]=b'\xe9'+struct.pack('<i',dst-start-5)+b'\x90'
 b[0x603670:0x603670+len(hook)]=hook
 struct.pack_into('<I',b,0x2c0,0x270+len(hook))
 (root/(label+'.dll')).write_bytes(b)
 print(label,inp,sha(b),len(b))
