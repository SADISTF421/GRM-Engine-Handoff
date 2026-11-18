local map='level1';local created=0
local actor={};db={actor=actor};level={name=function() return map end};function printf() end
function particles_object() created=created+1;return {playing=function() return false end,play_at_pos=function() end} end
dofile('/data/grm/cleanpatch/package/GRM_CleanDiag/gore1.script')
for i=1,100 do map='level'..i; assert(particle_at('grm_restore\\suicide_backup_head',{})) end
local held
for i=1,20 do local n,v=debug.getupvalue(particle_at,i);if not n then break end;if n=='held_particles' then held=v end end
assert(created==100 and held and #held==100)
for i=1,100 do assert(particle_at('grm_restore\\suicide_backup_head',{})) end
assert(created==100 and #held==100)
print('PASS: 100 level pool resets retain 100 references; reuse same level is bounded')
