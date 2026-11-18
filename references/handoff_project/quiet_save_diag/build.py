from pathlib import Path
import hashlib,zipfile
p=Path('/data/grm/quiet_save_diag/package'); p.mkdir(parents=True,exist_ok=True)
files=['/data/grm/newbin_last/bin/xrGame.dll','/data/grm/ogsrpose/package/GRM_OGSR_POSE/xrGame.dll','/data/grm/corpsegore/package/GRM_Corpse/engine0.dll','/data/grm/corpsegore/package/GRM_Corpse/engine1.dll']
sha=lambda b:hashlib.sha256(b).hexdigest(); rows=[]
for f in files:
 b=Path(f).read_bytes();n=bytearray(b)
 assert b[0x7285e:0x72865]==bytes.fromhex('e89dbd5a009090') and b[0x728b5:0x728bc]==bytes.fromhex('e846bd5a009090')
 for at in (0x7285e,0x728b5):n[at:at+7]=bytes.fromhex('8b842418200000')
 assert {i for i,(x,y) in enumerate(zip(b,n)) if x!=y} <= set(range(0x7285e,0x72865))|set(range(0x728b5,0x728bc))
 rows.append((sha(b),sha(n)));print(sha(b),sha(n))
entries=',\n'.join("[pscustomobject]@{old='%s';new='%s'}"%r for r in rows)
ps=r'''$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Split-Path -Parent $MyInvocation.MyCommand.Path))
function Hash([byte[]]$bytes) { $a=[Security.Cryptography.SHA256]::Create(); try { return ([BitConverter]::ToString($a.ComputeHash($bytes))).Replace('-','').ToLowerInvariant() } finally { $a.Dispose() } }
$specs=@(
ROWS
)
$tmp=$null; $bak=$null; $replaced=$false
try {
 [Console]::OutputEncoding=New-Object System.Text.UTF8Encoding
 if (@(Get-Process | Where-Object { $_.ProcessName -like 'XR_3DA*' }).Count -gt 0) { throw 'Закройте игру.' }
 $exe=Join-Path $root 'bin\XR_3DA.exe'; $target=Join-Path $root 'bin\xrGame.dll'
 foreach ($f in @($exe,$target)) { if (!(Test-Path -LiteralPath $f -PathType Leaf)) { throw ('Нет файла: '+$f) } }
 if ((Hash ([IO.File]::ReadAllBytes($exe))) -ne '5d52602915fbcbc25798b617a89303117edebb36fefef894ed0abd36e7cd634b') { throw 'Версия XR_3DA.exe не совпадает. Изменений нет.' }
 [byte[]]$data=[IO.File]::ReadAllBytes($target); $old=Hash $data
 foreach ($s in $specs) { if ($old -eq $s.new) { Write-Host 'Диагностика сохранений уже отключена.'; exit 0 } }
 $entry=$specs | Where-Object { $_.old -eq $old } | Select-Object -First 1
 if (!$entry) { throw ('Другая версия xrGame.dll. Изменений нет. SHA256: '+$old) }
 [byte[]]$original=0x8b,0x84,0x24,0x18,0x20,0x00,0x00
 [Array]::Copy($original,0,$data,0x7285e,7); [Array]::Copy($original,0,$data,0x728b5,7)
 if ((Hash $data) -ne $entry.new) { throw 'Проверка изменений не пройдена.' }
 $dir=Split-Path -Parent $target; $tmp=Join-Path $dir ([IO.Path]::GetRandomFileName()+'.tmp'); $bak=Join-Path $dir ([IO.Path]::GetRandomFileName()+'.bak')
 [IO.File]::WriteAllBytes($tmp,$data); if ((Hash ([IO.File]::ReadAllBytes($tmp))) -ne $entry.new) { throw 'Ошибка проверки записи.' }
 [IO.File]::Replace($tmp,$target,$bak); $replaced=$true
 if ((Hash ([IO.File]::ReadAllBytes($target))) -ne $entry.new) { throw 'Ошибка проверки установленного файла.' }
 Remove-Item -LiteralPath $bak -Force -ErrorAction SilentlyContinue; $bak=$null
 Write-Host 'Журнал GRM_SAVE_DIAG отключён. Остальные правки сохранены.'
} catch {
 if ($replaced -and $bak -and (Test-Path -LiteralPath $bak)) { try { $discard=Join-Path (Split-Path -Parent $target) ([IO.Path]::GetRandomFileName()+'.tmp'); [IO.File]::Replace($bak,$target,$discard); Remove-Item -LiteralPath $discard -Force -ErrorAction SilentlyContinue; $bak=$null } catch { Write-Host ('Исходный файл: '+$bak) } }
 Write-Host ('ОШИБКА: '+$_.Exception.Message); exit 1
} finally { if ($tmp -and (Test-Path -LiteralPath $tmp)) { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue } }
'''.replace('ROWS',entries)
(p/'GRM_QuietSaveDiag.ps1').write_text(ps,encoding='utf-8-sig',newline='\r\n')
(p/'INSTALL_GRM_QuietSaveDiag.bat').write_bytes(b'@echo off\r\nchcp 65001 >nul\r\npowershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0GRM_QuietSaveDiag.ps1"\r\npause\r\n')
(p/'ПРОЧТИ.txt').write_text('''Закройте игру и сделайте полный бэкап игры и сохранений. Распакуйте архив в папку игры и запустите INSTALL_GRM_QuietSaveDiag.bat. Он изменит только bin\\xrGame.dll при точном совпадении проверенных версий. Другие скрипты и исправления не меняются. Отключается только журнал GRM_SAVE_DIAG. Это не доказанный фикс вылета при переходе. В игре не проверено. jump_to_level перезаписывает user_autosave.sav; проверяйте на копии ручного сохранения. Если предыдущий патч Particle Transition ещё не установлен, установите его первым: он проверяет версию DLL до этой правки.\n''',encoding='utf-8-sig')
with zipfile.ZipFile('/data/GRM_Quiet_Save_Diagnostics_TEST.zip','w',zipfile.ZIP_DEFLATED) as z:
 for f in p.iterdir():z.write(f,f.name)
with zipfile.ZipFile('/data/GRM_Quiet_Save_Diagnostics_TEST.zip') as z:assert z.testzip() is None
