$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Split-Path -Parent $MyInvocation.MyCommand.Path))
function Hash([byte[]]$bytes) { $a=[Security.Cryptography.SHA256]::Create(); try { return ([BitConverter]::ToString($a.ComputeHash($bytes))).Replace('-','').ToLowerInvariant() } finally { $a.Dispose() } }
$specs=@(
[pscustomobject]@{old='c5f1968e680b1bef8d000a0a2d37adf343026628994fffcb138fea1c3130e9fb';new='258e6be1b4db929bc915088f485379ec6db86a525690f3ff227da2a091291742'},
[pscustomobject]@{old='4a6e84f3397b853124158865bd71b54f9c438d11384bad6a90eaa08c20216959';new='b60bfe6f03a1f085dd7d5bcb1b8771668b24e60ed44d8d2394aa339e78125225'},
[pscustomobject]@{old='969d116337e15a0f5c0af212c8c49ea5262bba3b2d93e4ca7af7ff140e2856d7';new='dd08eeaa462788fd6b00481a987a33c848c9d417f4b4d67781219ebeadcedd71'},
[pscustomobject]@{old='f59cdeeeb652adcb8f76ec621a32e72552f2037db457e7f3ea3e19633f702fbd';new='bf347977fde7ce70d310181c1fc18df78e6d539b5092b218758b1bd7c4cb2e90'}
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
