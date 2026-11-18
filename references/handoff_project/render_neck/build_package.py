from pathlib import Path
import hashlib, struct, zipfile, sys
sys.path.insert(0,'/data/grm/pylibs')
import pefile
r=Path('/data/grm/render_neck'); pkg=r/'package';(pkg/'GRM_RenderNeck').mkdir(parents=True,exist_ok=True)
sha=lambda x:hashlib.sha256(x).hexdigest()
old=Path('/data/grm/newbin_last/bin/XR_3DA.exe').read_bytes();p=pefile.PE(data=old)
assert sha(old)=='5d52602915fbcbc25798b617a89303117edebb36fefef894ed0abd36e7cd634b'
assert p.FILE_HEADER.NumberOfSections==5 and p.OPTIONAL_HEADER.ImageBase==0x400000 and p.OPTIONAL_HEADER.SizeOfImage==0x16d000 and len(old)==0x166600
stub=(r/'stub.bin').read_bytes();assert len(stub)<0x200
b=bytearray(old);struct.pack_into('<H',b,p.FILE_HEADER.get_file_offset()+2,6)
o=p.OPTIONAL_HEADER.get_file_offset(); struct.pack_into('<I',b,o+4,p.OPTIONAL_HEADER.SizeOfCode+0x200);struct.pack_into('<I',b,o+56,0x16e000);struct.pack_into('<I',b,o+64,0)
h=p.sections[-1].get_file_offset()+40;assert not any(b[h:h+40]);b[h:h+40]=struct.pack('<8sIIIIIIHHI',b'.grmnck\0',len(stub),0x16d000,0x200,0x166600,0,0,0,0,0x60000020)
for va,off,axis in [(0x467514,0x66914,0),(0x4675ce,0x669ce,1),(0x467688,0x66a88,2)]:
 assert b[off:off+5]==bytes.fromhex(['f30f105a30','f30f105a34','f30f105a38'][axis]);target=0x56d000+4*axis;b[off:off+5]=b'\xe8'+struct.pack('<i',target-(va+5))
