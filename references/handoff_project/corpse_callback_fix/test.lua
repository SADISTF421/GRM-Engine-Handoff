local f=assert(io.open('/data/grm/corpse_callback_fix/package/GRM_Corpse_Callback/xr_motivator.script','rb'));local src=f:read('*a');f:close()
local env=setmetatable({motivator_binder={}, callback={hit=1,death=2}}, {__index=_G})
local a=assert(src:find('function motivator_binder:clear_callbacks()',1,true));local b=assert(src:find('function motivator_binder:use_callback',a,true));assert(load(src:sub(a,b-1),'motivator','t',env))()
local callbacks={};local alive=false;local obj={alive=function() return alive end, id=function() return 5 end,name=function() return 'npc' end,set_patrol_extrapolate_callback=function() end,set_callback=function(_,kind,fn,owner) callbacks[kind]=fn end}
local binder=setmetatable({object=obj,st={}}, {__index=env.motivator_binder});local corpse_calls=0;local logs=0
env.grm_gore_test={death=function() end,corpse_hit=function(self,who,bone) corpse_calls=corpse_calls+1;assert(bone==13) end,hit=function() error('should not call live') end}
env.grm_active_ragdoll={on_death=function() end};env.grm_painter_combat={on_death=function() end};env.sr_territory={issue_event=function() end};env.sr_light={check_light=function() end};env.smart_terrain={on_death=function() end};env.death_manager={drop_manager=function() return {create_release_item=function() end} end};env.printf=function() logs=logs+1 end;env.db={actor=nil};env.time_global=function() return 100 end
callbacks[1]=env.motivator_binder.hit_callback;callbacks[2]=env.motivator_binder.death_callback
binder:death_callback(obj,nil);assert(callbacks[1]==env.motivator_binder.hit_callback and callbacks[2]==nil,'death removed hit callback')
callbacks[1](binder,obj,0,{},nil,13);assert(corpse_calls==1,'corpse callback not invoked');binder:clear_callbacks();assert(callbacks[1]==nil,'cleanup did not clear hit')
print('PASS: real death callback retains hit, corpse dispatches, cleanup clears')
