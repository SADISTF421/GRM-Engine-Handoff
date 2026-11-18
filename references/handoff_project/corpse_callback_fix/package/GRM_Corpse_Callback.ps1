$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Split-Path -Parent $MyInvocation.MyCommand.Path))
function Hash([string]$p) { return (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLowerInvariant() }
$tmp=$null; $bak=$null; $replaced=$false
try {
 [Console]::OutputEncoding=New-Object System.Text.UTF8Encoding
 if (@(Get-Process | Where-Object { $_.ProcessName -like 'XR_3DA*' }).Count -gt 0) { throw 'Закройте игру.' }
 $exe=Join-Path $root 'bin\XR_3DA.exe'; $dll=Join-Path $root 'bin\xrGame.dll'; $gore=Join-Path $root 'gamedata\scripts\grm_gore_test.script'; $target=Join-Path $root 'gamedata\scripts\xr_motivator.script'; $source=Join-Path $root 'GRM_Corpse_Callback\xr_motivator.script'
 foreach ($p in @($exe,$dll,$gore,$target,$source)) { if (!(Test-Path -LiteralPath $p -PathType Leaf)) { throw ('Не найден файл: '+$p) } }
 if ((Hash $exe) -ne '5d52602915fbcbc25798b617a89303117edebb36fefef894ed0abd36e7cd634b') { throw 'Другая версия EXE.' }
 if (@('969d116337e15a0f5c0af212c8c49ea5262bba3b2d93e4ca7af7ff140e2856d7','f59cdeeeb652adcb8f76ec621a32e72552f2037db457e7f3ea3e19633f702fbd') -notcontains (Hash $dll)) { throw ('Нужна установленная предыдущая версия патча. xrGame.dll SHA256: '+(Hash $dll)) }
 if (@('ebf92bc9fd6a18272eb58eb3432e29cc7d807560a5e4bc2909c7e2fe9c800e64','7e3118d4fe9abbe94dc255412d346134c7167e6c8211a6140378baeb9a6e4c7e') -notcontains (Hash $gore)) { throw ('Другая версия скрипта grm_gore_test.script SHA256: '+(Hash $gore)) }
 $targetHash=Hash $target
 if ($targetHash -eq '4f26699c3260e4a7c90a1007bff925477eff7b62b53d05d399e7a5d42021450b') { Write-Host 'Уже установлен.'; exit 0 }
 if ($targetHash -ne 'cc39221b2fb38bd844058dbdec2dd7b8828063343a32e55022bdb83ac3ea3915') { throw ('Другая версия xr_motivator.script SHA256: '+$targetHash) }
 if ((Hash $source) -ne '4f26699c3260e4a7c90a1007bff925477eff7b62b53d05d399e7a5d42021450b') { throw 'Файл патча повреждён.' }
 $dir=Split-Path -Parent $target; $tmp=Join-Path $dir ([IO.Path]::GetRandomFileName()+'.tmp'); $bak=Join-Path $dir ([IO.Path]::GetRandomFileName()+'.bak')
 [IO.File]::Copy($source,$tmp); if ((Hash $tmp) -ne '4f26699c3260e4a7c90a1007bff925477eff7b62b53d05d399e7a5d42021450b') { throw 'Ошибка проверки временного файла.' }
 [IO.File]::Replace($tmp,$target,$bak); $replaced=$true
 if ((Hash $target) -ne '4f26699c3260e4a7c90a1007bff925477eff7b62b53d05d399e7a5d42021450b') { throw 'Ошибка проверки записи.' }
 Remove-Item -LiteralPath $bak -Force -ErrorAction SilentlyContinue; $bak=$null
 Write-Host 'Готово. Проверьте в игре.'
} catch {
 if ($replaced -and $bak -and (Test-Path -LiteralPath $bak)) { try { $discard=Join-Path (Split-Path -Parent $target) ([IO.Path]::GetRandomFileName()+'.tmp'); [IO.File]::Replace($bak,$target,$discard); Remove-Item -LiteralPath $discard -Force -ErrorAction SilentlyContinue; $bak=$null } catch { Write-Host ('Исходный файл: '+$bak) } }
 Write-Host ('ОШИБКА: '+$_.Exception.Message); exit 1
} finally { if ($tmp -and (Test-Path -LiteralPath $tmp)) { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue } }
