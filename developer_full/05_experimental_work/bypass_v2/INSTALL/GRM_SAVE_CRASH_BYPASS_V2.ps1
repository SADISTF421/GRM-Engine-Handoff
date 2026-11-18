param([string]$GameRoot = '')
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding
$before = '3a1ac31b52efd39965c89c5e43347e4e059adfcfb7cd6a16f85bc05f0716528b'
$after  = 'b3a74fa6dd45ba5c6306ab5b1971e91c98af87d4ee57f0148823d19dd8b4a432'
$exeHash = 'ae91b0b55e7e9d80a5dee21213ae4224d6d6809fbe99d1fbac5dd54f8cbbc525'
$temp = $null
function Digest([byte[]]$b) {
 $s=[Security.Cryptography.SHA256]::Create()
 try { return ([BitConverter]::ToString($s.ComputeHash($b))).Replace('-','').ToLowerInvariant() } finally { $s.Dispose() }
}
function Hex([string]$h) {
 [byte[]]$r=New-Object byte[] ($h.Length/2)
 for($i=0;$i -lt $r.Length;$i++) { $r[$i]=[Convert]::ToByte($h.Substring($i*2,2),16) }
 return ,$r
}
function CheckBytes([byte[]]$b,[int]$off,[byte[]]$expected) {
 if ($off -lt 0 -or $b.Length -lt $off+$expected.Length) { throw 'Некорректная длина DLL.' }
 for($i=0;$i -lt $expected.Length;$i++) { if($b[$off+$i] -ne $expected[$i]) { throw ('Несовпадение байтов: 0x{0:X}' -f ($off+$i)) } }
}
try {
 Write-Host 'Перед установкой сделайте полный бэкап игры и отдельную копию всех сохранений.'
 Write-Host 'ЭКСПЕРИМЕНТ: пропуск объекта может создать неполный или повреждённый сейв.'
 if(@(Get-Process -Name 'XR_3DA*' -ErrorAction SilentlyContinue).Count -gt 0) { throw 'Закройте игру.' }
 if([string]::IsNullOrWhiteSpace($GameRoot)) { $GameRoot=Read-Host 'Путь к корневой папке игры' }
 $GameRoot=[IO.Path]::GetFullPath($GameRoot.Trim().Trim('"'))
 $dll=Join-Path $GameRoot 'bin\xrGame.dll';$exe=Join-Path $GameRoot 'bin\XR_3DA.exe'
 if(!(Test-Path -LiteralPath $dll -PathType Leaf) -or !(Test-Path -LiteralPath $exe -PathType Leaf)){throw 'В указанной папке не найдены bin\xrGame.dll и XR_3DA.exe.'}
 if((Digest ([IO.File]::ReadAllBytes($exe))) -ne $exeHash){throw 'Версия XR_3DA.exe не совпадает. Ничего не изменено.'}
 [byte[]]$old=[IO.File]::ReadAllBytes($dll);$hash=Digest $old
 if($hash -eq $after){Write-Host 'Этот экспериментальный патч уже установлен.';exit 0}
 if($hash -ne $before){throw ('Версия xrGame.dll не совпадает. Ничего не изменено. SHA-256: '+$hash)}
 CheckBytes $old 0x729a0 (Hex 'e99bc35a00')
 CheckBytes $old 0x2c0 (Hex '52090000')
 CheckBytes $old 0x603e00 (New-Object byte[] 280)
 [byte[]]$data=$old.Clone()
 [Array]::Copy((Hex 'e95bc45a00'),0,$data,0x729a0,5)
 [byte[]]$guard=[Convert]::FromBase64String('nGDoAAAAAF2B7Qf6YQCLXhCF23ROidi6BAAAADHJ6EcAAACFwHQ8izuJ+LqkAAAAuQEAAADoMAAAAIXAdCWLh6AAAAC6AQAAALkCAAAA6BcAAACFwHQMYZ2LThCLAelCO6X/YZ3pYzul/1NWV4PsHInGideJy2ocjUQkBFBW/5UcYEYAg/gcD4WCAAAAgXwkEAAQAAB1eItEJBSpAQEAAHVtJf8AAACD+wJ0IoP4AnQzg/gEdC6D+Ah0KYP4IHQkg/hAdB89gAAAAHQY60GD+BB0EYP4IHQMg/hAdAc9gAAAAHUrhdt0CoF8JBgAAAABdR2F/3QZTwH3chSLBCQDRCQMcgs5x3MHuAEAAADrAjHAg8QcX15bww==')
 [Array]::Copy($guard,0,$data,0x603e00,280)
 [Array]::Copy((Hex '180b0000'),0,$data,0x2c0,4)
 if((Digest $data) -ne $after){throw 'Сборка DLL не прошла контрольный SHA-256. Ничего не изменено.'}
 $backupDir=Join-Path $GameRoot 'GRM_SAVE_CRASH_BYPASS_V2_BACKUP'
 [IO.Directory]::CreateDirectory($backupDir) | Out-Null
 $backup=Join-Path $backupDir ('xrGame_'+(Get-Date -Format 'yyyyMMdd_HHmmss')+'_'+[Guid]::NewGuid().ToString('N')+'.dll')
 [IO.File]::Copy($dll,$backup,$false)
 if((Digest ([IO.File]::ReadAllBytes($backup))) -ne $before) {throw 'Контроль копии DLL не пройден. DLL не изменена.'}
 $temp=Join-Path (Split-Path -Parent $dll) ([Guid]::NewGuid().ToString('N')+'.tmp')
 $stream=New-Object IO.FileStream($temp,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 try {$stream.Write($data,0,$data.Length);$stream.Flush($true)} finally {$stream.Dispose()}
 if((Digest ([IO.File]::ReadAllBytes($temp))) -ne $after){throw 'Контроль временной DLL не пройден.'}
 if((Digest ([IO.File]::ReadAllBytes($dll))) -ne $before){throw 'DLL изменилась во время работы. Ничего не заменено.'}
 if(@(Get-Process -Name 'XR_3DA*' -ErrorAction SilentlyContinue).Count -gt 0){throw 'Игра запущена. Ничего не заменено.'}
 [IO.File]::Replace($temp,$dll,$null);$temp=$null
 if((Digest ([IO.File]::ReadAllBytes($dll))) -ne $after){throw ('Ошибка контроля установленной DLL. Копия: '+$backup)}
 Write-Host ('Готово. Исходная DLL скопирована: '+$backup)
 Write-Host 'Проверяются только страницы объекта и vtable, не время жизни; от переполнения защиты нет.'
} catch {Write-Host ('ОШИБКА: '+$_.Exception.Message);exit 1}
finally {if($temp -and (Test-Path -LiteralPath $temp)) {Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue}}
