printf=function() end
actor_binder={}; object_binder={}
local mode=0; local got=''; local calls={}
function object_binder.save(_,p) p:w_u8(42) end
function object_binder.load(_,p) assert(p:r_u8()==42) end
level={get_game_difficulty=function() return mode end}
local game_difficulty_by_num={[0]='gd_novice',[1]='gd_stalker',[2]='gd_veteran',[3]='gd_master'}
get_console=function() return {execute=function(_,s)got=s end} end
abort=function(s) error(s) end
utils={w_CTime=function(p,v) p:w_u32(v) end,r_CTime=function(p) return p:r_u32() end}
local function state()return {save_state=function()end,queue_load_state=function()end}end
shiza_hud_items=state();shiza_radiation=state();shiza_vodka=state();shiza_kill_stress=state();shiza_syringe=state()
shiza_skeleton_illusion={before_save=function()end};shiza_bar_light_flicker={before_save=function()end};grm_eyes_open={queue_load=function()end}
local function pair(k) return {save=function(p)p:w_u8(k)end,load=function(p)assert(p:r_u8()==k)end} end
xr_logic={pstor_save_all=function(_,p)p:w_u8(71)end,pstor_load_all=function(_,p)assert(p:r_u8()==71)end}
sr_psy_antenna=pair(73);treasure_manager=pair(74);task_manager=pair(75)
local f=assert(io.open('actor_functions.lua','rb'));local src=f:read('*a');f:close()
assert(load(src,'actor','t',setmetatable({game_difficulty_by_num=game_difficulty_by_num},{__index=_G})))()
local function packet()
 local p={data='',pos=1}
 function p:w_u8(x)self.data=self.data..string.pack('<I1',x)end
 function p:w_bool(x)self:w_u8(x and 1 or 0)end
 function p:w_u32(x)self.data=self.data..string.pack('<I4',x)end
 function p:w_tell()return #self.data end
 function p:r_u8()local a,n=string.unpack('<I1',self.data,self.pos);self.pos=n;return a end
 function p:r_u32()local a,n=string.unpack('<I4',self.data,self.pos);self.pos=n;return a end
 function p:r_eof() return self.pos>#self.data end
 return p
end
for difficulty=0,3 do for _,paused in ipairs({false,true}) do
 mode=difficulty;local w=pair(72);local d=pair(76)
 local from={object={name=function()return 'actor'end},st={disable_input_time=paused and 123456 or nil},weather_manager={save=function(_,p)w.save(p)end,load=function(_,p)w.load(p)end},actor_detector={save=function(_,p)d.save(p)end,load=function(_,p)d.load(p)end}}
 local to={object={name=function()return 'actor'end},st={},weather_manager=from.weather_manager,actor_detector=from.actor_detector}
 local p=packet(); actor_binder.save(from,p);p:w_u8(99);actor_binder.load(to,p); assert(p:r_u8()==99);assert(p:r_eof());assert(got=='g_game_difficulty '..game_difficulty_by_num[difficulty]);assert(to.st.disable_input_time==from.st.disable_input_time)
end end
print('PASS: actor save/load byte order, 4 difficulties, pause present/absent; mocks only')
