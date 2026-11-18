local logs=0
function printf(...) logs=logs+1 end
local root='SOURCE/TESTS/tmp/'
function getFS() return {update_path=function(self,alias,rel) assert(alias=='$game_saves$'); return root..rel:match('([^\\]+)$') end} end
local map='l01_escape';level={name=function()return map end}
dofile('INSTALL/payload/sl_sidecar_manager.script')
local function corpse(id) return {id=function()return id end,section=function()return 'stalker' end,name=function()return 'npc_'..id end} end
for i=1,200 do assert(mark_hidden(corpse(i))) end
assert(count()==200);assert(mark_hidden(corpse(1)) and count()==200)
forget(2); assert(count()==199)
local ok,n=save_gore_data('user_quicksave.sav');assert(ok and n==199)
reset();assert(count()==0);ok,n=load_gore_data('user_quicksave');assert(ok and n==199 and count()==199)
assert(not save_gore_data('../test'));assert(not save_gore_data('a/b'));assert(not save_gore_data('test.sav\n'))
local f=assert(io.open(root..'corrupt.txt','wb'));f:write('version=1\nlevel=4141\ncount=1\nobject_1=41|42|1\nend=1\nmalicious');f:close()
assert(not load_gore_data('corrupt') and count()==0)
assert(not load_gore_data('missing') and count()==0)
f=assert(io.open(root..'large.txt','wb'));f:write(string.rep('x',262145));f:close();assert(not load_gore_data('large') and count()==0)
map='new_level';assert(mark_hidden(corpse(3)));assert(count()==1)
local orig=io;io=nil;ok=save_gore_data('new');assert(not ok and logs==1);ok=save_gore_data('new');assert(not ok and logs==1);io=orig
print('PASS: 200 scalar records, dedupe, forget, disk round trip, corrupt/missing/oversized input, safe name, missing IO, level reset')
