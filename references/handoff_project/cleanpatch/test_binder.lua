local function loadsave(path, env)
 local f=assert(io.open(path,'rb'));local s=f:read('*a'); f:close()
 local a=assert(s:find('function actor_binder:save%(packet%)'))
 local b=assert(s:find('function actor_binder:load%(reader%)',a))
 assert(load(s:sub(a,b-1),path,'t',env))()
 return env.actor_binder.save
end
local records={}
local function env()
 local e=setmetatable({}, {__index=_G})
 e.actor_binder={}
 e.printf=function(fmt,...) if fmt:find('GRM_ACTOR_BYTES',1,true) then records[#records+1]=string.format(fmt,...) end end
 e.shiza_skeleton_illusion={before_save=function() end}; e.shiza_bar_light_flicker={before_save=function() end}
 e.level={get_game_difficulty=function() return 2 end}
 e.object_binder={save=function(self,p) p:add('BIND') end}
 for _,k in ipairs({'shiza_hud_items','shiza_radiation','shiza_vodka','shiza_kill_stress','shiza_syringe'}) do e[k]={save_state=function() end} end
 e.xr_logic={pstor_save_all=function(obj,p) p:add('PSTOR') end}
 e.sr_psy_antenna={save=function(p) p:add('ANTENNA') end}
 e.treasure_manager={save=function(p) p:add('TREASURE') end}
 e.task_manager={save=function(p) p:add('TASKS') end}
 e.utils={w_CTime=function(p) p:add('TIME') end}
 return e
end
local function packet()
 local p={data=''};function p:add(s) self.data=self.data..s end
 function p:w_u8(v) self:add(string.char(v)) end
 function p:w_bool(v) self:add(v and '1' or '0') end
 function p:w_tell() return #self.data end
 return p
end
local self={st={},object={name=function() return "actor" end},weather_manager={save=function(_,p) p:add('WEATHER') end},actor_detector={save=function(_,p) p:add('DETECTOR') end}}
local pairs={
 {'/data/grm/current/scripts.rar/scripts/bind_stalker.script','/data/grm/cleanpatch/package/GRM_CleanDiag/binder0.script'},
 {'/data/grm/savefix/gamedata/scripts/bind_stalker.script','/data/grm/cleanpatch/package/GRM_CleanDiag/binder1.script'} }
for _,paths in ipairs(pairs) do
 records={};local a,b=packet(),packet();loadsave(paths[1],env())(self,a);loadsave(paths[2],env())(self,b)
 assert(a.data==b.data,'serialization changed');assert(#records==8,'expected 8 diagnostic measurements')
 assert(records[#records]:match('detector '..#b.data..'$'),'end length incorrect')
end
print('PASS: save bytes unchanged, probes report stage positions')
