$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Split-Path -Parent $MyInvocation.MyCommand.Path))
function Hash([string]$p) { return (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLowerInvariant() }
$specs=@(
  [pscustomobject]@{old='796b2db67e21ec231fb7455f09da9e0bcabb03b9550aeea663b96d411c8946e9';new='c0fbed884abc839dd4856082fd287141d4aebd04cd061a220ef196bbcb25e0a8';file='100ms_popup.script'},
  [pscustomobject]@{old='f4904a34ac1e79b285f03ff6427df45dd237c989012a16455411566229c53151';new='14af0a7b3399f54c980a1dc211b206342f4b2acf46d95c48315d84a015ca1c13';file='50ms_popup.script'},
  [pscustomobject]@{old='bbab0c15788ddceab6c87128cc11bba61cb107829425e0e006da46898826af2d';new='da4fa7f017f0aca7af1aca8577f75be9d72d9b9f804b97b65f53cfcc1cf2d851';file='100ms_quiet.script'},
  [pscustomobject]@{old='62a9340cedda07264ec8696078407ff5f53071993ba716e6b9c82252640b55dc';new='1191db234c19ea11dc9a33d89374c3984a88d576772699cccc1b2e3199ba14d6';file='50ms_quiet.script'},
  [pscustomobject]@{old='9d010f7adce860dad994b19c54789a5ea46979e25c7dbc29ec117f6a70594bfd';new='e295e303a9d838afa67ef1fd8eed5183f05819b8d4c460016dcd21e95f24d2c9';file='100ms_corpse.script'},
  [pscustomobject]@{old='db46e6f60adb172a1ad6d4bb75d1b1625bfc87a15e15074b742a7dd78820025f';new='9f8674b9f4f9e2d90ac7cb5cc3fc98e363f1f6f7181cc2653918289804232b77';file='50ms_corpse.script'}
)
$tmp=$null; $bak=$null; $replaced=$false
try {
 [Console]::OutputEncoding=New-Object System.Text.UTF8Encoding
 if (@(Get-Process | Where-Object { $_.ProcessName -like 'XR_3DA*' }).Count -gt 0) { throw 'Закройте игру.' }
 $exe=Join-Path $root 'bin\XR_3DA.exe'; $dll=Join-Path $root 'bin\xrGame.dll'; $target=Join-Path $root 'gamedata\scripts\grm_gore_test.script'
 foreach ($f in @($exe,$dll,$target)) { if (!(Test-Path -LiteralPath $f -PathType Leaf)) { throw ('Нет файла: '+$f) } }
 if ((Hash $exe) -ne '5d52602915fbcbc25798b617a89303117edebb36fefef894ed0abd36e7cd634b') { throw 'Версия XR_3DA.exe не совпадает. Изменений нет.' }
 $dh=Hash $dll
 if (@('c5f1968e680b1bef8d000a0a2d37adf343026628994fffcb138fea1c3130e9fb','4a6e84f3397b853124158865bd71b54f9c438d11384bad6a90eaa08c20216959','969d116337e15a0f5c0af212c8c49ea5262bba3b2d93e4ca7af7ff140e2856d7','f59cdeeeb652adcb8f76ec621a32e72552f2037db457e7f3ea3e19633f702fbd') -notcontains $dh) { throw ('Другая версия xrGame.dll. Изменений нет. SHA256: '+$dh) }
 $sh=Hash $target
 foreach ($s in $specs) { if ($sh -eq $s.new) { Write-Host 'Патч уже установлен.'; exit 0 } }
 $entry=$specs | Where-Object { $_.old -eq $sh } | Select-Object -First 1
 if (!$entry) { throw ('Другая версия grm_gore_test.script. Изменений нет. SHA256: '+$sh) }
 $source=Join-Path $root ('GRM_ParticleTransition\'+$entry.file)
 if (!(Test-Path -LiteralPath $source -PathType Leaf) -or (Hash $source) -ne $entry.new) { throw 'Нет файла патча или он повреждён.' }
 $dir=Split-Path -Parent $target
 $tmp=Join-Path $dir ([IO.Path]::GetRandomFileName()+'.tmp');$bak=Join-Path $dir ([IO.Path]::GetRandomFileName()+'.bak')
 [IO.File]::Copy($source,$tmp); if ((Hash $tmp) -ne $entry.new) { throw 'Ошибка проверки записи.' }
 [IO.File]::Replace($tmp,$target,$bak); $replaced=$true
 if ((Hash $target) -ne $entry.new) { throw 'Ошибка проверки установленного файла.' }
 Remove-Item -LiteralPath $bak -Force -ErrorAction SilentlyContinue; $bak=$null
 Write-Host 'Исправление установлено.'
} catch {
 if ($replaced -and $bak -and (Test-Path -LiteralPath $bak)) { try { $discard=Join-Path (Split-Path -Parent $target) ([IO.Path]::GetRandomFileName()+'.tmp'); [IO.File]::Replace($bak,$target,$discard); Remove-Item -LiteralPath $discard -Force -ErrorAction SilentlyContinue; $bak=$null } catch { Write-Host ('Исходный файл: '+$bak) } }
 Write-Host ('ОШИБКА: '+$_.Exception.Message); exit 1
} finally { if ($tmp -and (Test-Path -LiteralPath $tmp)) { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue } }
