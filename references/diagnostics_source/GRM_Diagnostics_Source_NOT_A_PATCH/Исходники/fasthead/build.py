from pathlib import Path
import hashlib, zipfile
p=Path('/data/grm/fasthead'); pkg=p/'pkg'; s=Path('/data/grm/chance75/package/GRM_Chance75/grm_gore_test.script').read_bytes()
old=b'elseif now - pending.started >= 100 then';new=b'elseif now - pending.started >= 50 then';assert s.count(old)==1
r=s.replace(old,new);(p/'grm_gore_fast.script').write_bytes(r)
h=lambda b:hashlib.sha256(b).hexdigest(); print('original',h(s),'modified',h(r))
ps=r'''$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Split-Path -Parent $MyInvocation.MyCommand.Path))
$target=Join-Path $root 'gamedata\scripts\grm_gore_test.script'
$dll=Join-Path $root 'bin\xrGame.dll'; $exe=Join-Path $root 'bin\XR_3DA.exe'
$temp=$null; $backup=$null; $replaced=$false
function Hash([byte[]]$b) { $s=[Security.Cryptography.SHA256]::Create(); try { return ([BitConverter]::ToString($s.ComputeHash($b))).Replace('-','').ToLowerInvariant() } finally { $s.Dispose() } }
try {
 [Console]::OutputEncoding=New-Object System.Text.UTF8Encoding
 if (@(Get-Process | Where-Object { $_.ProcessName -like 'XR_3DA*' }).Count -gt 0) { throw 'Закройте игру. Ничего не изменено.' }
 foreach ($f in @($target,$dll,$exe)) { if (!(Test-Path -LiteralPath $f -PathType Leaf)) { throw ('Не найден файл: '+$f+'. Ничего не изменено.') } }
 if ((Hash ([IO.File]::ReadAllBytes($exe))) -ne '5d52602915fbcbc25798b617a89303117edebb36fefef894ed0abd36e7cd634b') { throw 'Другая версия EXE. Ничего не изменено.' }
 if ((Hash ([IO.File]::ReadAllBytes($dll))) -ne 'c5f1968e680b1bef8d000a0a2d37adf343026628994fffcb138fea1c3130e9fb') { throw 'Другая версия xrGame.dll. Ничего не изменено.' }
 [byte[]]$bytes=[IO.File]::ReadAllBytes($target); $h=Hash $bytes
 if ($h -eq 'NEW_HASH') { Write-Host 'Уже установлено.'; exit 0 }
 if ($h -ne 'OLD_HASH') { throw ('Скрипт отличается от проверенной версии. Ничего не изменено. SHA256: '+$h) }
 $enc=[Text.Encoding]::GetEncoding(28591); $text=$enc.GetString($bytes)
 $old='elseif now - pending.started >= 100 then'; $new='elseif now - pending.started >= 50 then'
 if ($text.IndexOf($old,[StringComparison]::Ordinal) -lt 0 -or $text.IndexOf($old,[StringComparison]::Ordinal) -ne $text.LastIndexOf($old,[StringComparison]::Ordinal)) { throw 'Не найден однозначный таймер. Ничего не изменено.' }
 [byte[]]$data=$enc.GetBytes($text.Replace($old,$new))
 if ((Hash $data) -ne 'NEW_HASH') { throw 'Ошибка проверки результата. Ничего не изменено.' }
 $dir=Split-Path -Parent $target; $temp=Join-Path $dir ([IO.Path]::GetRandomFileName()+'.tmp'); $backup=Join-Path $dir ([IO.Path]::GetRandomFileName()+'.bak')
 [IO.File]::WriteAllBytes($temp,$data)
 if ((Hash ([IO.File]::ReadAllBytes($temp))) -ne 'NEW_HASH') { throw 'Ошибка проверки записи. Ничего не изменено.' }
 [IO.File]::Replace($temp,$target,$backup); $temp=$null; $replaced=$true
 if ((Hash ([IO.File]::ReadAllBytes($target))) -ne 'NEW_HASH') { throw 'Ошибка проверки установленного файла.' }
 Remove-Item -LiteralPath $backup -Force -ErrorAction SilentlyContinue; $backup=$null
 Write-Host 'Готово: минимальная задержка скрытия 50 мс.'
} catch {
 Write-Host ('ОШИБКА: '+$_.Exception.Message)
 if ($replaced -and $backup -and (Test-Path -LiteralPath $backup)) {
  try { $discard=Join-Path (Split-Path -Parent $target) ([IO.Path]::GetRandomFileName()+'.tmp'); [IO.File]::Replace($backup,$target,$discard); Remove-Item -LiteralPath $discard -Force -ErrorAction SilentlyContinue; $backup=$null; Write-Host 'Прежний скрипт восстановлен.' }
  catch { Write-Host ('Исходный скрипт сохранён: '+$backup) }
 }
 exit 1
} finally { if ($temp -and (Test-Path -LiteralPath $temp)) { Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue } }
'''.replace('NEW_HASH',h(r)).replace('OLD_HASH',h(s))
(pkg/'GRM_Fast_Head.ps1').write_text(ps,encoding='utf-8-sig',newline='\r\n')
(pkg/'INSTALL_GRM_Fast_Head.bat').write_bytes(b'@echo off\r\nchcp 65001 >nul\r\npowershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0GRM_Fast_Head.ps1"\r\npause\r\n')
readme='''ТЕСТ: БЫСТРЕЕ СКРЫВАТЬ ГОЛОВУ\r\n\r\nЗакройте игру. Сделайте полный бэкап игры и сохранений. Распакуйте в папку игры рядом с bin и gamedata, запустите INSTALL_GRM_Fast_Head.bat. Установщик проверяет точные хэши EXE, xrGame.dll и исходного скрипта, изменяет только gamedata\\scripts\\grm_gore_test.script. При несовпадении ничего не изменяет.\r\n\r\nМинимальное ожидание уменьшено со 100 до 50 мс; фактическое время зависит от обновления NPC. Вызов всё ещё происходит при обновлении после смерти. Шанс, оружие, кровь и прочая логика не меняются. Рэгдоллы, движение тел после загрузки и вылеты сохранения этот патч не исправляет. В игре не проверен. Проверяйте на копии старого сохранения; jump_to_level перезаписывает user_autosave.sav.\r\n'''
(pkg/'ПРОЧТИ.txt').write_bytes(readme.encode('utf-8-sig'))
with zipfile.ZipFile('/data/GRM_Fast_Head_50ms_TEST.zip','w',zipfile.ZIP_DEFLATED) as z:
 for f in pkg.iterdir(): z.write(f,f.name)
assert zipfile.ZipFile('/data/GRM_Fast_Head_50ms_TEST.zip').testzip() is None
