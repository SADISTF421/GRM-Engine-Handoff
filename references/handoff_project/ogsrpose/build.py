import sys, hashlib,struct,os,zipfile
sys.path.insert(0,'/data/grm/pylibs')
import pefile
P='/data/grm/ogsrpose/'
old=open('/data/grm/newbin_last/bin/xrGame.dll','rb').read()
assert hashlib.sha256(old).hexdigest()=='c5f1968e680b1bef8d000a0a2d37adf343026628994fffcb138fea1c3130e9fb'
p=pefile.PE(data=old); assert p.OPTIONAL_HEADER.ImageBase==0x10000000
s=p.sections[-1]; assert (s.VirtualAddress,s.Misc_VirtualSize,s.PointerToRawData,s.SizeOfRawData)==(0x61f000,0x670,0x603400,0x800)
assert len(old)==0x603c00
blob=open(P+'hook.bin','rb').read(); assert len(blob)==299
b=bytearray(old)+bytearray(0x400)
struct.pack_into('<I',b,s.get_file_offset()+8,0x800+len(blob))
struct.pack_into('<I',b,s.get_file_offset()+16,0xc00)
b[0x603c00:0x603c00+len(blob)]=blob
assert struct.unpack_from('<H',b,0x5839e0)[0]==0x32bf
struct.pack_into('<H',b,0x5839e0,0x02bf)
def patch(va,expected,dest):
    off=p.get_offset_from_rva(va-0x10000000)
    expected=bytes.fromhex(expected)
    assert b[off:off+len(expected)]==expected, (hex(va),b[off:off+len(expected)].hex())
    b[off:off+len(expected)]=b'\xe9'+struct.pack('<i',dest-(va+5))+b'\x90'*(len(expected)-5)
