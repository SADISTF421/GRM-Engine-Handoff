$ErrorActionPreference='Stop'
[Console]::OutputEncoding=New-Object System.Text.UTF8Encoding
$root=Split-Path -Parent $PSScriptRoot
function report($rel,$expected){$p=Join-Path $root $rel;if(!(Test-Path -LiteralPath $p -PathType Leaf)){Write-Host ($rel+': отсутствует');return};$h=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant();if($expected -contains $h){Write-Host ($rel+': известный SHA-256 '+$h)}else{Write-Host ($rel+': неизвестный SHA-256 '+$h)}}
report 'bin\XR_3DA.exe' @('ae91b0b55e7e9d80a5dee21213ae4224d6d6809fbe99d1fbac5dd54f8cbbc525')
report 'bin\xrGame.dll' @('7526ad7042e1ad3eead1a89baf15d1ac7be1dcae71bc27db2b0f24010c690d45')
report 'bin\xrGame.pdb' @('ee9f633b9f8a54d900d53877dcd15464a2415a16a122501522729115bc0a0d06')
report 'gamedata\scripts\task_manager.script' @('fdb96acef7e9127e21c13e0795dc5d80086ab00a6512dc28a547575f5b51c84e','51fab23ce33aa62aff415446701c34e37407ef4b28b09ac7c400c9988605f97c')
report 'gamedata\scripts\bind_stalker.script' @('39c907d9f4c215559dfa82e9cc250b9d462930c0b496eafc422bc76c0de19cb9','2a7bba2236092e335d69018b20b748e602a8f4b55c6b7c0682585af995135ba1')
report 'gamedata\scripts\xr_motivator.script' @('47474418ea714dc25c646915af7144eb20f2f98abe6bc415cc5cce0d096a48bc','e1377dc896c2bac0d65682d27844704b54c0edf50115936cf8fefc2852c4407a','5cf24ef2a81dfe4e0a4c178dd0c6c893af3259f028a66df3410641625314e4bb')
report 'gamedata\scripts\grm_gore_test.script' @('92321efd1f41cedb57218b59001bf9bdd63e8eb5dd4a724dd8ae69acaa37f1ee','2f598d7fc6178de3d6b8f8ee813a23c5fbc0598ff3b854de32d295ce9575e85e')
Write-Host 'Совпадение PDB по SHA не подтверждает его пригодность: age PDB отличается от age DLL.'
