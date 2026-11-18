local actions,callbacks,mode,lookup,forgets={}, {},'valid',0,0
function vector()return{set=function(self) return self end}end
function time_global()return 0 end
function device()return{time_global=function()return 1 end}end
math.randomseed=function()end;math.random=function()return 1 end
local actor={id=function()return 1 end,active_slot=function()return 4 end,activate_slot=function()end,object=function()return nil end,level_vertex_id=function()return 1 end,game_vertex_id=function()return 1 end,position=function()return {} end,set_actor_position=function()end,hide_weapon=function()end,restore_weapon=function() actions.restore=true end}
db={actor=actor};sound_object={s2d=1};xr_sound={get_safe_sound_object=function()return{play_at_pos=function()end}end}
level={disable_input=function()actions.disabled=true end,enable_input=function()actions.enabled=true end,add_pp_effector=function()end,add_cam_effector=function()end,add_call=function(a,b)table.insert(callbacks,b)end,object_by_id=function(id)lookup=lookup+1;return client end}
sl_rotting={begin_harvest=function()end,forget=function()end};grm_gore_test={forget=function(id)assert(id==7);forgets=forgets+1 end}
local server={online=true,name=function()return mode=='reused' and 'other' or 'npc7' end,section_name=function()return 'stalker' end}
function alife()return {object=function(self,id) if mode=='removed' then return nil end;server.online=(mode~='offline');return server end,create=function(self,section)actions[section]=(actions[section] or 0)+1;return {} end,release=function(self,o) actions.released=(actions.released or 0)+1 end}end
client={id=function()return 7 end,name=function()return 'npc7' end,section=function()return 'stalker' end,alive=function()return false end,position=function()return{} end,level_vertex_id=function()return 1 end,game_vertex_id=function()return 1 end,iterate_inventory=function()end}
dofile((os.getenv('GRM_SCRIPT_DIR') or 'INSTALL/gamedata/scripts/') .. 'shiza_reznya.script')
for _,m in ipairs({'removed','offline','reused','valid'})do
 mode=m;actions={};callbacks={};lookup=0; piter_moment(client); assert(actions.disabled and #callbacks==2);callbacks[2]();assert(actions.enabled and actions.restore)
 if m=='valid' then assert(lookup==1 and actions.released==1 and actions.reznya_trup_base==1) else assert(lookup==0 and not actions.released and not actions.reznya_trup_base) end
end
assert(forgets==5)
print('PASS: harvest target deleted/offline/reused cancels safely on mocks; valid corpse released once')
