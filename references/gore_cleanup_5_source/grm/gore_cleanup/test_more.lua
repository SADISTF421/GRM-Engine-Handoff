local now, map, weapon, captures, warns, playing = 0, 'cordon', 'wpn_toz34', 0, 0, false
function time_global() return now end
function printf(...) warns=warns+1 end
function vector() return {set=function(self,x,y,z) self.x=x;self.y=y;self.z=z;return self end} end
function device() return {cam_pos={x=0,y=0,z=0},cam_dir={x=0,y=0,z=1}} end
local actor={id=function()return 1 end,active_item=function()return {section=function()return weapon end}end,give_game_news=function() error('popup') end}
db={actor=actor}
local npc={dead=false,id=function()return 7 end,name=function()return 'npc' end, alive=function(s)return not s.dead end,position=function()return {x=0,y=0,z=5}end, bone_position=function(s,n) if n=='__grm_test_head_id__' then return {x=13} elseif n=='__grm_test_hide_head__' then captures=captures+1;return {x=1} else return {x=0,y=0,z=5} end end}
level={name=function()return map end,object_by_id=function()return npc end}
function system_ini() return {line_exist=function()return false end} end
sound_object=setmetatable({s3d=1},{__call=function()return {play_at_pos=function()end}end})
local weak=setmetatable({},{__mode='v'}); local created=0
function particles_object(effect) created=created+1; local x={playing=function()return playing end,play_at_pos=function()end};weak[created]=x; return x end
math.random=function(a,b) return 1 end
dofile('/data/grm/gore_cleanup/payload/50ms_corpse_transition.script')
local function fresh() npc.dead=false;now=now+1000;return {object=npc} end
local b=fresh();hit(b,1,actor,13);assert(b.grm_gore_test.head and b.grm_gore_test.npc==7);hit(b,1,actor,12);assert(not b.grm_gore_test.head);npc.dead=true;death(b,actor);assert(not b.grm_gore_test and not b.grm_gore_aim and not b.grm_gore_pending,'body must cancel head and fallback')
b=fresh();hit(b,1,actor,12);hit(b,1,actor,13);npc.dead=true;death(b,actor);assert(not b.grm_gore_test and b.grm_gore_pending,'last head');now=now+50;update(b);assert(captures==1 and b.grm_gore_anchored);now=now+5000;update(b);assert(b.grm_gore_blood==nil and b.grm_gore_anchored,'blood finishes but corpse flag remains')
b=fresh();hit(b,1,actor,13);now=now+301;update(b);assert(not b.grm_gore_test,'expiry')
local start=now;playing=true;assert(particle_at('grm_restore\\suicide_backup_head',{}));collectgarbage('collect');local before=created;now=start+20000;update(b);collectgarbage('collect');assert(weak[before]~=nil,'playing particle collected')
playing=false;now=now+2001;update(b);collectgarbage('collect');assert(weak[before]==nil,'completed particle not released')
assert(warns==0,'diagnostics leaked')
print('PASS last hit, expiry, state retention, effect completion, silent mode')
