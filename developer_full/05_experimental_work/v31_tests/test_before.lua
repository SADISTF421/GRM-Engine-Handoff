local base='/data/grm/v31/'; local messages=0
function printf(...) messages=messages+1 end
local map='cordon';level={name=function()return map end};function getFS()return{update_path=function(self,a,b)return '/data/grm/v31_tests/tmp/'..b:match('([^\\]+)$')end}end
local lookups=0
function alife()return{object=function(self,id)lookups=lookups+1;if id%2==1 then return {} end;return nil end}end
local env=setmetatable({},{__index=_G});assert(loadfile(base..'gamedata/scripts/sl_sidecar_manager.script','t',env))()
for id=1,200 do assert(env.mark_hidden({id=function()return id end,section=function()return 'npc' end,name=function()return 'name_'..id end})) end
local ok,n=env.before_save();assert(ok and n==100 and lookups==200 and env.count()==100)
local f=assert(io.open('/data/grm/v31_tests/tmp/grm_runtime_unconfirmed.txt','rb'));local t=f:read('*a');f:close();assert(t:find('count=100',1,true))
env.forget(3);assert(env.count()==99)
env.io=false;ok=env.before_save();assert(not ok and env.count()==0)
env.io=io;assert(env.mark_hidden({id=function()return 5 end,section=function()return'npc'end,name=function()return'n'end}))
env.alife=function()return{object=function() error('lookup') end}end
ok=env.before_save();assert(not ok and env.count()==1)
print('PASS mock: 200 records, 100 removed IDs pruned before snapshot; direct forget; absent IO resets; failed lookup does not delete')
