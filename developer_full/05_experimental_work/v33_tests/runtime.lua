local root='/data/grm/v33/gamedata/scripts/'
local calls=0;function printf()end
function time_global()return now end
local lv='cordon';level={name=function()return lv end,object_by_id=function(id) calls=calls+1;return npc end}
function vector()return{set=function(self)return self end}end
function device()return{cam_pos={x=0,y=0,z=0},cam_dir={x=0,y=0,z=1}}end
local weapon='wpn_svd'; local actor={id=function()return 1 end,active_item=function()return{section=function()return weapon end}end};db={actor=actor}
npc={dead=false,id=function()return 7 end,name=function()return 'npc7' end,section=function()return 'stalker' end,alive=function(s)return not s.dead end,position=function()return{x=0,y=0,z=5}end,bone_position=function(s,n)if n=='__grm_test_head_id__' then return {x=13} elseif n=='__grm_test_hide_head__' then return{x=1} else return{x=0,y=0,z=5} end end}
function system_ini()return{line_exist=function()return false end}end
function particles_object()return{playing=function()return false end,play_at_pos=function()end}end
sound_object=setmetatable({s3d=1},{__call=function()return{play_at_pos=function()end}end});math.random=function()return 1 end
local present,online,identity=true,true,true
local server={online=true,name=function()return identity and 'npc7' or 'other' end,section_name=function()return 'stalker' end}
function alife() return {object=function(self,id)if not present then return nil end;server.online=online;return server end} end
local marks=0;sl_sidecar_manager={mark_hidden=function(o)marks=marks+1 end,forget=function()end}
dofile(root..'grm_gore_test.script')
local function attempt()
 now=now+1000;npc.dead=false;local b={object=npc};hit(b,1,actor,13);npc.dead=true;death(b,actor);now=now+50;update(b)
end
now=0;present=false;attempt();assert(calls==0 and marks==0)
present=true;online=false;attempt();assert(calls==0 and marks==0)
online=true;identity=false;attempt();assert(calls==0 and marks==0)
identity=true;attempt();assert(calls==1 and marks==1)
print('PASS: deleted/offline/reused NPC not looked up as client, online matching NPC still executes hide on mocks')

local old=npc.bone_position; local bone_calls=0
npc.bone_position=function(...) bone_calls=bone_calls+1;return old(...) end
weapon='wpn_knife';local b={object=npc,grm_gore_test={head=true},grm_gore_aim={}}
npc.dead=false;hit(b,1,actor,13);npc.dead=true;death(b,actor)
assert(bone_calls==0 and not b.grm_gore_pending and not b.grm_gore_test)
local blood,anchor={},{}; b.grm_gore_blood=blood;b.grm_gore_anchored=anchor;b.grm_gore_pending={};b.grm_gore_test={};b.grm_gore_aim={}
prepare_harvest(b);assert(not b.grm_gore_pending and not b.grm_gore_test and not b.grm_gore_aim); assert(b.grm_gore_blood==blood and b.grm_gore_anchored==anchor)
weapon='wpn_toz34';npc.dead=false;hit(b,1,actor,13);assert(b.grm_gore_test and b.grm_gore_test.kind=='shotgun')
print('PASS: knife avoids gore bone query, pending reset preserves blood/anchor, TOZ hit retained')
