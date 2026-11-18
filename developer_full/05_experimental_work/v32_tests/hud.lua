local root='/data/grm/current2026/scripts.rar/scripts/'
local saved={}
xr_logic={pstor_store=function(actor,key,value) saved[key]=value end,pstor_retrieve=function()return ''end}
local state=setmetatable({},{__index=_G});assert(loadfile(root..'shiza_state.script','t',state))();shiza_state=state
local hud=setmetatable({},{__index=_G});assert(loadfile(root..'shiza_hud_items.script','t',hud))()
local found=false
for i=1,30 do local name=debug.getupvalue(hud.save_state,i);if not name then break end;if name=='current_use' then debug.setupvalue(hud.save_state,i,{source='sigi',phase=3,animator_id=123,proxy_id=42,had_binoculars=true,actor=io.stdout,sound=io.stdout});found=true end end
assert(found);hud.save_state({})
local value=saved['shiza_state_v1_hud'];assert(type(value)=='string' and value:find('active=1',1,true) and value:find('animator=123',1,true) and value:find('proxy=42',1,true) and not value:find('userdata',1,true))
print('PASS: actual HUD save_state outputs numerical journal string, not actor/sound userdata; mock only')
