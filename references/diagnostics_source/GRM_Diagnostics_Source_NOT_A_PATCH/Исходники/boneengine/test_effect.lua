local now, fxcount, hide, sounds, choice, map = 100, 0, 0, 0, 1, 'bar'
function time_global() return now end
function Frect() return {set=function(self,...) return self end} end
function vector() return {set=function(self,x,y,z) self.x=x self.y=y self.z=z return self end} end
function device() return {cam_pos={x=0,y=0,z=0},cam_dir={x=0,y=0,z=1}} end
local actor={id=function() return 1 end,active_item=function() return {section=function() return 'wpn_toz34' end} end,give_game_news=function() end}
db={actor=actor}
local npc={dead=false,id=function() return 5 end,name=function() return 'npc' end,alive=function(self) return not self.dead end,position=function() return {x=0,y=-1.7,z=10} end,
 bone_position=function(self,name) if name=='__grm_test_head_id__' then return {x=13} elseif name=='__grm_test_hide_head__' then hide=hide+1;return {x=1} else return {x=0,y=0,z=10} end end}
level={name=function() return map end,object_by_id=function() return npc end}
function system_ini() return {line_exist=function() return false end} end
function printf() end
function grm_stress_loadlib() error('legacy plugin must not be loaded') end
sound_object=setmetatable({s3d=1},{__call=function() return {play_at_pos=function() sounds=sounds+1 end} end})
function particles_object() return {playing=function() return false end,play_at_pos=function() fxcount=fxcount+1 end} end
math.random=function(a,b) if b==100 then return choice end return 1 end
dofile('/data/grm/boneengine/grm_gore_test.script')
local b={object=npc};hit(b,1,actor,13);npc.dead=true;death(b,actor);now=200;update(b)
assert(hide==1 and sounds==1 and fxcount==1)
for i=1,10 do now=200+i*500;update(b) end
assert(hide==1 and fxcount==11 and not b.grm_gore_blood)
npc.dead=false;now=6000;update(b);choice=99;hit(b,1,actor,13);npc.dead=true;death(b,actor);now=6200;update(b)
assert(hide==1 and fxcount==11)
print('PASS: one hide, blood 5s, whole-effect chance, legacy bridge not loaded')
