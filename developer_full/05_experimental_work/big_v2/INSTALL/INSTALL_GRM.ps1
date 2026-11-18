$ErrorActionPreference='Stop'
[Console]::OutputEncoding=New-Object System.Text.UTF8Encoding
$game=Split-Path -Parent $PSScriptRoot
function Hash([string]$p) { (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant() }
$specs=@(
 [pscustomobject]@{name='task_manager.script';old='fdb96acef7e9127e21c13e0795dc5d80086ab00a6512dc28a547575f5b51c84e';new='51fab23ce33aa62aff415446701c34e37407ef4b28b09ac7c400c9988605f97c'},
 [pscustomobject]@{name='bind_stalker.script';old='39c907d9f4c215559dfa82e9cc250b9d462930c0b496eafc422bc76c0de19cb9';new='2a7bba2236092e335d69018b20b748e602a8f4b55c6b7c0682585af995135ba1'},
 [pscustomobject]@{name='xr_motivator.script';old='47474418ea714dc25c646915af7144eb20f2f98abe6bc415cc5cce0d096a48bc';new='e1377dc896c2bac0d65682d27844704b54c0edf50115936cf8fefc2852c4407a'}
)
$log=New-Object 'System.Collections.Generic.List[string]'
$fail=0; $changed=0; $unchanged=0
try {
 Write-Host 'Сначала сделайте полный бэкап игры и отдельную копию сохранений.'
 if (@(Get-Process -Name 'XR_3DA*' -ErrorAction SilentlyContinue).Count -gt 0) { throw 'Закройте игру.' }
 $exe=Join-Path $game 'bin\XR_3DA.exe';$dll=Join-Path $game 'bin\xrGame.dll';$pdb=Join-Path $game 'bin\xrGame.pdb'
 $known=$false
 if ((Test-Path -LiteralPath $exe -PathType Leaf) -and (Test-Path -LiteralPath $dll -PathType Leaf)) {
  $eh=Hash $exe;$dh=Hash $dll
  $known=($eh -eq 'ae91b0b55e7e9d80a5dee21213ae4224d6d6809fbe99d1fbac5dd54f8cbbc525' -and $dh -eq '7526ad7042e1ad3eead1a89baf15d1ac7be1dcae71bc27db2b0f24010c690d45')
  if ($known) {
   $fs=[IO.File]::OpenRead($dll)
   try { foreach($o in @(0x7285e,0x728b5)) { $fs.Position=$o; $b=New-Object byte[] 7; if($fs.Read($b,0,7) -ne 7 -or [BitConverter]::ToString($b) -ne '8B-84-24-18-20-00-00') { $known=$false } } } finally { $fs.Dispose() }
  }
 }
 if (-not $known) { $log.Add('Движок отличается или не найден; engine-патч не применялся. Скрипты сверяются отдельно.') }
 else { $log.Add('EXE/DLL и две контрольные последовательности совпали; engine-патч отсутствует и не применялся.') }
 if ((Test-Path -LiteralPath $pdb -PathType Leaf) -and (Hash $pdb) -eq 'ee9f633b9f8a54d900d53877dcd15464a2415a16a122501522729115bc0a0d06') { $log.Add('PDB совпал с предоставленным файлом; возраст PDB не совпадает с DLL, символы не подтверждены.') }
 else { $log.Add('PDB отличается или отсутствует; для скриптовой части не требуется.') }
 $broot=Join-Path $game 'GRM_BIG_GUARD_BACKUP'
 $backup=Join-Path $broot ((Get-Date -Format 'yyyyMMdd_HHmmss')+'_'+[Guid]::NewGuid().ToString('N').Substring(0,8))
 New-Item -ItemType Directory -Path $backup -Force | Out-Null
 foreach($s in $specs) {
  $target=Join-Path $game ('gamedata\scripts\'+$s.name);$src=Join-Path $PSScriptRoot ('payload\'+$s.name)
  try {
   if (!(Test-Path -LiteralPath $target -PathType Leaf)) { throw 'целевой файл отсутствует' }
   $h=Hash $target
   if($h -eq $s.new) { $unchanged++; $log.Add($s.name+': уже установлен');continue }
   if($h -ne $s.old) { throw ('неизвестный SHA-256 '+$h) }
   if (!(Test-Path -LiteralPath $src -PathType Leaf) -or (Hash $src) -ne $s.new) { throw 'файл патча отсутствует или повреждён' }
   $dir=Split-Path -Parent $target;$tmp=Join-Path $dir ('.grm_'+[Guid]::NewGuid().ToString('N')+'.tmp');$bak=Join-Path $backup $s.name
   try {
    [IO.File]::Copy($src,$tmp,$false)
    if((Hash $tmp) -ne $s.new -or (Hash $target) -ne $s.old) { throw 'проверка временного или исходного файла не пройдена' }
    [IO.File]::Replace($tmp,$target,$bak,$true)
    if((Hash $target) -ne $s.new -or (Hash $bak) -ne $s.old) {
     if(Test-Path -LiteralPath $bak) { $discard=Join-Path $dir ('.grm_failed_'+[Guid]::NewGuid().ToString('N')+'.tmp');[IO.File]::Replace($bak,$target,$discard,$true);Remove-Item -LiteralPath $discard -Force -ErrorAction SilentlyContinue }
     throw 'проверка после замены не пройдена; проверяйте копию в BACKUP'
    }
    $changed++;$log.Add($s.name+': установлен, точная копия создана')
   } finally { if($tmp -and (Test-Path -LiteralPath $tmp)) { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue } }
  } catch { $fail++;$log.Add($s.name+': ПРОПУЩЕН/ОШИБКА: '+$_.Exception.Message) }
 }
 $log | Set-Content -LiteralPath (Join-Path $backup 'INSTALL_RESULT.txt') -Encoding UTF8
 foreach($l in $log){Write-Host $l}
 Write-Host ('Изменено: '+$changed+'; уже установлено: '+$unchanged+'; пропущено/ошибка: '+$fail)
 Write-Host ('Точные копии и журнал: '+$backup)
 Write-Host 'Защита обеих стадий и атомарное сохранение НЕ реализованы.'
 if($fail -gt 0){exit 1}
} catch { Write-Host ('ОШИБКА: '+$_.Exception.Message);exit 1 }
