local map='level0'; local created,freed=0,0
local actor={}; db={actor=actor}; level={name=function() return map end}; function printf() end
function particles_object() created=created+1; return setmetatable({playing=function() return false end,play_at_pos=function() end},{__gc=function() freed=freed+1 end}) end
dofile('/data/grm/particle_transition_fix/package/GRM_ParticleTransition/100ms_quiet.script')
local function heldcount() for i=1,30 do local n,v=debug.getupvalue(particle_at,i); if n=='held_particles' then return #v end end; error('no held') end
for i=1,100 do map='level'..i; assert(particle_at('grm_restore\\suicide_backup_head',{})); assert(heldcount()==1) end
collectgarbage('collect'); assert(created==100 and freed==99,created..' '..freed)
for i=1,100 do assert(particle_at('grm_restore\\suicide_backup_head',{})) end
assert(created==100 and heldcount()==1)
db.actor={}; assert(particle_at('grm_restore\\suicide_backup_head',{})); collectgarbage('collect'); assert(created==101 and freed==100 and heldcount()==1)
print('PASS map reset, reuse and actor reset')
