from pathlib import Path
import difflib,hashlib,json
D=Path('/data/grm');B=D/'current2026/scripts.rar/scripts';V2=D/'big_v2/INSTALL/payload';V3=D/'v3/INSTALL/payload';O=D/'sidecar_v3';P=O/'INSTALL/payload';specs=[]
def sha(b):return hashlib.sha256(b).hexdigest()
def change(s,a,b):
 assert s.count(a)==1,(a[:120],s.count(a));return s.replace(a,b,1)
def variant(target,label,origin,fn):
 raw=origin.read_bytes();s=raw.decode('cp1251'); out=fn(s).encode('cp1251');name=target.replace('.script','')+'__'+label+'.script'; (P/name).write_bytes(out); (O/'SOURCE'/name).write_bytes(out)
 (O/'SOURCE'/(name+'.diff')).write_text(''.join(difflib.unified_diff(s.splitlines(True),out.decode('cp1251').splitlines(True),fromfile=target+'_'+label,tofile=name)),encoding='utf-8')
 specs.append(dict(target=target,variant=label,old=sha(raw),new=sha(out),payload=name))
def gore(s):return change(s,'                binder.grm_gore_anchored = true','                pcall(function() sl_sidecar_manager.mark_hidden(obj) end)\n                binder.grm_gore_anchored = true')
def actor(s):
 s=change(s,'function actor_binder:net_destroy()','function actor_binder:net_destroy()\n    pcall(function() sl_sidecar_manager.reset() end)')
 return change(s,'function actor_binder:reinit()','function actor_binder:reinit()\n    pcall(function() sl_sidecar_manager.reset() end)')
def rez(s):
 s=change(s,'    sl_rotting.forget(obj)\n\talife():release(alife():object(obj:id()), true)','    sl_rotting.forget(obj)\n    pcall(function() sl_sidecar_manager.forget(obj:id()) end)\n\talife():release(alife():object(obj:id()), true)')
 return change(s,'\t\t\talife():release(alife():object(obj:id()), true)','\t\t\tpcall(function() sl_sidecar_manager.forget(obj:id()) end)\n\t\t\talife():release(alife():object(obj:id()), true)')
def rot(s):
 s=change(s,'        alife():release(server,true);records[id]=nil;save_record(id,nil);return true','        pcall(function() sl_sidecar_manager.forget(id) end)\r\n        alife():release(server,true);records[id]=nil;save_record(id,nil);return true')
 return change(s,'    local next_stage=r.stage+1\r\n    alife():release(server,true)','    local next_stage=r.stage+1\r\n    pcall(function() sl_sidecar_manager.forget(id) end)\r\n    alife():release(server,true)')
variant('grm_gore_test.script','original',B/'grm_gore_test.script',gore)
variant('grm_gore_test.script','previousV3',V3/'grm_gore_test.script',gore)
variant('bind_stalker.script','original',B/'bind_stalker.script',actor)
variant('bind_stalker.script','V2',V2/'bind_stalker.script',actor)
variant('shiza_reznya.script','original',B/'shiza_reznya.script',rez)
variant('sl_rotting.script','original',B/'sl_rotting.script',rot)
(O/'SOURCE/variants.json').write_text(json.dumps(specs,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(specs,ensure_ascii=False,indent=1))
