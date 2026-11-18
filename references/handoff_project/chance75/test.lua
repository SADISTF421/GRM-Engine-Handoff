local now, choice, weapon, hides = 100, 75, 'wpn_toz34', 0
function time_global() return now end
function Frect() return {set=function(self,...) return self end} end
function vector() return {set=function(self,x,y,z) self.x=x self.y=y self.z=z return self end} end
function device() return {cam_pos={x=0,y=0,z=0},cam_dir={x=0,y=0,z=1}} end
local actor={id=function() return 1 end,active_item=function() return {section=function() return weapon end} end,give_game_news=function() end}
db={actor=actor}
local npc={dead=false,id=function() return 5 end,name=function() return 'npc' end,alive=function(self) return not self.dead end,position=function() return {x=0,y=-1.7,z=10} end,
 bone_position=function(self,name) if name=='__grm_test_head_id__' then return {x=13} elseif name=='__grm_test_hide_head__' then hides=hides+1;return {x=1} else return {x=0,y=0,z=10} end end}
level={name=function() return 'bar' end,object_by_id=function() return npc end}
function system_ini() return {line_exist=function() return false end} end
function printf() end
sound_object=setmetatable({s3d=1},{__call=function() return {play_at_pos=function() end} end})
function particles_object() return {playing=function() return false end,play_at_pos=function() end} end
math.random=function(a,b) if b==100 then return choice end return 1 end
dofile('/data/grm/chance75/package/GRM_Chance75/grm_gore_test.script')
local function kill()
 npc.dead=false;now=now+1000;local b={object=npc};hit(b,1,actor,13);npc.dead=true;death(b,actor);now=now+100;update(b)
end
kill();assert(hides==1,'ТОЗ при 75')
weapon='wpn_svd';kill();assert(hides==2,'СВД при 75')
weapon='wpn_svu';kill();assert(hides==3,'СВУ при 75')
choice=76;kill();assert(hides==3,'должен быть пропуск при 76')
print('PASS: ТОЗ, СВД, СВУ, пороги 75/76')
