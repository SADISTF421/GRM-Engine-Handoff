$ErrorActionPreference='Stop'
[Console]::OutputEncoding=New-Object System.Text.UTF8Encoding
$game=Split-Path -Parent $PSScriptRoot
function Hash([string]$p) { (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant() }
$specs=@(
 [pscustomobject]@{name='grm_gore_test.script';old='92321efd1f41cedb57218b59001bf9bdd63e8eb5dd4a724dd8ae69acaa37f1ee';new='2f598d7fc6178de3d6b8f8ee813a23c5fbc0598ff3b854de32d295ce9575e85e'},
 [pscustomobject]@{name='xr_motivator.script';old='e1377dc896c2bac0d65682d27844704b54c0edf50115936cf8fefc2852c4407a';new='5cf24ef2a81dfe4e0a4c178dd0c6c893af3259f028a66df3410641625314e4bb'}
)
$changed=New-Object 'System.Collections.Generic.List[object]'; $staged=New-Object 'System.Collections.Generic.List[string]'; $backup=$null
try {
 Write-Host 'Сначала сделайте полный бэкап игры и отдельную копию сохранений.'
 if (@(Get-Process -Name 'XR_3DA*' -ErrorAction SilentlyContinue).Count -gt 0) { throw 'Закройте игру.' }
 $exe=Join-Path $game 'bin\XR_3DA.exe'; $dll=Join-Path $game 'bin\xrGame.dll'
 if (!(Test-Path -LiteralPath $exe -PathType Leaf) -or !(Test-Path -LiteralPath $dll -PathType Leaf)) { throw 'Не найдены EXE/DLL в корне игры.' }
 if ((Hash $exe) -ne 'ae91b0b55e7e9d80a5dee21213ae4224d6d6809fbe99d1fbac5dd54f8cbbc525' -or (Hash $dll) -ne '7526ad7042e1ad3eead1a89baf15d1ac7be1dcae71bc27db2b0f24010c690d45') { throw 'Неизвестная версия EXE/DLL: установка остановлена.' }
 $scripts=Join-Path $game 'gamedata\scripts'
 foreach($x in @(@('bind_stalker.script','2a7bba2236092e335d69018b20b748e602a8f4b55c6b7c0682585af995135ba1'),@('task_manager.script','51fab23ce33aa62aff415446701c34e37407ef4b28b09ac7c400c9988605f97c'))) {
  $p=Join-Path $scripts $x[0]; if(!(Test-Path -LiteralPath $p -PathType Leaf) -or (Hash $p) -ne $x[1]) {throw ('Ожидается установленный V2: не совпадает '+$x[0])}
 }
 foreach($s in $specs) {
  $target=Join-Path $scripts $s.name; $src=Join-Path $PSScriptRoot ('payload\'+$s.name)
  if(!(Test-Path -LiteralPath $target -PathType Leaf) -or !(Test-Path -LiteralPath $src -PathType Leaf)) {throw ('Не найден файл '+$s.name)}
  $h=Hash $target
  if($h -ne $s.old -and $h -ne $s.new){throw ('Неизвестная версия '+$s.name+' SHA-256 '+$h)}
  if((Hash $src) -ne $s.new){throw ('Повреждён файл патча '+$s.name)}
 }
 $backup=Join-Path (Join-Path $game 'GRM_V3_BACKUP') ((Get-Date -Format 'yyyyMMdd_HHmmss')+'_'+[Guid]::NewGuid().ToString('N').Substring(0,8))
 New-Item -ItemType Directory -Path $backup -Force | Out-Null
 foreach($s in $specs) {
  $target=Join-Path $scripts $s.name; if((Hash $target) -eq $s.new){Write-Host ($s.name+': уже установлен');continue}
  $src=Join-Path $PSScriptRoot ('payload\'+$s.name);$bak=Join-Path $backup $s.name
  [IO.File]::Copy($target,$bak,$false)
  if((Hash $bak) -ne $s.old -or (Hash $target) -ne $s.old){throw ('Ошибка резервной копии: '+$s.name)}
  $tmp=Join-Path $scripts ('.grm_v3_'+[Guid]::NewGuid().ToString('N')+'.tmp');$staged.Add($tmp)
  [IO.File]::Copy($src,$tmp,$false)
  if((Hash $tmp) -ne $s.new -or (Hash $target) -ne $s.old){throw ('Изменение файла во время подготовки: '+$s.name)}
  [IO.File]::Replace($tmp,$target,$null,$true)
  $changed.Add([pscustomobject]@{target=$target;backup=$bak;old=$s.old;new=$s.new})
  if((Hash $target) -ne $s.new){throw ('Ошибка проверки результата: '+$s.name)}
  Write-Host ($s.name+': установлен; точная копия сохранена')
 }
 @('V3 установлена.','Резервные копии относятся только к заменённым скриптам.','Нет sidecar, автоматического .prev, защиты записи и ремонта .sav.') | Set-Content -LiteralPath (Join-Path $backup 'INSTALL_RESULT.txt') -Encoding UTF8
 Write-Host ('Готово. Точные копии: '+$backup)
 Write-Host 'Sidecar, защитная отмена сохранения и автоматический .prev не реализованы.'
} catch {
 Write-Host ('ОШИБКА: '+$_.Exception.Message)
 foreach($c in $changed) {
  try {
   if((Hash $c.backup) -ne $c.old -or (Hash $c.target) -ne $c.new){throw 'Хэш изменился: восстановление не выполнялось'}
   $r=Join-Path $scripts ('.grm_restore_'+[Guid]::NewGuid().ToString('N')+'.tmp');$staged.Add($r);[IO.File]::Copy($c.backup,$r,$false);[IO.File]::Replace($r,$c.target,$null,$true)
   if((Hash $c.target) -ne $c.old){throw 'Проверка восстановления не пройдена'}
   Write-Host ('Восстановлен: '+$c.target)
  } catch {Write-Host ('ПРОВЕРЬТЕ КОПИЮ '+$c.backup+': '+$_.Exception.Message)}
 }
 exit 1
} finally { foreach($p in $staged){if(Test-Path -LiteralPath $p){Remove-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue}} }
