local now, choice, weapon, hides, blood, meat, noise, map = 100, 75, 'wpn_toz34', 0, 0, 0, 0, 'bar'
function time_global() return now end
function Frect() return {set=function(self,...) return self end} end
function vector() return {set=function(self,x,y,z) self.x=x self.y=y self.z=z return self end} end
function device() return {cam_pos={x=0,y=0,z=0},cam_dir={x=0,y=0,z=1}} end
local actor={id=function() return 1 end,active_item=function() return {section=function() return weapon end} end,give_game_news=function() end}
db={actor=actor}
local npc={dead=false,id=function() return 5 end,name=function() return 'npc' end,alive=function(self) return not self.dead end,position=function() return {x=0,y=-1.7,z=10} end,
 bone_position=function(self,name) if name=='__grm_test_head_id__' then return {x=13} elseif name=='__grm_test_hide_head__' then hides=hides+1;return {x=1} else return {x=0,y=0,z=10} end end}
level={name=function() return map end,object_by_id=function() return npc end}
function system_ini() return {line_exist=function() return false end} end
function printf() end
sound_object=setmetatable({s3d=1},{__call=function() return {play_at_pos=function() noise=noise+1 end} end})
function particles_object(effect) return {playing=function() return false end,play_at_pos=function() if effect=='grm_restore\\suicide_backup_head' then meat=meat+1 else blood=blood+1 end end} end
math.random=function(a,b) if b==100 then return choice end return 1 end
dofile('/data/grm/fasthead/grm_gore_fast.script')
local function start()
 now=now+1000; npc.dead=false;local b={object=npc};hit(b,1,actor,13);npc.dead=true;death(b,actor);return b
end
for i,w in ipairs({'wpn_toz34','wpn_svd','wpn_svu'}) do
 weapon=w;local b=start();local before=hides;now=now+49;update(b);assert(hides==before,'early');now=now+1;update(b);assert(hides==before+1,'hide');assert(meat==i and noise==i,'effects');now=now+5000;update(b);assert(blood==10*i,'blood chain')
end
choice=76;local b=start();local before=hides;now=now+100;update(b);assert(hides==before,'chance skip')
choice=75;b=start();map='escape';now=now+100;update(b);assert(hides==before,'level change')
print('PASS: 49/50ms, TOZ/SVD/SVU, chance, effects, 5s blood, map guard')
