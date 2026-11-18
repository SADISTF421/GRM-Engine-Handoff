local now, screenx, mode, choice, regs, messages = 100,0,'wpn_toz34',1,0,{}
function time_global() return now end
function Frect() return {set=function(self,...) return self end} end
function vector() return {set=function(self,x,y,z) self.x=x self.y=y self.z=z return self end} end
function device() return {cam_pos={x=0,y=0,z=0},cam_dir={x=0,y=0,z=1}} end
local actor={id=function() return 1 end,active_item=function() return {section=function() return mode end} end,give_game_news=function(self,s) messages[#messages+1]=s end}
db={actor=actor}
local npc={dead=false,id=function() return 5 end,name=function() return 'npc' end,alive=function(self) return not self.dead end,position=function() return {x=0,y=-1.7,z=10} end,bone_position=function(self,n) if n=='__grm_test_head_id__' then return {x=13} elseif n=='__grm_test_hide_head__' then regs=regs+1;return{x=1} elseif n=='bip01_head' then return{x=screenx,y=0,z=10} else return{x=0,y=0,z=10} end end}
level={name=function() return 'bar' end,object_by_id=function() return npc end}
function getFS() return {update_path=function() return 'bridge.dll' end} end
function grm_stress_loadlib() return function() return {install=function() return true end} end end
function system_ini() return {line_exist=function() return false end} end
sound_object=setmetatable({s3d=1},{__call=function() return {play_at_pos=function() end} end})
function particles_object() return {playing=function() return false end,play_at_pos=function() end} end
function printf() end
math.random=function(a,b) if b==100 then return choice end return 1 end
dofile('/data/grm/boneengine/grm_gore_test.script')
local function fresh() npc.dead=false; screenx=0;now=now+1000;return {object=npc} end
local function kill(b) npc.dead=true;death(b,actor);now=now+100;update(b) end
local b=fresh();update(b);assert(b.grm_gore_aim,'sample missing'); screenx=1;now=now+50;kill(b);assert(b.grm_gore_anchored,'prior aim ignored'); assert(string.find(table.concat(messages,' '),'PRE%-AIM'))
b=fresh();update(b);screenx=1;now=now+351;kill(b);assert(not b.grm_gore_anchored,'stale sample accepted')
b=fresh();update(b);screenx=1;now=now+120;update(b);assert(not b.grm_gore_aim,'off-target sample not cleared');kill(b);assert(not b.grm_gore_anchored)
b=fresh();update(b);screenx=1;mode='wpn_svd';now=now+20;kill(b);assert(not b.grm_gore_anchored,'wrong gun accepted')
mode='wpn_svu';b=fresh();update(b);screenx=1;now=now+20;kill(b);assert(b.grm_gore_anchored,'SVU sample ignored')
print('PASS: pre-shot aim, recoil displacement, expiration, changed aim and changed weapon guards')
