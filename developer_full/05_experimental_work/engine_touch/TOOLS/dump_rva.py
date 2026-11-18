#!/usr/bin/env python3
"""Read MINIDUMP ModuleListStream, report module base and crash RVA, no changes."""
import argparse, struct, uuid, os

def read_modules(data):
    def take(off, length):
        if off < 0 or length < 0 or off > len(data) or length > len(data) - off:
            raise ValueError('усечённый или некорректный minidump')
        return data[off:off + length]
    def unpack(fmt, off):
        return struct.unpack(fmt, take(off, struct.calcsize(fmt)))
    sig, ver, count, directory = unpack('<IIII', 0)
    if sig != 0x504d444d: raise ValueError('это не minidump MDMP')
    if count > 100000: raise ValueError('слишком много потоков')
    take(directory, count*12)
    modules=[]
    for i in range(count):
        typ, size, rva = unpack('<III', directory+i*12)
        if typ != 4: continue
        stream=take(rva,size)
        if len(stream)<4: raise ValueError('усечённый ModuleListStream')
        n=struct.unpack_from('<I',stream)[0]
        if n > (len(stream)-4)//108: raise ValueError('усечённая таблица модулей')
        for j in range(n):
            off=rva+4+j*108
            base, sz, checksum, stamp, name_rva=unpack('<QIIII',off)
            namelen,=unpack('<I',name_rva)
            if namelen > 32768 or namelen%2: raise ValueError('некорректное имя модуля')
            name=take(name_rva+4,namelen).decode('utf-16le',errors='strict')
            cvsize,cvrva=unpack('<II',off+76)
            ident='нет RSDS'
            if cvsize:
                cv=take(cvrva,cvsize)
                if len(cv)>=24 and cv[:4]==b'RSDS':
                    ident='GUID %s age %d PDB %s' % (uuid.UUID(bytes_le=bytes(cv[4:20])),struct.unpack_from('<I',cv,20)[0],cv[24:].split(b'\0')[0].decode('ascii',errors='replace'))
            modules.append((name,base,sz,ident))
    return modules

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('dump');p.add_argument('address',help='адрес, например 0x05FBDCFB')
    a=p.parse_args(); addr=int(a.address,0)
    with open(a.dump,'rb') as f: data=f.read()
    modules=read_modules(data)
    matches=[m for m in modules if m[1] <= addr < m[1]+m[2]]
    if not matches:
        print('Адрес не попал в модули из дампа; RVA не определён.')
        return 2
    for name,base,size,ident in matches:
        print('%s\nbase=0x%X size=0x%X address=0x%X RVA=0x%X\n%s' % (name,base,size,addr,addr-base,ident))
    print('RVA — не имя функции: для символов нужен точно совпадающий PDB (GUID и age).')
    return 0
if __name__=='__main__':
    try: raise SystemExit(main())
    except (ValueError, OSError, UnicodeError) as e:
        print('Ошибка:', e); raise SystemExit(1)
