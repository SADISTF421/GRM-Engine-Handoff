import ctypes as c,hashlib
p=c.c_void_p;l=c.CDLL('libarchive.so.13')
for n,rt,args in [('archive_read_new',p,[]),('archive_read_support_filter_all',c.c_int,[p]),('archive_read_support_format_all',c.c_int,[p]),('archive_read_open_filename',c.c_int,[p,c.c_char_p,c.c_size_t]),('archive_read_next_header',c.c_int,[p,c.POINTER(p)]),('archive_entry_pathname',c.c_char_p,[p]),('archive_read_data',c.c_ssize_t,[p,p,c.c_size_t]),('archive_read_free',c.c_int,[p]),('archive_error_string',c.c_char_p,[p])]:
 f=getattr(l,n);f.restype=rt;f.argtypes=args
a=l.archive_read_new();l.archive_read_support_filter_all(a);l.archive_read_support_format_all(a);fn=b'/data/.agent-service/files/971652cf-8c98-49c5-82ef-058d30e71e79/scripts.rar';print('open',l.archive_read_open_filename(a,fn,65536));e=p();count=0
need={'sl_sidecar_manager.script','grm_gore_test.script','bind_stalker.script','shiza_reznya.script','sl_rotting.script','xr_motivator.script'}
while True:
 r=l.archive_read_next_header(a,c.byref(e))
 if r!=0:
  if r!=1:print('end/error',r,l.archive_error_string(a))
  break
 name=l.archive_entry_pathname(e).decode(errors='replace').replace('\\','/'); count+=1
 if name.split('/')[-1].lower() in need:
  d=[];buf=c.create_string_buffer(65536)
  while True:
   n=l.archive_read_data(a,buf,len(buf))
   if n<0:print('READ ERROR',name,l.archive_error_string(a));break
   if n==0:break
   d.append(buf.raw[:n])
  data=b''.join(d);print(name,len(data),hashlib.sha256(data).hexdigest())
print('entries',count);l.archive_read_free(a)