patch(0x101f22b3,'8b57148b471052508bcbff158c674610',0x1061f800)
patch(0x101f22da,'8b7c240c8b8fa4010000',0x1061f841)
new=bytes(b); h=hashlib.sha256(new).hexdigest(); print('output sha256',h)
q=pefile.PE(data=new); assert q.sections[-1].Misc_VirtualSize==0x800+len(blob) and q.sections[-1].SizeOfRawData==0xc00
assert q.OPTIONAL_HEADER.SizeOfImage==0x620000
assert not any(e.type!=0 and e.rva==0x1f22bf for block in q.DIRECTORY_ENTRY_BASERELOC for e in block.entries)
os.makedirs(P+'package/GRM_OGSR_POSE',exist_ok=True)
open(P+'package/GRM_OGSR_POSE/xrGame.dll','wb').write(new)
ps=r'''$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Split-Path -Parent $MyInvocation.MyCommand.Path))
$dll = Join-Path $root 'bin\xrGame.dll'
$exe = Join-Path $root 'bin\XR_3DA.exe'
$payload = Join-Path $root 'GRM_OGSR_POSE\xrGame.dll'
$temp=$null; $backup=$null; $replaced=$false
function HashFile([string]$path) { $s=[Security.Cryptography.SHA256]::Create(); $f=[IO.File]::OpenRead($path); try { return ([BitConverter]::ToString($s.ComputeHash($f))).Replace('-','').ToLowerInvariant() } finally { $f.Dispose(); $s.Dispose() } }
try {
 [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding
 if (@(Get-Process | Where-Object { $_.ProcessName -like 'XR_3DA*' }).Count -gt 0) { throw 'Закройте игру. Ничего не изменено.' }
 foreach($f in @($dll,$exe,$payload)) { if (!(Test-Path -LiteralPath $f -PathType Leaf)) { throw ('Не найден файл: '+$f+'. Распакуйте архив в папку игры.') } }
 if ((HashFile $exe) -ne '5d52602915fbcbc25798b617a89303117edebb36fefef894ed0abd36e7cd634b') { throw 'Другая версия XR_3DA.exe. Ничего не изменено.' }
 $old=HashFile $dll
 if ($old -eq 'NEWHASH') { Write-Host 'Патч уже установлен.'; exit 0 }
 if ($old -ne 'c5f1968e680b1bef8d000a0a2d37adf343026628994fffcb138fea1c3130e9fb') { throw ('Другая версия xrGame.dll. Ничего не изменено. SHA256: '+$old) }
 if ((HashFile $payload) -ne 'NEWHASH') { throw 'Файл патча повреждён. Ничего не изменено.' }
 $dir=Split-Path -Parent $dll
 $temp=Join-Path $dir ([IO.Path]::GetRandomFileName()+'.tmp')
 $backup=Join-Path $dir ([IO.Path]::GetRandomFileName()+'.bak')
 [IO.File]::Copy($payload,$temp)
 if ((HashFile $temp) -ne 'NEWHASH') { throw 'Ошибка проверки записи. Ничего не изменено.' }
 [IO.File]::Replace($temp,$dll,$backup); $temp=$null; $replaced=$true
 if ((HashFile $dll) -ne 'NEWHASH') { throw 'Ошибка проверки установленной DLL.' }
 Remove-Item -LiteralPath $backup -Force -ErrorAction SilentlyContinue; $backup=$null
 Write-Host 'Экспериментальная правка движка установлена.'
} catch {
 Write-Host ('ОШИБКА: '+$_.Exception.Message)
 if ($replaced -and $backup -and (Test-Path -LiteralPath $backup)) {
   try { $discard=Join-Path (Split-Path -Parent $dll) ([IO.Path]::GetRandomFileName()+'.tmp'); [IO.File]::Replace($backup,$dll,$discard); Remove-Item -LiteralPath $discard -Force -ErrorAction SilentlyContinue; $backup=$null; Write-Host 'Прежняя DLL восстановлена.' }
   catch { Write-Host ('Исходная DLL сохранена здесь: '+$backup) }
 }
 exit 1
} finally { if ($temp -and (Test-Path -LiteralPath $temp)) { Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue } }
'''.replace('NEWHASH',h)
open(P+'package/GRM_OGSR_POSE.ps1','w',encoding='utf-8-sig',newline='\r\n').write(ps)
open(P+'package/INSTALL_GRM_OGSR_POSE.bat','w',encoding='ascii',newline='').write('@echo off\r\npowershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0GRM_OGSR_POSE.ps1"\r\npause\r\n')
text='''ЭКСПЕРИМЕНТАЛЬНЫЙ ПАТЧ ФИЗИКИ ТРУПОВ\n\nПеред установкой закройте игру и сделайте полный бэкап игры и сохранений.\nРаспакуйте весь архив в папку игры (где находится папка bin). Запустите INSTALL_GRM_OGSR_POSE.bat. Установщик проверит точные версии EXE и DLL.\n\nПатч меняет только bin/xrGame.dll. Для подходящих NPC с невидимой головой маска применяется после инициализации физики и её восстановления. Оставлены прежние защиты и все остальные файлы, включая скрипты. Влияние на разделку ножом необходимо проверить отдельно.\n\nВ игре не проверялся. Не гарантирует исправления вылета сохранения и не исправляет растянутые модели. Тест: используйте копию старого ручного сейва, убейте NPC с эффектом, сохраните, загрузите, повторите и перейдите на другую локацию. jump_to_level перезаписывает автосейв. В логе ищите GRM_OGSR_POSE и GRM_PHYS_DIAG.\n'''
open(P+'package/README.txt','w',encoding='utf-8-sig').write(text)
out='/data/GRM_OGSR_Corpse_Physics_TEST.zip'
with zipfile.ZipFile(out,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=9) as z:
 for root,dirs,files in os.walk(P+'package'):
  for f in files:
   path=os.path.join(root,f); z.write(path,os.path.relpath(path,P+'package'))
print(out,os.path.getsize(out))
