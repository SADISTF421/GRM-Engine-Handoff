import pathlib,hashlib,struct,sys,base64
src=pathlib.Path(sys.argv[1]); b=bytearray(src.read_bytes())
assert hashlib.sha256(b).hexdigest()=='3a1ac31b52efd39965c89c5e43347e4e059adfcfb7cd6a16f85bc05f0716528b'
assert b[0x729a0:0x729a5].hex()=='e99bc35a00'
assert b[0x2c0:0x2c4].hex()=='52090000'
code=(pathlib.Path(__file__).parent/'guard.bin').read_bytes()
assert len(code)==280 and b[0x603e00:0x603e00+len(code)]==bytes(len(code))
b[0x729a0:0x729a5]=bytes.fromhex('e95bc45a00')
b[0x603e00:0x603e00+len(code)]=code
struct.pack_into('<I',b,0x2c0,0xb18)
out=pathlib.Path(sys.argv[2]);out.write_bytes(b)
print('guard base64',base64.b64encode(code).decode());print('output SHA256',hashlib.sha256(b).hexdigest())
