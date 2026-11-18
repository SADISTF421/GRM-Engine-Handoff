printf=function() end
local old_env={CRandomTask={}};setmetatable(old_env,{__index=_G})
local new_env={CRandomTask={}};setmetatable(new_env,{__index=_G})
utils={w_CTime=function(p,t) p:w_u32(t or 0) p:w_u32(0x12345678) end,r_CTime=function(p) local t=p:r_u32() assert(p:r_u32()==0x12345678) return t end,cfg_get_number=function(...)return 77 end}
alife=function() return {object=function(_,id) return {spawn_ini=function() return {} end} end} end
assert(loadfile('/data/grm/savecompact/old_part.lua','t',old_env))()
assert(loadfile('/data/grm/savecompact/new_part.lua','t',new_env))()
local function packet()
 local p={data='',pos=0}
 function p:w_u8(x) assert(x>=0 and x<=255) self.data=self.data..string.pack('<I1',x) end
 function p:w_u16(x) assert(x>=0 and x<=65535) self.data=self.data..string.pack('<I2',x) end
 function p:w_u32(x) self.data=self.data..string.pack('<I4',x % 4294967296) end
 function p:w_bool(x) self:w_u8(x and 1 or 0) end
 function p:w_stringZ(x) assert(type(x)=='string') self.data=self.data..x..'\0' end
 function p:r_u8() local a,n=string.unpack('<I1',self.data,self.pos+1) self.pos=n-1 return a end
 function p:r_u16() local a,n=string.unpack('<I2',self.data,self.pos+1) self.pos=n-1 return a end
 function p:r_u32() local a,n=string.unpack('<I4',self.data,self.pos+1) self.pos=n-1 if a==4294967295 then return -1 end return a end
 function p:r_bool() return self:r_u8() ~= 0 end
 function p:r_stringZ() local a,n=string.unpack('z',self.data,self.pos+1) self.pos=n-1 return a end
 function p:r_tell() return self.pos end
 function p:r_seek(x) self.pos=x end
 function p:r_elapsed() return #self.data-self.pos end
 return p
end
local statuses={'normal','selected','completed','refused','failed','rewarded','custom',''}
local function create(n)
 local t={task_info={},active_task_by_type={kill='task0001',misc='task0002'}}
 for i=1,n do
  local name=string.format('task%04d',i)
  t.task_info[name]={type=i%30==0 and 'defend_lager' or 'find_item',enabled=i%2==0,enabled_props=i%3==0,status=statuses[i%#statuses+1],selected_target=(i%4~=0 and i or nil),last_task_time=10000+i}
 end
 return t
end
local function blank(src)
 local out={task_info={},active_task_by_type={}}
 for k,v in pairs(src.task_info) do out.task_info[k]={type=v.type} end
 return out
end
local function equal(a,b)
 for k,x in pairs(a.task_info) do
  local y=b.task_info[k]; assert(y,k)
  for _,field in ipairs({'enabled','enabled_props','status','last_task_time'}) do assert(x[field]==y[field], k..':'..field) end
  assert((x.selected_target or -1)==(y.selected_target or -1), k..':target')
  if x.type=='defend_lager' then assert(y.defend_target==77) end
 end
 for k,v in pairs(a.active_task_by_type) do assert(b.active_task_by_type[k]==v) end
end
for _,n in ipairs({0,1,10,146,254,255,256}) do
 local source=create(n)
 local packed=packet();new_env.CRandomTask.save(source,packed)
 local result=blank(source);new_env.CRandomTask.load(result,packed);assert(packed:r_elapsed()==0);equal(source,result)
 if n<=255 then
  local legacy=packet();old_env.CRandomTask.save(source,legacy)
  local readold=blank(source);new_env.CRandomTask.load(readold,legacy);assert(legacy:r_elapsed()==0);equal(source,readold)
  print('tasks='..n..' legacy='..#legacy.data..' compact='..#packed.data..' saved='..(#legacy.data-#packed.data))
 end
end
-- Проверка неопознанного маркера: старый формат с 255 задачами.
local src=create(255); local q=packet(); old_env.CRandomTask.save(src,q); assert(q.data:byte(1)==255)
local restored=blank(src); new_env.CRandomTask.load(restored,q); equal(src,restored);assert(q:r_elapsed()==0)
print('PASS legacy and compact round trips, marker 255, custom statuses, defend task')
-- Следующие данные актёра не должны попадать в формат задач.
for _, n in ipairs({0, 1, 10, 146, 255, 256}) do
 local source=create(n)
 for _, writer in ipairs(n<=255 and {old_env.CRandomTask.save,new_env.CRandomTask.save} or {new_env.CRandomTask.save}) do
  local p=packet(); writer(source,p); p:w_u32(0x13572468); p:w_stringZ('next component')
  local dst=blank(source); new_env.CRandomTask.load(dst,p); equal(source,dst)
  assert(p:r_u32()==0x13572468); assert(p:r_stringZ()=='next component'); assert(p:r_elapsed()==0)
 end
end
print('PASS following components remain aligned')
