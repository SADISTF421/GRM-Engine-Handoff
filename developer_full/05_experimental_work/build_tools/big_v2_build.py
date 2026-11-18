from pathlib import Path
import hashlib, json, difflib
root=Path('/data/grm/big_v2');cur=Path('/data/grm/current2026/scripts.rar/scripts')
sha=lambda x:hashlib.sha256(x).hexdigest()
patches={}
def read(n):return (cur/n).read_bytes().decode('cp1251')
name='task_manager.script';old=read(name);nl='\r\n' if '\r\n' in old else '\n'; s=old.replace('\r\n','\n')
needle='''        if p:r_u32() == grm_magic1 and p:r_u32() == grm_magic2 then
            compact = true
            count = p:r_u16()'''
new='''        if p:r_u32() == grm_magic1 and p:r_u32() == grm_magic2 then
            -- Маркер занял восемь байтов; для количества нужны ещё два.
            -- Повреждённые данные заданий не пропускаются и не обнуляются.
            if p:r_elapsed() < 2 then error("GRM: усечён заголовок задач") end
            compact = true
            count = p:r_u16()'''
assert s.count(needle)==1;s=s.replace(needle,new,1);patches[name]=s.replace('\n',nl).encode('cp1251')
name='bind_stalker.script';old=read(name);nl='\r\n' if '\r\n' in old else '\n';s=old.replace('\r\n','\n')
needle='''    local function grm_save_probe(label)
        pcall(function() printf("[GRM_ACTOR_BYTES] %s %u", label, packet:w_tell()) end)
    end
    grm_save_probe("start")

''';assert s.count(needle)==1;s=s.replace(needle,'',1)
for label in ('binder','pstor','weather','antenna','treasure','tasks','detector'):
 needle='    grm_save_probe("'+label+'")';assert s.count(needle)==1;s=s.replace(needle,'',1)
patches[name]=s.replace('\n',nl).encode('cp1251')
name='xr_motivator.script';old=read(name);nl='\r\n' if '\r\n' in old else '\n';s=old.replace('\r\n','\n');lines=s.splitlines(keepends=True);patterns=['printf("HIT_CALLBACK:', 'printf("[GORE_DIAG] hit id=', 'printf("[GORE_DIAG] death id=', 'printf("[GORE_DIAG] смерть не совпала']
for pat in patterns:assert sum(pat in l for l in lines)==1,pat
s=''.join(l for l in lines if not any(pat in l for pat in patterns));patches[name]=s.replace('\n',nl).encode('cp1251')
rows=[]
for name,data in patches.items():
 old=(cur/name).read_bytes();(root/'INSTALL/payload'/name).write_bytes(data);(root/'SOURCE'/name).write_bytes(data)
 a=old.decode('cp1251').splitlines(True);b=data.decode('cp1251').splitlines(True)
 (root/'SOURCE'/(name+'.diff')).write_text(''.join(difflib.unified_diff(a,b,fromfile='current/'+name,tofile='test/'+name)),encoding='utf-8')
 rows.append({'name':name,'old':sha(old),'new':sha(data)})
(root/'SOURCE'/'hashes.json').write_text(json.dumps(rows,indent=2),encoding='utf-8')
print('Prepared',len(rows),'script edits',*(f'{x["name"]}: {x["new"]}' for x in rows),sep='\n')
