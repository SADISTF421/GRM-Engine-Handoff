$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Split-Path -Parent $MyInvocation.MyCommand.Path))
function Hash([string]$p) { return (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLowerInvariant() }
$entries=@(
 [pscustomobject]@{target='bin\xrGame.dll';old='c5f1968e680b1bef8d000a0a2d37adf343026628994fffcb138fea1c3130e9fb';new='969d116337e15a0f5c0af212c8c49ea5262bba3b2d93e4ca7af7ff140e2856d7';file='engine0.dll'},
 [pscustomobject]@{target='bin\xrGame.dll';old='4a6e84f3397b853124158865bd71b54f9c438d11384bad6a90eaa08c20216959';new='f59cdeeeb652adcb8f76ec621a32e72552f2037db457e7f3ea3e19633f702fbd';file='engine1.dll'},
 [pscustomobject]@{target='gamedata\scripts\xr_motivator.script';old='70213e46b6a60b54befd23581f6998aeb27b51910424e9b7a692c0eabe8ba9c8';new='cc39221b2fb38bd844058dbdec2dd7b8828063343a32e55022bdb83ac3ea3915';file='motivator.script'},
 [pscustomobject]@{target='gamedata\scripts\grm_gore_test.script';old='bbab0c15788ddceab6c87128cc11bba61cb107829425e0e006da46898826af2d';new='9d010f7adce860dad994b19c54789a5ea46979e25c7dbc29ec117f6a70594bfd';file='gore0.script'},
 [pscustomobject]@{target='gamedata\scripts\grm_gore_test.script';old='796b2db67e21ec231fb7455f09da9e0bcabb03b9550aeea663b96d411c8946e9';new='9d010f7adce860dad994b19c54789a5ea46979e25c7dbc29ec117f6a70594bfd';file='gore0.script'},
 [pscustomobject]@{target='gamedata\scripts\grm_gore_test.script';old='62a9340cedda07264ec8696078407ff5f53071993ba716e6b9c82252640b55dc';new='db46e6f60adb172a1ad6d4bb75d1b1625bfc87a15e15074b742a7dd78820025f';file='gore1.script'},
 [pscustomobject]@{target='gamedata\scripts\grm_gore_test.script';old='f4904a34ac1e79b285f03ff6427df45dd237c989012a16455411566229c53151';new='db46e6f60adb172a1ad6d4bb75d1b1625bfc87a15e15074b742a7dd78820025f';file='gore1.script'}
)
$changes=New-Object System.Collections.ArrayList
try {
 [Console]::OutputEncoding=New-Object System.Text.UTF8Encoding
 if (@(Get-Process | Where-Object { $_.ProcessName -like 'XR_3DA*' }).Count -gt 0) { throw 'Закройте игру.' }
 $exe=Join-Path $root 'bin\XR_3DA.exe'
 if (!(Test-Path -LiteralPath $exe -PathType Leaf) -or (Hash $exe) -ne '5d52602915fbcbc25798b617a89303117edebb36fefef894ed0abd36e7cd634b') { throw 'EXE не совпадает. Файлы не изменены.' }
 foreach ($name in @('bin\xrGame.dll','gamedata\scripts\xr_motivator.script','gamedata\scripts\grm_gore_test.script')) {
  $target=Join-Path $root $name
  if (!(Test-Path -LiteralPath $target -PathType Leaf)) { throw ('Нет файла: '+$name) }
  $hash=Hash $target; $choices=@($entries | Where-Object { $_.target -eq $name })
  if (@($choices | Where-Object { $_.new -eq $hash }).Count -gt 0) { continue }
  $entry=$choices | Where-Object { $_.old -eq $hash } | Select-Object -First 1
  if (!$entry) { throw ('Неизвестная версия: '+$name+' SHA256: '+$hash) }
  $payload=Join-Path $root ('GRM_Corpse\'+$entry.file)
  if (!(Test-Path -LiteralPath $payload -PathType Leaf) -or (Hash $payload) -ne $entry.new) { throw ('Повреждён файл патча: '+$entry.file) }
  $dir=Split-Path -Parent $target
  $tmp=Join-Path $dir ([IO.Path]::GetRandomFileName()+'.tmp')
  $bak=Join-Path $dir ([IO.Path]::GetRandomFileName()+'.bak')
  [void]$changes.Add([pscustomobject]@{target=$target;payload=$payload;expected=$entry.new;tmp=$tmp;bak=$bak;replaced=$false})
 }
 foreach ($c in $changes) { [IO.File]::Copy($c.payload,$c.tmp); if ((Hash $c.tmp) -ne $c.expected) { throw 'Ошибка проверки временного файла.' } }
 foreach ($c in $changes) { [IO.File]::Replace($c.tmp,$c.target,$c.bak); $c.replaced=$true; if ((Hash $c.target) -ne $c.expected) { throw 'Ошибка проверки установленного файла.' } }
 foreach ($c in $changes) { if (Test-Path -LiteralPath $c.bak) { Remove-Item -LiteralPath $c.bak -Force -ErrorAction SilentlyContinue } }
 Write-Host 'Готово. Проверяйте в игре на копии сохранения.'
} catch {
 Write-Host ('ОШИБКА: '+$_.Exception.Message)
 for ($i=$changes.Count-1; $i -ge 0; $i--) { $c=$changes[$i]; if ($c.replaced -and (Test-Path -LiteralPath $c.bak)) { try { $discard=Join-Path (Split-Path -Parent $c.target) ([IO.Path]::GetRandomFileName()+'.tmp'); [IO.File]::Replace($c.bak,$c.target,$discard); Remove-Item -LiteralPath $discard -Force -ErrorAction SilentlyContinue } catch { Write-Host ('Исходный файл: '+$c.bak) } } }
 exit 1
} finally { foreach ($c in $changes) { if (Test-Path -LiteralPath $c.tmp) { Remove-Item -LiteralPath $c.tmp -Force -ErrorAction SilentlyContinue } } }
