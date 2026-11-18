local now=1000
function time_global()return now end
function printf()end
function vector()return{set=function(self,x,y,z)return self end}end
function device()return{cam_pos={x=0,y=0,z=0},cam_dir={x=0,y=0,z=1}}end
local actor={id=function()return 1 end,active_item=function()return {section=function()return 'wpn_toz34' end}end};db={actor=actor}
local npc={dead=false,id=function()return 7 end,section=function()return 'stalker' end,name=function()return 'npc7' end,alive=function(s)return not s.dead end,position=function()return{x=0,y=0,z=5}end,bone_position=function(s,n)if n=='__grm_test_head_id__' then return{x=13} elseif n=='__grm_test_hide_head__' then return{x=1} else return{x=0,y=0,z=5} end end}
level={name=function()return 'cordon' end,object_by_id=function()return npc end}
function system_ini()return{line_exist=function()return false end}end
function particles_object()return{playing=function()return false end,play_at_pos=function()end}end
sound_object=setmetatable({s3d=1},{__call=function()return{play_at_pos=function()end}end});math.random=function()return 1 end
-- Модуль загружается в собственное пространство имён, как game-скрипт.
local env=setmetatable({},{__index=_G});assert(loadfile('INSTALL/payload/sl_sidecar_manager.script','t',env))();sl_sidecar_manager=env
dofile('INSTALL/payload/grm_gore_test__original.script')
local b={object=npc};hit(b,1,actor,13);npc.dead=true;death(b,actor);now=now+50;update(b)
assert(sl_sidecar_manager.count()==1);sl_sidecar_manager.forget(7);assert(sl_sidecar_manager.count()==0)
print('PASS: gore hide result records scalar snapshot; forget removes it (Lua mocks only)')
