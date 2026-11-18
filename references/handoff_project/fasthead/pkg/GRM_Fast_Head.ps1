$ErrorActionPreference='Stop'
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
 if ($h -eq 'f4904a34ac1e79b285f03ff6427df45dd237c989012a16455411566229c53151') { Write-Host 'Уже установлено.'; exit 0 }
 if ($h -ne '796b2db67e21ec231fb7455f09da9e0bcabb03b9550aeea663b96d411c8946e9') { throw ('Скрипт отличается от проверенной версии. Ничего не изменено. SHA256: '+$h) }
 $enc=[Text.Encoding]::GetEncoding(28591); $text=$enc.GetString($bytes)
 $old='elseif now - pending.started >= 100 then'; $new='elseif now - pending.started >= 50 then'
 if ($text.IndexOf($old,[StringComparison]::Ordinal) -lt 0 -or $text.IndexOf($old,[StringComparison]::Ordinal) -ne $text.LastIndexOf($old,[StringComparison]::Ordinal)) { throw 'Не найден однозначный таймер. Ничего не изменено.' }
 [byte[]]$data=$enc.GetBytes($text.Replace($old,$new))
 if ((Hash $data) -ne 'f4904a34ac1e79b285f03ff6427df45dd237c989012a16455411566229c53151') { throw 'Ошибка проверки результата. Ничего не изменено.' }
 $dir=Split-Path -Parent $target; $temp=Join-Path $dir ([IO.Path]::GetRandomFileName()+'.tmp'); $backup=Join-Path $dir ([IO.Path]::GetRandomFileName()+'.bak')
 [IO.File]::WriteAllBytes($temp,$data)
 if ((Hash ([IO.File]::ReadAllBytes($temp))) -ne 'f4904a34ac1e79b285f03ff6427df45dd237c989012a16455411566229c53151') { throw 'Ошибка проверки записи. Ничего не изменено.' }
 [IO.File]::Replace($temp,$target,$backup); $temp=$null; $replaced=$true
 if ((Hash ([IO.File]::ReadAllBytes($target))) -ne 'f4904a34ac1e79b285f03ff6427df45dd237c989012a16455411566229c53151') { throw 'Ошибка проверки установленного файла.' }
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
