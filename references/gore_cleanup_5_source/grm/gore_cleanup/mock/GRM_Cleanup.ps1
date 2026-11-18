$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Split-Path -Parent $MyInvocation.MyCommand.Path))
function Hash([string]$p) { (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLowerInvariant() }
$ss=@(
[pscustomobject]@{old='796b2db67e21ec231fb7455f09da9e0bcabb03b9550aeea663b96d411c8946e9';new='1991e2d5aef2fc382afa851751ab7ad2256e0e725a7ef68bde65ce3ff4d182b6';file='100_popup_old.script'},
[pscustomobject]@{old='f4904a34ac1e79b285f03ff6427df45dd237c989012a16455411566229c53151';new='92321efd1f41cedb57218b59001bf9bdd63e8eb5dd4a724dd8ae69acaa37f1ee';file='50_popup_old.script'},
[pscustomobject]@{old='bbab0c15788ddceab6c87128cc11bba61cb107829425e0e006da46898826af2d';new='1991e2d5aef2fc382afa851751ab7ad2256e0e725a7ef68bde65ce3ff4d182b6';file='100_quiet_old.script'},
[pscustomobject]@{old='62a9340cedda07264ec8696078407ff5f53071993ba716e6b9c82252640b55dc';new='92321efd1f41cedb57218b59001bf9bdd63e8eb5dd4a724dd8ae69acaa37f1ee';file='50_quiet_old.script'},
[pscustomobject]@{old='9d010f7adce860dad994b19c54789a5ea46979e25c7dbc29ec117f6a70594bfd';new='e89e1f29d3c29181caa468b7ed26630c6f933d8b95fc069f81fbeb8a9026a2f6';file='100_corpse_old.script'},
[pscustomobject]@{old='db46e6f60adb172a1ad6d4bb75d1b1625bfc87a15e15074b742a7dd78820025f';new='cc8c2de14433ff926ad7631ac99ba4fe84a1ae5455f8def0e9685c1d3c46fac7';file='50_corpse_old.script'},
[pscustomobject]@{old='e295e303a9d838afa67ef1fd8eed5183f05819b8d4c460016dcd21e95f24d2c9';new='e89e1f29d3c29181caa468b7ed26630c6f933d8b95fc069f81fbeb8a9026a2f6';file='100ms_corpse_transition.script'},
[pscustomobject]@{old='c0fbed884abc839dd4856082fd287141d4aebd04cd061a220ef196bbcb25e0a8';new='1991e2d5aef2fc382afa851751ab7ad2256e0e725a7ef68bde65ce3ff4d182b6';file='100ms_popup_transition.script'},
[pscustomobject]@{old='da4fa7f017f0aca7af1aca8577f75be9d72d9b9f804b97b65f53cfcc1cf2d851';new='1991e2d5aef2fc382afa851751ab7ad2256e0e725a7ef68bde65ce3ff4d182b6';file='100ms_quiet_transition.script'},
[pscustomobject]@{old='9f8674b9f4f9e2d90ac7cb5cc3fc98e363f1f6f7181cc2653918289804232b77';new='cc8c2de14433ff926ad7631ac99ba4fe84a1ae5455f8def0e9685c1d3c46fac7';file='50ms_corpse_transition.script'},
[pscustomobject]@{old='14af0a7b3399f54c980a1dc211b206342f4b2acf46d95c48315d84a015ca1c13';new='92321efd1f41cedb57218b59001bf9bdd63e8eb5dd4a724dd8ae69acaa37f1ee';file='50ms_popup_transition.script'},
[pscustomobject]@{old='1191db234c19ea11dc9a33d89374c3984a88d576772699cccc1b2e3199ba14d6';new='92321efd1f41cedb57218b59001bf9bdd63e8eb5dd4a724dd8ae69acaa37f1ee';file='50ms_quiet_transition.script'}
)
$ds=@(
[pscustomobject]@{old='c5f1968e680b1bef8d000a0a2d37adf343026628994fffcb138fea1c3130e9fb';new='6c6271c680e4d9147f97ff11afc3ac5cc0b20954a889a0136681c22b2aa5751e'},
[pscustomobject]@{old='4a6e84f3397b853124158865bd71b54f9c438d11384bad6a90eaa08c20216959';new='57325ce761e164eb33d20a348567b9fcc3618cd6ea319bff2ff90fd50b27a445'},
[pscustomobject]@{old='969d116337e15a0f5c0af212c8c49ea5262bba3b2d93e4ca7af7ff140e2856d7';new='59e9dea963d3a80c11c1bf24b069d681007f511fb759724562d924052f8de258'},
[pscustomobject]@{old='f59cdeeeb652adcb8f76ec621a32e72552f2037db457e7f3ea3e19633f702fbd';new='e802b4d33a0befcdd9ab36942dc66f1427a5248390e9cf0869b607dfa648a2e1'},
[pscustomobject]@{old='258e6be1b4db929bc915088f485379ec6db86a525690f3ff227da2a091291742';new='eee84088a07565f6cf3314bd43b598abbcce1259c6b7b3293fd737d7485181e7'},
[pscustomobject]@{old='b60bfe6f03a1f085dd7d5bcb1b8771668b24e60ed44d8d2394aa339e78125225';new='7526ad7042e1ad3eead1a89baf15d1ac7be1dcae71bc27db2b0f24010c690d45'},
[pscustomobject]@{old='dd08eeaa462788fd6b00481a987a33c848c9d417f4b4d67781219ebeadcedd71';new='3416517353bdd5181048b502bf5563d9acebbea18d105f9d78a72726e65beffe'},
[pscustomobject]@{old='bf347977fde7ce70d310181c1fc18df78e6d539b5092b218758b1bd7c4cb2e90';new='ff83245fbed905b4e1a28aaad79ad48b44197d594f3723121df07ef0dcf89f43'}
)
$work=@();$success=$false
try {
 [Console]::OutputEncoding=New-Object System.Text.UTF8Encoding
 if (@(Get-Process | Where-Object { $_.ProcessName -like 'XR_3DA*' }).Count -gt 0) { throw 'Закройте игру.' }
 $exe=Join-Path $root 'bin\XR_3DA.exe';$dll=Join-Path $root 'bin\xrGame.dll';$script=Join-Path $root 'gamedata\scripts\grm_gore_test.script'
 foreach ($p in @($exe,$dll,$script)) { if (!(Test-Path -LiteralPath $p -PathType Leaf)) { throw ('Нет файла: '+$p) } }
 if (@('5d52602915fbcbc25798b617a89303117edebb36fefef894ed0abd36e7cd634b','ae91b0b55e7e9d80a5dee21213ae4224d6d6809fbe99d1fbac5dd54f8cbbc525') -notcontains (Hash $exe)) { throw 'Неизвестная версия EXE. Изменений нет.' }
 $sh=Hash $script;$dh=Hash $dll
 $sr=$ss | Where-Object { $_.old -eq $sh -or $_.new -eq $sh } | Select-Object -First 1
 $dr=$ds | Where-Object { $_.old -eq $dh -or $_.new -eq $dh } | Select-Object -First 1
 if (!$sr) { throw ('Неизвестная версия скрипта. SHA256: '+$sh) }
 if (!$dr) { throw ('Неизвестная версия xrGame.dll. SHA256: '+$dh) }
 if ($sh -ne $sr.new) {
  $source=Join-Path $root ('GRM_Cleanup\'+$sr.file)
  if (!(Test-Path -LiteralPath $source -PathType Leaf) -or (Hash $source) -ne $sr.new) { throw 'Нет файла патча либо он повреждён.' }
  $dir=Split-Path -Parent $script; $tmp=Join-Path $dir ([IO.Path]::GetRandomFileName()+'.tmp');$bak=Join-Path $dir ([IO.Path]::GetRandomFileName()+'.bak')
  [IO.File]::Copy($source,$tmp);$work+=,[pscustomobject]@{target=$script;temp=$tmp;backup=$bak;new=$sr.new;done=$false}
 }
 if ($dh -ne $dr.new) {
  [byte[]]$bytes=[IO.File]::ReadAllBytes($dll)
  if ($bytes[0x6038ee] -ne 0x8b -or $bytes[0x6038ef] -ne 0x04 -or $bytes[0x6038f0] -ne 0x24) { throw 'Проверка инструкций DLL не пройдена.' }
  $bytes[0x6038ee]=0xeb; $bytes[0x6038ef]=0x2b
  $dir=Split-Path -Parent $dll; $tmp=Join-Path $dir ([IO.Path]::GetRandomFileName()+'.tmp');$bak=Join-Path $dir ([IO.Path]::GetRandomFileName()+'.bak')
  [IO.File]::WriteAllBytes($tmp,$bytes);$work+=,[pscustomobject]@{target=$dll;temp=$tmp;backup=$bak;new=$dr.new;done=$false}
 }
 foreach ($w in $work) { if ((Hash $w.temp) -ne $w.new) { throw 'Проверка подготовленных файлов не пройдена.' } }
 foreach ($w in $work) { [IO.File]::Replace($w.temp,$w.target,$w.backup);$w.done=$true; if ((Hash $w.target) -ne $w.new) { throw 'Проверка установки не пройдена.' } }
 $success=$true
 foreach ($w in $work) { if (Test-Path -LiteralPath $w.backup) { Remove-Item -LiteralPath $w.backup -Force -ErrorAction SilentlyContinue } }
 Write-Host 'Патч очистки установлен. Если уже установлен, изменений нет.'
} catch {
 Write-Host ('ОШИБКА: '+$_.Exception.Message)
 [array]::Reverse($work)
 foreach ($w in $work) { if ($w.done -and (Test-Path -LiteralPath $w.backup)) { try { $discard=Join-Path (Split-Path -Parent $w.target) ([IO.Path]::GetRandomFileName()+'.tmp');[IO.File]::Replace($w.backup,$w.target,$discard);Remove-Item -LiteralPath $discard -Force -ErrorAction SilentlyContinue } catch { Write-Host ('Исходный файл сохранён: '+$w.backup) } } }
 exit 1
} finally { foreach ($w in $work) { if (Test-Path -LiteralPath $w.temp) { Remove-Item -LiteralPath $w.temp -Force -ErrorAction SilentlyContinue } } }
