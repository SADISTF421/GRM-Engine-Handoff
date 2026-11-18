import hashlib,struct,pathlib,sys
p=pathlib.Path(sys.argv[1]);b=bytearray(p.read_bytes())
assert hashlib.sha256(b).hexdigest()=='7526ad7042e1ad3eead1a89baf15d1ac7be1dcae71bc27db2b0f24010c690d45'
assert b[0x729a0:0x729a5]==bytes.fromhex('8b4e108b01')
assert b[0x603d40:0x603d60]==bytes(32)
assert struct.unpack_from('<I',b,0x2c0)[0]==0x92b
site=0x735a0;cave=0x61f940;skip=0x735cd;normal=0x735a5
rel=lambda src,dst:struct.pack('<i',dst-src)
hook=b'\xe9'+rel(site+5,cave)
stub=bytes.fromhex('8b4e1085c90f84')+rel(cave+11,skip)+bytes.fromhex('8b01e9')+rel(cave+18,normal)
assert len(stub)==18
b[0x729a0:0x729a5]=hook;b[0x603d40:0x603d40+len(stub)]=stub;struct.pack_into('<I',b,0x2c0,0x952)
out=pathlib.Path(__file__).resolve().parent.parent;(out/'test_patched.dll').write_bytes(b);(out/'SOURCE/TESTS/hook.bin').write_bytes(hook);(out/'SOURCE/TESTS/stub.bin').write_bytes(stub)
print('hook',hook.hex(' ')); print('stub',stub.hex(' '));print('patched SHA256',hashlib.sha256(b).hexdigest())
