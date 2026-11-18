$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Split-Path -Parent $MyInvocation.MyCommand.Path))
function Hash([string]$p) { return (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLowerInvariant() }
function Install-One([string]$target,[string]$payload,[string]$expected) {
 $dir=Split-Path -Parent $target; $tmp=Join-Path $dir ([IO.Path]::GetRandomFileName()+'.tmp'); $bak=Join-Path $dir ([IO.Path]::GetRandomFileName()+'.bak'); $replaced=$false
 try {
  if ((Hash $payload) -ne $expected) { throw 'Файл патча повреждён.' }
  [IO.File]::Copy($payload,$tmp)
  if ((Hash $tmp) -ne $expected) { throw 'Ошибка проверки записи.' }
  [IO.File]::Replace($tmp,$target,$bak); $replaced=$true
  if ((Hash $target) -ne $expected) { throw 'Ошибка проверки установленного файла.' }
  Remove-Item -LiteralPath $bak -Force -ErrorAction SilentlyContinue; $bak=$null
 } catch {
  if ($replaced -and $bak -and (Test-Path -LiteralPath $bak)) {
   try { $discard=Join-Path $dir ([IO.Path]::GetRandomFileName()+'.tmp'); [IO.File]::Replace($bak,$target,$discard); Remove-Item -LiteralPath $discard -Force -ErrorAction SilentlyContinue; $bak=$null }
   catch { Write-Host ('Исходный файл находится здесь: '+$bak) }
  }; throw
 } finally { if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue } }
}
try {
 [Console]::OutputEncoding=New-Object System.Text.UTF8Encoding
 if (@(Get-Process | Where-Object { $_.ProcessName -like 'XR_3DA*' }).Count -gt 0) { throw 'Закройте игру.' }
 $exe=Join-Path $root 'bin\XR_3DA.exe'; $dll=Join-Path $root 'bin\xrGame.dll'
 foreach ($f in @($exe,$dll)) { if (!(Test-Path -LiteralPath $f -PathType Leaf)) { throw ('Не найден: '+$f+'. Распакуйте архив в папку игры.') } }
 if ((Hash $exe) -ne '5d52602915fbcbc25798b617a89303117edebb36fefef894ed0abd36e7cd634b') { throw 'Другая версия EXE.' }
 if (@('c5f1968e680b1bef8d000a0a2d37adf343026628994fffcb138fea1c3130e9fb','4a6e84f3397b853124158865bd71b54f9c438d11384bad6a90eaa08c20216959') -notcontains (Hash $dll)) { throw 'Другая версия xrGame.dll.' }
 $specs = @(
  [pscustomobject]@{target='grm_gore_test.script';old='796b2db67e21ec231fb7455f09da9e0bcabb03b9550aeea663b96d411c8946e9';new='bbab0c15788ddceab6c87128cc11bba61cb107829425e0e006da46898826af2d';file='gore0.script'},
  [pscustomobject]@{target='grm_gore_test.script';old='f4904a34ac1e79b285f03ff6427df45dd237c989012a16455411566229c53151';new='62a9340cedda07264ec8696078407ff5f53071993ba716e6b9c82252640b55dc';file='gore1.script'},
  [pscustomobject]@{target='bind_stalker.script';old='5f2fad111f6bfbca338a681e507afdf475280682af4469a71ddc538364dd4af5';new='0d1831225e5beb4a6d4b307e2c7acc20ba32d34be366dbd84aee621576b0ace5';file='binder0.script'},
  [pscustomobject]@{target='bind_stalker.script';old='09a83a00c28c0180e0edcb7e93df8daaa037bfcf6f9b81506f5699360415a1fb';new='39c907d9f4c215559dfa82e9cc250b9d462930c0b496eafc422bc76c0de19cb9';file='binder1.script'}
 )
 foreach ($name in @('grm_gore_test.script','bind_stalker.script')) {
  $target=Join-Path $root ('gamedata\scripts\'+$name)
  if (!(Test-Path -LiteralPath $target -PathType Leaf)) { Write-Host ($name+': файл не найден, пропущен.'); continue }
  $hash=Hash $target; $choices=@($specs | Where-Object { $_.target -eq $name }); $done=$false
  foreach ($c in $choices) { if ($hash -eq $c.new) { Write-Host ($name+': уже установлен.'); $done=$true; break } }
  if ($done) { continue }
  $entry=$choices | Where-Object { $_.old -eq $hash } | Select-Object -First 1
  if (!$entry) { Write-Host ($name+': неизвестная версия, пропущен. SHA256: '+$hash); continue }
  $payload=Join-Path $root ('GRM_CleanDiag\'+$entry.file)
  if (!(Test-Path -LiteralPath $payload -PathType Leaf)) { throw ('Не найден файл патча: '+$payload) }
  Install-One $target $payload $entry.new
  Write-Host ($name+': установлен.')
 }
} catch { Write-Host ('ОШИБКА: '+$_.Exception.Message); exit 1 }
