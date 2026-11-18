$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Split-Path -Parent $MyInvocation.MyCommand.Path))
function Hash([string]$p) { return (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLowerInvariant() }
$tmp=$null; $bak=$null; $replaced=$false
try {
 [Console]::OutputEncoding=New-Object System.Text.UTF8Encoding
 if (@(Get-Process | Where-Object { $_.ProcessName -like 'XR_3DA*' }).Count -gt 0) { throw 'Закройте игру.' }
 $exe=Join-Path $root 'bin\XR_3DA.exe'; $dll=Join-Path $root 'bin\xrGame.dll'; $script=Join-Path $root 'gamedata\scripts\grm_gore_test.script'; $payload=Join-Path $root 'GRM_RenderNeck\XR_3DA.patched'
 foreach ($f in @($exe,$dll,$script,$payload)) { if (!(Test-Path -LiteralPath $f -PathType Leaf)) { throw ('Нет файла: '+$f) } }
 $dh=Hash $dll
 if (@('c5f1968e680b1bef8d000a0a2d37adf343026628994fffcb138fea1c3130e9fb','4a6e84f3397b853124158865bd71b54f9c438d11384bad6a90eaa08c20216959','969d116337e15a0f5c0af212c8c49ea5262bba3b2d93e4ca7af7ff140e2856d7','f59cdeeeb652adcb8f76ec621a32e72552f2037db457e7f3ea3e19633f702fbd','258e6be1b4db929bc915088f485379ec6db86a525690f3ff227da2a091291742','b60bfe6f03a1f085dd7d5bcb1b8771668b24e60ed44d8d2394aa339e78125225','dd08eeaa462788fd6b00481a987a33c848c9d417f4b4d67781219ebeadcedd71','bf347977fde7ce70d310181c1fc18df78e6d539b5092b218758b1bd7c4cb2e90') -notcontains $dh) { throw ('Другая версия xrGame.dll. Изменений нет. SHA256: '+$dh) }
 $sh=Hash $script
 if (@('796b2db67e21ec231fb7455f09da9e0bcabb03b9550aeea663b96d411c8946e9','f4904a34ac1e79b285f03ff6427df45dd237c989012a16455411566229c53151','bbab0c15788ddceab6c87128cc11bba61cb107829425e0e006da46898826af2d','62a9340cedda07264ec8696078407ff5f53071993ba716e6b9c82252640b55dc','9d010f7adce860dad994b19c54789a5ea46979e25c7dbc29ec117f6a70594bfd','db46e6f60adb172a1ad6d4bb75d1b1625bfc87a15e15074b742a7dd78820025f','c0fbed884abc839dd4856082fd287141d4aebd04cd061a220ef196bbcb25e0a8','14af0a7b3399f54c980a1dc211b206342f4b2acf46d95c48315d84a015ca1c13','da4fa7f017f0aca7af1aca8577f75be9d72d9b9f804b97b65f53cfcc1cf2d851','1191db234c19ea11dc9a33d89374c3984a88d576772699cccc1b2e3199ba14d6','e295e303a9d838afa67ef1fd8eed5183f05819b8d4c460016dcd21e95f24d2c9','9f8674b9f4f9e2d90ac7cb5cc3fc98e363f1f6f7181cc2653918289804232b77') -notcontains $sh) { throw ('Другая версия grm_gore_test.script. Изменений нет. SHA256: '+$sh) }
 $eh=Hash $exe
 if ($eh -eq 'ae91b0b55e7e9d80a5dee21213ae4224d6d6809fbe99d1fbac5dd54f8cbbc525') { Write-Host 'Патч уже установлен.'; exit 0 }
 if ($eh -ne '5d52602915fbcbc25798b617a89303117edebb36fefef894ed0abd36e7cd634b') { throw ('Другая версия XR_3DA.exe. Изменений нет. SHA256: '+$eh) }
 if ((Hash $payload) -ne 'ae91b0b55e7e9d80a5dee21213ae4224d6d6809fbe99d1fbac5dd54f8cbbc525') { throw 'Файл патча повреждён. Изменений нет.' }
 $dir=Split-Path -Parent $exe; $tmp=Join-Path $dir ([IO.Path]::GetRandomFileName()+'.tmp'); $bak=Join-Path $dir ([IO.Path]::GetRandomFileName()+'.bak')
 [IO.File]::Copy($payload,$tmp); if ((Hash $tmp) -ne 'ae91b0b55e7e9d80a5dee21213ae4224d6d6809fbe99d1fbac5dd54f8cbbc525') { throw 'Ошибка проверки записи.' }
 [IO.File]::Replace($tmp,$exe,$bak); $replaced=$true
 if ((Hash $exe) -ne 'ae91b0b55e7e9d80a5dee21213ae4224d6d6809fbe99d1fbac5dd54f8cbbc525') { throw 'Ошибка проверки установленного файла.' }
 Remove-Item -LiteralPath $bak -Force -ErrorAction SilentlyContinue; $bak=$null
 Write-Host 'Экспериментальная правка рендера установлена.'
} catch {
 if ($replaced -and $bak -and (Test-Path -LiteralPath $bak)) { try { $discard=Join-Path (Split-Path -Parent $exe) ([IO.Path]::GetRandomFileName()+'.tmp'); [IO.File]::Replace($bak,$exe,$discard); Remove-Item -LiteralPath $discard -Force -ErrorAction SilentlyContinue; $bak=$null } catch { Write-Host ('Исходный файл сохранён: '+$bak) } }
 Write-Host ('ОШИБКА: '+$_.Exception.Message); exit 1
} finally { if ($tmp -and (Test-Path -LiteralPath $tmp)) { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue } }
