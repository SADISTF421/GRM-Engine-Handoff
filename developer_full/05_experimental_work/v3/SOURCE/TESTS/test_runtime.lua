local now, map, weapon, captures, logs = 0, 'cordon', 'wpn_toz34', 0, {}
function time_global() return now end
function printf(...) logs[#logs+1] = string.format(...) end
function vector() return {set=function(self,x,y,z) self.x=x;self.y=y;self.z=z;return self end} end
function device() return {cam_pos={x=0,y=0,z=0},cam_dir={x=0,y=0,z=1}} end
local actor={id=function()return 1 end,active_item=function()return {section=function()return weapon end}end,give_game_news=function() error('unexpected popup') end}
db={actor=actor}
local npc={dead=false,id=function()return 7 end,name=function()return 'npc' end, alive=function(s)return not s.dead end,position=function()return {x=0,y=0,z=5}end, bone_position=function(s,n) if n=='__grm_test_head_id__' then return {x=13} elseif n=='__grm_test_hide_head__' then captures=captures+1;return {x=1} else return {x=0,y=0,z=5} end end}
level={name=function()return map end,object_by_id=function()return npc end}
function system_ini() return {line_exist=function()return false end} end
sound_object=setmetatable({s3d=1},{__call=function()return {play_at_pos=function()end}end})
local created, weak, playing = 0, setmetatable({},{__mode='v'}), false
function particles_object(effect) created=created+1; local x={playing=function()return playing end,play_at_pos=function()end};weak[created]=x;return x end
math.random=function() return 1 end
dofile('INSTALL/payload/grm_gore_test.script')
local b={object=npc}; hit(b,1,actor,13);assert(b.grm_gore_test.head);hit(b,1,actor,12); assert(not b.grm_gore_test.head and not b.grm_gore_aim);npc.dead=true;death(b,actor);assert(not b.grm_gore_pending and not b.grm_gore_test)
npc.dead=false; hit(b,1,actor,13);npc.dead=true;death(b,actor); assert(b.grm_gore_pending and not b.grm_gore_test); now=50;update(b);assert(captures==1 and b.grm_gore_anchored and b.grm_gore_blood);now=5050;update(b);assert(not b.grm_gore_blood and b.grm_gore_anchored)
assert(#logs==1 and logs[1]=='[GRM_GORE] runtime started')
reset_binder(b); for _,k in ipairs({'grm_gore_aim','grm_gore_pending','grm_gore_test','grm_gore_blood','grm_gore_anchored'}) do assert(b[k]==nil) end
-- Separate mock level, all allocated effects remain playing, no active wrapper is reclaimed for the cap.
map='garbage';playing=true
for i=1,16 do assert(particle_at('hit_fx\\group_items\\hit_blood_puff_head',{},true)) end
local cap_created=created; assert(not particle_at('hit_fx\\group_items\\hit_blood_puff_head',{},true));assert(created==cap_created)
-- Other systems use the shared pool and remain independent from the gore quota.
assert(particle_at('hit_fx\\group_items\\hit_blood_puff_head',{}));assert(created==cap_created+1)
collectgarbage('collect');for i=cap_created-15,cap_created do assert(weak[i], 'active wrapper collected') end
playing=false; now=30000; npc.dead=false; update(b)
for i=1,20 do
 npc.dead=false; b={object=npc}; now=now+100; hit(b,1,actor,13); npc.dead=true; death(b,actor)
 assert(b.grm_gore_pending); now=now+50; update(b); assert(b.grm_gore_anchored)
 now=now+5000; update(b); assert(not b.grm_gore_blood); reset_binder(b); assert(not b.grm_gore_test and not b.grm_gore_anchored)
end
assert(#logs==1)
print('PASS: head/body ordering, startup log, mock blood timer, reset, 16 owned wrappers, separate shared pool, retained mock playing wrappers, 20 mock deaths')