b+=stub+bytes(0x200-len(stub));q=pefile.PE(data=b);assert q.FILE_HEADER.NumberOfSections==6 and q.sections[-1].get_data()[:len(stub)]==stub
allowed=set(range(h,h+40))|set(range(p.FILE_HEADER.get_file_offset()+2,p.FILE_HEADER.get_file_offset()+4))|set(range(o+4,o+8))|set(range(o+56,o+60))|set(range(o+64,o+68))|set(range(0x66914,0x66919))|set(range(0x669ce,0x669d3))|set(range(0x66a88,0x66a8d))
assert all(i in allowed for i,(a,c) in enumerate(zip(old,b)) if a!=c)
newhash=sha(b);(pkg/'GRM_RenderNeck'/'XR_3DA.patched').write_bytes(b)
source=(r/'stub.s').read_text(); source='\n'.join(line.split('#')[0].rstrip() for line in source.splitlines())+'\n';(pkg/'GRM_RenderNeck'/'render_neck.s').write_text(source)
inputs=['/data/grm/chance75/package/GRM_Chance75/grm_gore_test.script','/data/grm/fasthead/grm_gore_fast.script','/data/grm/cleanpatch/package/GRM_CleanDiag/gore0.script','/data/grm/cleanpatch/package/GRM_CleanDiag/gore1.script','/data/grm/corpsegore/package/GRM_Corpse/gore0.script','/data/grm/corpsegore/package/GRM_Corpse/gore1.script']
inputs += [str(x) for x in Path('/data/grm/particle_transition_fix/package/GRM_ParticleTransition').glob('*.script')]
scripts=[sha(Path(x).read_bytes()) for x in inputs];assert len(scripts)==12
ps=r'''$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Split-Path -Parent $MyInvocation.MyCommand.Path))
function Hash([string]$p) { return (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLowerInvariant() }
$tmp=$null; $bak=$null; $replaced=$false
try {
 [Console]::OutputEncoding=New-Object System.Text.UTF8Encoding
 if (@(Get-Process | Where-Object { $_.ProcessName -like 'XR_3DA*' }).Count -gt 0) { throw 'Закройте игру.' }
 $exe=Join-Path $root 'bin\XR_3DA.exe'; $dll=Join-Path $root 'bin\xrGame.dll'; $script=Join-Path $root 'gamedata\scripts\grm_gore_test.script'; $payload=Join-Path $root 'GRM_RenderNeck\XR_3DA.patched'
 foreach ($f in @($exe,$dll,$script,$payload)) { if (!(Test-Path -LiteralPath $f -PathType Leaf)) { throw ('Нет файла: '+$f) } }
 $dh=Hash $dll
 if (@(DLLHASHES) -notcontains $dh) { throw ('Другая версия xrGame.dll. Изменений нет. SHA256: '+$dh) }
 $sh=Hash $script
 if (@(SCRIPTHASHES) -notcontains $sh) { throw ('Другая версия grm_gore_test.script. Изменений нет. SHA256: '+$sh) }
 $eh=Hash $exe
 if ($eh -eq 'NEWHASH') { Write-Host 'Патч уже установлен.'; exit 0 }
 if ($eh -ne 'OLDHASH') { throw ('Другая версия XR_3DA.exe. Изменений нет. SHA256: '+$eh) }
 if ((Hash $payload) -ne 'NEWHASH') { throw 'Файл патча повреждён. Изменений нет.' }
 $dir=Split-Path -Parent $exe; $tmp=Join-Path $dir ([IO.Path]::GetRandomFileName()+'.tmp'); $bak=Join-Path $dir ([IO.Path]::GetRandomFileName()+'.bak')
 [IO.File]::Copy($payload,$tmp); if ((Hash $tmp) -ne 'NEWHASH') { throw 'Ошибка проверки записи.' }
 [IO.File]::Replace($tmp,$exe,$bak); $replaced=$true
 if ((Hash $exe) -ne 'NEWHASH') { throw 'Ошибка проверки установленного файла.' }
 Remove-Item -LiteralPath $bak -Force -ErrorAction SilentlyContinue; $bak=$null
 Write-Host 'Экспериментальная правка рендера установлена.'
} catch {
 if ($replaced -and $bak -and (Test-Path -LiteralPath $bak)) { try { $discard=Join-Path (Split-Path -Parent $exe) ([IO.Path]::GetRandomFileName()+'.tmp'); [IO.File]::Replace($bak,$exe,$discard); Remove-Item -LiteralPath $discard -Force -ErrorAction SilentlyContinue; $bak=$null } catch { Write-Host ('Исходный файл сохранён: '+$bak) } }
 Write-Host ('ОШИБКА: '+$_.Exception.Message); exit 1
} finally { if ($tmp -and (Test-Path -LiteralPath $tmp)) { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue } }
'''
dlls=['c5f1968e680b1bef8d000a0a2d37adf343026628994fffcb138fea1c3130e9fb','4a6e84f3397b853124158865bd71b54f9c438d11384bad6a90eaa08c20216959','969d116337e15a0f5c0af212c8c49ea5262bba3b2d93e4ca7af7ff140e2856d7','f59cdeeeb652adcb8f76ec621a32e72552f2037db457e7f3ea3e19633f702fbd','258e6be1b4db929bc915088f485379ec6db86a525690f3ff227da2a091291742','b60bfe6f03a1f085dd7d5bcb1b8771668b24e60ed44d8d2394aa339e78125225','dd08eeaa462788fd6b00481a987a33c848c9d417f4b4d67781219ebeadcedd71','bf347977fde7ce70d310181c1fc18df78e6d539b5092b218758b1bd7c4cb2e90']
ps=ps.replace('OLDHASH',sha(old)).replace('NEWHASH',newhash).replace('DLLHASHES',','.join("'"+v+"'" for v in dlls)).replace('SCRIPTHASHES',','.join("'"+v+"'" for v in scripts))
(pkg/'GRM_RenderNeck.ps1').write_text(ps,encoding='utf-8-sig',newline='\r\n')
(pkg/'INSTALL_GRM_RenderNeck.bat').write_bytes(b'@echo off\r\nchcp 65001 >nul\r\npowershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0GRM_RenderNeck.ps1"\r\npause\r\n')
(pkg/'ПРОЧТИ.txt').write_text('''ЭКСПЕРИМЕНТАЛЬНАЯ ПРАВКА РЕНДЕРА ГОЛОВЫ\n\nЗакройте игру. Сделайте полный бэкап игры и сохранений. Распакуйте архив в папку игры, запустите INSTALL_GRM_RenderNeck.bat. Проверяются точные версии EXE, xrGame.dll и скрипта. Не запускайте игру, пока работает установщик.\n\nМеняется только bin\\XR_3DA.exe: на путях аппаратного скиннинга 1B/2B точка схлопывания скрытой головы и её скрытых дочерних костей при выдаче матриц GPU смещается к живой кости-родителю. Физика и сохранение не меняются этой правкой. Это не исправляет причины всех вылетов и может не работать с другими путями отрисовки или всеми моделями. Прежний экспериментальный GPU-плагин включать нельзя. Скрипты, эффекты и модели не заменяются.\n\nПосле установки старые установщики, проверяющие исходный EXE, могут отказаться работать. Если нужна правка Particle Transition или отключение GRM_SAVE_DIAG, устанавливайте их до этой правки.\n\nНа копии старого ручного сохранения проверьте головы нескольких моделей, сохранение, загрузку и переходы. jump_to_level перезаписывает user_autosave.sav. В игре теста не было; стабильность и устранение растяжения не гарантированы.\n''',encoding='utf-8-sig')
with zipfile.ZipFile('/data/GRM_Render_Neck_Experimental_TEST.zip','w',zipfile.ZIP_DEFLATED) as z:
 for f in pkg.rglob('*'):
  if f.is_file(): z.write(f,f.relative_to(pkg))
with zipfile.ZipFile('/data/GRM_Render_Neck_Experimental_TEST.zip') as z: assert z.testzip() is None
print('patched sha256',newhash,'script versions',len(scripts))
