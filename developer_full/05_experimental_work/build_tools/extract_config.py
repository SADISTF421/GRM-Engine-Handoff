import ctypes as c,sys,os
l=c.CDLL('libarchive.so.13');p=c.c_void_p
for n,rest,args in [('archive_read_new',p,[]),('archive_read_support_filter_all',c.c_int,[p]),('archive_read_support_format_all',c.c_int,[p]),('archive_read_open_filename',c.c_int,[p,c.c_char_p,c.c_size_t]),('archive_read_next_header',c.c_int,[p,c.POINTER(p)]),('archive_entry_pathname',c.c_char_p,[p]),('archive_read_data',c.c_ssize_t,[p,p,c.c_size_t]),('archive_read_free',c.c_int,[p])]:
 f=getattr(l,n);f.restype=rest;f.argtypes=args
need=('task_manager.ltx',)
for fn in sys.argv[1:]:
 a=l.archive_read_new();l.archive_read_support_filter_all(a);l.archive_read_support_format_all(a);l.archive_read_open_filename(a,fn.encode(),65536);e=p()
 while l.archive_read_next_header(a,c.byref(e))==0:
  n=l.archive_entry_pathname(e).decode(errors='replace')
  if not any(k in n.lower() for k in need):continue
  path='/data/grm/current2026/'+os.path.basename(fn)+'/'+n
  os.makedirs(os.path.dirname(path),exist_ok=True);buf=c.create_string_buffer(65536)
  with open(path,'wb') as f:
   while True:
    sz=l.archive_read_data(a,buf,len(buf))
    if sz<=0:break
    f.write(buf.raw[:sz])
 l.archive_read_free(a)
