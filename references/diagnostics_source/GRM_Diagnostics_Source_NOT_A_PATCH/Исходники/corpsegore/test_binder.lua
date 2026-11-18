local function callback(path, env)
 local f=assert(io.open(path,'rb')); local s=f:read('*a');f:close()
 local a=assert(s:find('function motivator_binder:hit_callback',1,true));local b=assert(s:find('function motivator_binder:death_callback',a,true))
 assert(load(s:sub(a,b-1),path,'t',env))();return env.motivator_binder.hit_callback
end
local env=setmetatable({motivator_binder={}}, {__index=_G}); local n=0; local live=0;local events=0
local actor={};local npc={alive=function(self) return self.isalive end};local who=actor
local binder={object=npc, st={active_section='x',x={}}};local index=13
env.grm_gore_test={hit=function(self,amount,w,b) assert(self==binder and w==who and b==index);live=live+1 end,corpse_hit=function(self,w,b) assert(self==binder and w==who and b==index);n=n+1 end}
env.xr_logic={issue_event=function() events=events+1 end}
local hit=callback('/data/grm/corpsegore/package/GRM_Corpse/motivator.script',env)
npc.isalive=false;hit(binder,npc,0,{},who,index);assert(n==1 and live==0 and events==0)
npc.isalive=true;hit(binder,npc,0,{},who,index);assert(n==1 and live==1 and events==1)
print('PASS: corpse early return, living handler retained')
