local root='/data/grm/v32/gamedata/scripts/'
function printf()end
level={name=function()return 'cordon' end}
local mode='valid'
function alife()return{object=function(self,id)
 if id==2 then return nil end
 if id==4 and mode=='error' then error('lookup') end
 return {name=function()return id==3 and 'reused' or ('npc'..id) end,section_name=function()return 'stalker' end}
end}end
local env=setmetatable({},{__index=_G});assert(loadfile(root..'sl_sidecar_manager.script','t',env))()
for id=1,4 do assert(env.mark_hidden({id=function()return id end,name=function()return 'npc'..id end,section=function()return 'stalker' end})) end
local ok,n=env.prune_deleted();assert(ok and n==2 and env.count()==2)
mode='error';ok=env.prune_deleted();assert(not ok and env.count()==2)
print('PASS: prune missing/reused IDs, fail-closed on lookup error in mocks')
