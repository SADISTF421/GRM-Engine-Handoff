from pathlib import Path
import struct,hashlib
p=Path('/data/grm/boneengine'); b=p.joinpath('stub.bin').read_bytes(); sha=lambda x:hashlib.sha256(x).hexdigest();
for nm in ('original','particlefixed'):
 data=bytearray(Path('/data/grm/restoreguard/'+nm+'.dll').read_bytes()); before=sha(data)
 assert data[0x146310:0x146316]==bytes.fromhex('558bec83e4f8')
 assert data[0x6036a0:0x6036a0+len(b)]==bytes(len(b))
 assert struct.unpack_from('<I',data,0x2c0)[0]==0x297
 assert 0x2a0+len(b)<=0x400
 data[0x146310:0x146316]=b'\xe9'+struct.pack('<i',0x1061f2a0-0x10146f10-5)+b'\x90'
 data[0x6036a0:0x6036a0+len(b)]=b
 struct.pack_into('<I',data,0x2c0,0x2a0+len(b))
 p.joinpath(nm+'.dll').write_bytes(data)
 print(nm,before,sha(data),hex(0x2a0+len(b)))
s=Path('/data/grm/preshot/gamedata/scripts/grm_gore_test.script').read_bytes().decode('cp1251')
a=s.index('local function setup()'); z=s.index('\n-- ',a)
s=s[:a]+'''local function setup()
    if not attempted then
        attempted = true
        notice("ENGINE BONE MODE")
    end
    return true
end'''+s[z:]
s=s.replace('return corpse:bone_position("__grm_render_register__").x','return corpse:bone_position("__grm_test_hide_head__").x',1)
s=s.replace('notice("RENDER REGISTERED")','notice("HEAD HIDDEN")',1).replace('notice("REGISTER FAILED")','notice("HEAD HIDE FAILED")',1)
a=s.index('    elseif binder.grm_gore_anchored then\n',s.index('function update(binder)'))
z=s.index('\n    end\n    local blood',a)
s=s[:a]+'''    elseif binder.grm_gore_anchored and binder.grm_gore_map ~= level.name() then
        binder.grm_gore_anchored = nil
        binder.grm_gore_refresh = nil
        binder.grm_gore_map = nil
        binder.grm_gore_blood = nil'''+s[z:]
s=s.replace('-- Состояние эффекта временное и не записывается в сохранение.','-- Видимость кости обрабатывает движок; кровь и задержки временные.')
assert '__grm_render_register__' not in s and 'grm_stress_loadlib' not in s
out=s.encode('cp1251');p.joinpath('grm_gore_test.script').write_bytes(out); print('script',sha(out),len(out))
