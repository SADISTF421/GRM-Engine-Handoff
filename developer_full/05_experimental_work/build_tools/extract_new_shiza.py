import ctypes as c,os
l=c.CDLL('libarchive.so.13');p=c.c_void_p
for n,r,a in [('archive_read_new',p,[]),('archive_read_support_filter_all',c.c_int,[p]),('archive_read_support_format_all',c.c_int,[p]),('archive_read_open_filename',c.c_int,[p,c.c_char_p,c.c_size_t]),('archive_read_next_header',c.c_int,[p,c.POINTER(p)]),('archive_entry_pathname',c.c_char_p,[p]),('archive_read_data',c.c_ssize_t,[p,p,c.c_size_t]),('archive_error_string',c.c_char_p,[p]),('archive_read_free',c.c_int,[p])]:f=getattr(l,n);f.restype=r;f.argtypes=a
fn='/data/.agent-service/files/a12ba17e-028a-47d0-84af-2da6085672eb/shizamod_engine-main.rar'; a=l.archive_read_new();l.archive_read_support_filter_all(a);l.archive_read_support_format_all(a);assert l.archive_read_open_filename(a,fn.encode(),65536)==0;e=p(); found=[]
need={'README.md','trunk/xrNetServer/NET_utils.h','trunk/xr_3da/xrGame/alife_object_registry.cpp','trunk/xr_3da/xrGame/alife_storage_manager.cpp','trunk/xr_3da/xrGame/Level_network.cpp','trunk/xr_3da/xrGame/xrGame.vcproj','trunk/xr_3da/XR_3DA.sln'}
while True:
 st=l.archive_read_next_header(a,c.byref(e))
 if st==1:break
 if st!=0:raise RuntimeError(str(l.archive_error_string(a)))
 n=l.archive_entry_pathname(e).decode(errors='replace')
 if n not in need:continue
 path='/data/grm/new_shiza/'+n; os.makedirs(os.path.dirname(path),exist_ok=True);buf=c.create_string_buffer(65536)
 with open(path,'wb') as f:
  while True:
   sz=l.archive_read_data(a,buf,len(buf))
   if sz<0: raise RuntimeError(str(l.archive_error_string(a)))
   if not sz:break
   f.write(buf.raw[:sz])
 found.append(n)
l.archive_read_free(a);print('Extracted',len(found),*found,sep='\n')
