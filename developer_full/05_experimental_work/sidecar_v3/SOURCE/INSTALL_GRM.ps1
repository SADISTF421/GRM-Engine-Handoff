$ErrorActionPreference='Stop'
[Console]::OutputEncoding=New-Object System.Text.UTF8Encoding
$game=Split-Path -Parent $PSScriptRoot
function Hash([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
$variants=@'
[{"target":"grm_gore_test.script","variant":"original","old":"92321efd1f41cedb57218b59001bf9bdd63e8eb5dd4a724dd8ae69acaa37f1ee","new":"5317694f11ec0c0f5dc34d8c115ceb88d50c030b7b13345e40e573eeec97e247","payload":"grm_gore_test__original.script"},{"target":"grm_gore_test.script","variant":"previousV3","old":"2f598d7fc6178de3d6b8f8ee813a23c5fbc0598ff3b854de32d295ce9575e85e","new":"c935ce2e63e91f12e177c986c69566c294e061d6468a19762384f3bedf44166f","payload":"grm_gore_test__previousV3.script"},{"target":"bind_stalker.script","variant":"original","old":"39c907d9f4c215559dfa82e9cc250b9d462930c0b496eafc422bc76c0de19cb9","new":"e69913b201b043fd67e290347873a2ecb749222bb73a1c749a30d075fff7649a","payload":"bind_stalker__original.script"},{"target":"bind_stalker.script","variant":"V2","old":"2a7bba2236092e335d69018b20b748e602a8f4b55c6b7c0682585af995135ba1","new":"7adc13c4a425d02521c18030fd7bc6f58a2839db3ba2d0dd3f22ab4f7d177620","payload":"bind_stalker__V2.script"},{"target":"shiza_reznya.script","variant":"original","old":"75b91b5a7e4fc95bbe50a0b06e49f663b6a94f1920c35391dd2d07a011790992","new":"a9be430764b90af4d4f0b90257a55795ab973fa83c81362655b6a2bfc673617f","payload":"shiza_reznya__original.script"},{"target":"sl_rotting.script","variant":"original","old":"4da7c0f58b7dc150c4cd5388f108e95504251fac4172ac9ab08129abd710b4a8","new":"c52523d4ba211bf11e553594c1feaca74392d7e35fe203c200ece621e58ef7f2","payload":"sl_rotting__original.script"}]
'@ | ConvertFrom-Json
$managerHash='35327aae75e40d976e58db6175a605b2fd1dd7ab6f8106859e5f2b91172d7197'
$done=New-Object 'System.Collections.Generic.List[object]';$tmpfiles=New-Object 'System.Collections.Generic.List[string]';$backup=$null;$scripts=$null
try {
 Write-Host 'Сначала сделайте полный бэкап игры и отдельную копию сохранений.'
 if (@(Get-Process -Name 'XR_3DA*' -ErrorAction SilentlyContinue).Count -gt 0){throw 'Закройте игру.'}
 $exe=Join-Path $game 'bin\XR_3DA.exe';$dll=Join-Path $game 'bin\xrGame.dll'
 if(!(Test-Path -LiteralPath $exe -PathType Leaf) -or !(Test-Path -LiteralPath $dll -PathType Leaf)){throw 'Не найдены EXE/DLL в корне игры.'}
 if((Hash $exe) -ne 'ae91b0b55e7e9d80a5dee21213ae4224d6d6809fbe99d1fbac5dd54f8cbbc525' -or (Hash $dll) -ne '7526ad7042e1ad3eead1a89baf15d1ac7be1dcae71bc27db2b0f24010c690d45'){throw 'Неизвестные EXE/DLL: установка остановлена.'}
 $scripts=Join-Path $game 'gamedata\scripts';if(!(Test-Path -LiteralPath $scripts -PathType Container)){throw 'Папка gamedata\scripts не найдена.'}
 $mot=Join-Path $scripts 'xr_motivator.script'
 $knownMot=@('47474418ea714dc25c646915af7144eb20f2f98abe6bc415cc5cce0d096a48bc','e1377dc896c2bac0d65682d27844704b54c0edf50115936cf8fefc2852c4407a','5cf24ef2a81dfe4e0a4c178dd0c6c893af3259f028a66df3410641625314e4bb')
 if(!(Test-Path -LiteralPath $mot -PathType Leaf) -or $knownMot -notcontains (Hash $mot)){throw 'Неизвестный xr_motivator.script: установка остановлена.'}
 $plan=New-Object 'System.Collections.Generic.List[object]'
 foreach($name in @('grm_gore_test.script','bind_stalker.script','shiza_reznya.script','sl_rotting.script')){
  $target=Join-Path $scripts $name;if(!(Test-Path -LiteralPath $target -PathType Leaf)){throw ('Не найден: '+$name)}
  $h=Hash $target;$opts=@($variants | Where-Object {$_.target -eq $name});$installed=@($opts | Where-Object {$_.new -eq $h})
  if($installed.Count -gt 0){Write-Host ($name+': уже установлен');continue}
  $o=@($opts | Where-Object {$_.old -eq $h});if($o.Count -ne 1){throw ('Неизвестный файл: '+$name+' SHA-256 '+$h)};$o=$o[0]
  $src=Join-Path $PSScriptRoot ('payload\'+$o.payload);if(!(Test-Path -LiteralPath $src -PathType Leaf) -or (Hash $src) -ne $o.new){throw ('Ошибка файла патча '+$o.payload)}
  $plan.Add([pscustomobject]@{target=$target;src=$src;old=$o.old;new=$o.new;isNew=$false;name=$name})
 }
 $mgr=Join-Path $scripts 'sl_sidecar_manager.script'
 # Обе копии принимаются только при полном совпадении с эталонным SHA-256.
 $primary=Join-Path $PSScriptRoot 'payload\sl_sidecar_manager.script'
 $alternate=Join-Path $game 'SOURCE\sl_sidecar_manager.script'
 $msrc=$null; $sourceProblems=New-Object 'System.Collections.Generic.List[string]'
 foreach($candidate in @($primary,$alternate)){
  if(!(Test-Path -LiteralPath $candidate -PathType Leaf)){$sourceProblems.Add('нет файла: '+$candidate);continue}
  try {$actual=Hash $candidate} catch {$sourceProblems.Add('ошибка чтения: '+$candidate);continue}
  if($actual -eq $managerHash){$msrc=$candidate;break}
  $sourceProblems.Add('неверный SHA-256: '+$candidate+' = '+$actual)
 }
 if(!$msrc){throw ('Нет проверенной копии менеджера. '+($sourceProblems -join '; ')+'; ожидается SHA-256 '+$managerHash)}
 if($msrc -eq $alternate){Write-Host 'Используется проверенная копия менеджера из SOURCE.'}
 if(Test-Path -LiteralPath $mgr){if(!(Test-Path -LiteralPath $mgr -PathType Leaf) -or (Hash $mgr) -ne $managerHash){throw 'sl_sidecar_manager.script уже существует и отличается.'}else{Write-Host 'Менеджер уже установлен'}}
 else{$plan.Add([pscustomobject]@{target=$mgr;src=$msrc;old='';new=$managerHash;isNew=$true;name='sl_sidecar_manager.script'})}
 $backup=Join-Path (Join-Path $game 'GRM_SIDECAR_V3_BACKUP') ((Get-Date -Format 'yyyyMMdd_HHmmss')+'_'+[Guid]::NewGuid().ToString('N').Substring(0,8));New-Item -ItemType Directory -Force -Path $backup|Out-Null
 # Сначала копии и временные файлы для всех изменений, затем замена.
 foreach($p in $plan){
  if(!$p.isNew){$bak=Join-Path $backup $p.name;[IO.File]::Copy($p.target,$bak,$false);if((Hash $bak) -ne $p.old -or (Hash $p.target) -ne $p.old){throw ('Ошибка копии '+$p.name)}}
  $tmp=Join-Path $scripts ('.grm_sidecar_'+[Guid]::NewGuid().ToString('N')+'.tmp');$tmpfiles.Add($tmp);[IO.File]::Copy($p.src,$tmp,$false);if((Hash $tmp) -ne $p.new){throw ('Ошибка подготовки '+$p.name)}
  $p | Add-Member -NotePropertyName temp -NotePropertyValue $tmp
 }
 foreach($p in $plan){
  if($p.isNew){if(Test-Path -LiteralPath $p.target){throw 'Файл менеджера появился во время установки.'};[IO.File]::Move($p.temp,$p.target)}
  else{if((Hash $p.target) -ne $p.old){throw ('Файл изменился: '+$p.name)};[IO.File]::Replace($p.temp,$p.target,$null,$true)}
  $done.Add($p);if((Hash $p.target) -ne $p.new){throw ('Ошибка проверки '+$p.name)}
  Write-Host ('Установлен: '+$p.name)
 }
 $saved=Join-Path $game 'appdata\savedgames';if(Test-Path -LiteralPath $saved -PathType Container){New-Item -ItemType Directory -Force -Path (Join-Path $saved 'grm_project_data')|Out-Null}
 @('Точные копии заменённых скриптов в этой папке.','sl_sidecar_manager.script — новый файл, его до установки не было.','Проверка IO, автоматическое событие успешного save и восстановление физики отсутствуют.') | Set-Content -LiteralPath (Join-Path $backup 'INSTALL_RESULT.txt') -Encoding UTF8
 Write-Host ('Копии: '+$backup)
 Write-Host 'ВНИМАНИЕ: автоматическая запись sidecar после save и изоляция данных движка НЕ реализованы.'
} catch {
 Write-Host ('ОШИБКА: '+$_.Exception.Message)
 foreach($p in $done){try{
  if((Hash $p.target) -ne $p.new){throw 'Файл изменился после установки'}
  if($p.isNew){[IO.File]::Delete($p.target)}else{$b=Join-Path $backup $p.name;if((Hash $b) -ne $p.old){throw 'Копия не совпадает'};$t=Join-Path $scripts ('.grm_restore_'+[Guid]::NewGuid().ToString('N')+'.tmp');$tmpfiles.Add($t);[IO.File]::Copy($b,$t,$false);[IO.File]::Replace($t,$p.target,$null,$true);if((Hash $p.target) -ne $p.old){throw 'Восстановленный файл не совпал'}}
  Write-Host ('Возвращён исходный файл: '+$p.name)
 }catch{Write-Host ('ПРОВЕРЬТЕ ФАЙЛ И КОПИЮ: '+$p.name+' '+$_.Exception.Message)}}
 exit 1
} finally{foreach($p in $tmpfiles){if(Test-Path -LiteralPath $p){Remove-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue}}}
