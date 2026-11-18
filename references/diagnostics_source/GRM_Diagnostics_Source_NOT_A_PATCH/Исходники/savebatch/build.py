from pathlib import Path
import hashlib, json, zipfile
P=Path('/data/grm/savebatch');pkg=P/'pkg';h=lambda b:hashlib.sha256(b).hexdigest();off=0x1aee59
files=[Path('/data/grm/engdiag/original_diag.dll'),Path('/data/grm/engdiag/particlefixed_diag.dll'),Path('/data/grm/boneengine/original.dll'),Path('/data/grm/boneengine/particlefixed.dll')];pairs=[]
for f in files:
 b=bytearray(f.read_bytes());before=h(b);assert b[off:off+2]==bytes.fromhex('7215');b[off]=0xeb;after=h(b);pairs.append((before,after));print(f.name,before,'->',after)
script=r'''$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Split-Path -Parent $MyInvocation.MyCommand.Path))
$dll=Join-Path $root 'bin\xrGame.dll'; $exe=Join-Path $root 'bin\XR_3DA.exe'; $temp=$null; $backup=$null; $replaced=$false
function Hash([byte[]]$b) { $sha=[Security.Cryptography.SHA256]::Create(); try { return ([BitConverter]::ToString($sha.ComputeHash($b))).Replace('-','').ToLowerInvariant() } finally { $sha.Dispose() } }
try {
 [Console]::OutputEncoding=New-Object System.Text.UTF8Encoding
 if (@(Get-Process | Where-Object { $_.ProcessName -like 'XR_3DA*' }).Count -gt 0) { throw 'Закройте игру. Ничего не изменено.' }
 foreach($f in @($exe,$dll)){ if(!(Test-Path -LiteralPath $f -PathType Leaf)){ throw ('Не найден файл: '+$f+'. Ничего не изменено.') } }
 if ((Hash ([IO.File]::ReadAllBytes($exe))) -ne '5d52602915fbcbc25798b617a89303117edebb36fefef894ed0abd36e7cd634b') { throw 'XR_3DA.exe другой версии. Ничего не изменено.' }
 [byte[]]$data=[IO.File]::ReadAllBytes($dll); $h=Hash $data; $expected=$null
HASHCHECK
 if (!$expected) { throw ('Неизвестная версия xrGame.dll. Ничего не изменено. SHA256: '+$h) }
 if ($data[0x1aee59] -ne 0x72 -or $data[0x1aee5a] -ne 0x15) { throw 'Не совпала проверочная инструкция. Ничего не изменено.' }
 $data[0x1aee59]=0xeb
 if ((Hash $data) -ne $expected) { throw 'Ошибка проверки результата. Ничего не изменено.' }
 $dir=Split-Path -Parent $dll; $temp=Join-Path $dir ([IO.Path]::GetRandomFileName()+'.tmp'); $backup=Join-Path $dir ([IO.Path]::GetRandomFileName()+'.bak')
 [IO.File]::WriteAllBytes($temp,$data)
 if ((Hash ([IO.File]::ReadAllBytes($temp))) -ne $expected) { throw 'Ошибка записи. Ничего не изменено.' }
 [IO.File]::Replace($temp,$dll,$backup); $temp=$null; $replaced=$true
 if ((Hash ([IO.File]::ReadAllBytes($dll))) -ne $expected) { throw 'Ошибка проверки установленной DLL.' }
 Remove-Item -LiteralPath $backup -Force -ErrorAction SilentlyContinue; $backup=$null
 Write-Host 'Тестовая защита пакетов сохранения установлена.'
} catch {
 Write-Host ('ОШИБКА: '+$_.Exception.Message)
 if ($replaced -and $backup -and (Test-Path -LiteralPath $backup)) {
  try { $discard=Join-Path (Split-Path -Parent $dll) ([IO.Path]::GetRandomFileName()+'.tmp'); [IO.File]::Replace($backup,$dll,$discard); Remove-Item -LiteralPath $discard -Force -ErrorAction SilentlyContinue; $backup=$null; Write-Host 'Прежняя DLL восстановлена.' }
  catch { Write-Host ('Исходная DLL сохранена здесь: '+$backup) }
 }
 exit 1
} finally { if ($temp -and (Test-Path -LiteralPath $temp)) { Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue } }
'''
checks=[]
for before,after in pairs:checks.append(" if ($h -eq '%s') { $expected='%s' }"%(before,after))
for _,after in pairs:checks.append(" if ($h -eq '%s') { Write-Host 'Уже установлено.'; exit 0 }"%after)
script=script.replace('HASHCHECK','\n'.join(checks));(pkg/'GRM_Save_Packets.ps1').write_text(script,encoding='utf-8-sig',newline='\r\n')
(pkg/'INSTALL_GRM_Save_Packets.bat').write_bytes(b'@echo off\r\nchcp 65001 >nul\r\npowershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0GRM_Save_Packets.ps1"\r\npause\r\n')
readme='''ТЕСТОВАЯ ЗАЩИТА ПАКЕТОВ СОХРАНЕНИЯ\r\n\r\nЗакройте игру. Сделайте полный бэкап игры и сохранений. Распакуйте архив в папку игры рядом с bin и запустите INSTALL_GRM_Save_Packets.bat. Изменяется одна инструкция в bin\\xrGame.dll. Установщик принимает только четыре известные версии DLL и проверенный EXE; при несовпадении ничего не меняет. Скрипты, модели, эффекты и сохранения не меняются.\r\n\r\nПо логу вылет произошёл при записи звуковой памяти NPC в пакет. Этот эксперимент отправляет сохранения объектов по одному на пакет вместо группировки. Он устраняет только риск переполнения от суммарного размера нескольких объектов, если каждый из них сам помещается в пакет. Если один объект слишком большой, пакет или указатели повреждены по другой причине, вылет может сохраниться. Возможны дополнительные задержки при сохранении и другие побочные эффекты. Причина данного вылета ещё не доказана.\r\n\r\nДвижок не проверен в игре. Проверять на копии старого сохранения: несколько сохранений, перезагрузка каждого и переход между локациями. jump_to_level перезаписывает user_autosave.sav. Патч не исправляет растяжение моделей.\r\n'''
(pkg/'READ_ME.txt').write_bytes(readme.encode('utf-8-sig'))
with zipfile.ZipFile('/data/GRm_Save_Packets_TEST.zip','w',zipfile.ZIP_DEFLATED) as z:
 for f in pkg.iterdir(): z.write(f,f.name)
assert zipfile.ZipFile('/data/GRm_Save_Packets_TEST.zip').testzip() is None
