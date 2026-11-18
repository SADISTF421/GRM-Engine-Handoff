import ctypes as c,sys
from pathlib import Path
l=c.CDLL('liblua-5.3.so');P=c.c_void_p
for n,rt,args in [('luaL_newstate',P,[]),('luaL_openlibs',None,[P]),('luaL_loadbufferx',c.c_int,[P,c.c_char_p,c.c_size_t,c.c_char_p,c.c_char_p]),('lua_pcallk',c.c_int,[P,c.c_int,c.c_int,c.c_int,c.c_longlong,P]),('lua_tolstring',c.c_char_p,[P,c.c_int,P])]:
 f=getattr(l,n);f.restype=rt;f.argtypes=args
L=l.luaL_newstate();l.luaL_openlibs(L)
for name in sys.argv[1:]:
 b=Path(name).read_bytes();r=l.luaL_loadbufferx(L,b,len(b),name.encode(),None)
 if r: raise Exception(l.lua_tolstring(L,-1,None))
 if name.endswith('.lua'):
  r=l.lua_pcallk(L,0,0,0,0,None)
  if r:raise Exception(l.lua_tolstring(L,-1,None))
print('Syntax checked')
