param([string]$GameRoot = '')
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding
$before = '3210da596b7fe557e18015a03ebe7686c7643639d8db192ae3149206ee23f2dc'
$after  = '13c22239fa565a4f3da78bf6834497b339e07c23774bcd2e47853d2444899b27'
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
 Write-Host 'ЭКСПЕРИМЕНТ: при переполнении или NULL-источнике игра принудительно завершится без сохранения прогресса.'
 if(@(Get-Process -Name 'XR_3DA*' -ErrorAction SilentlyContinue).Count -gt 0) { throw 'Закройте игру.' }
 if([string]::IsNullOrWhiteSpace($GameRoot)) { $GameRoot=Read-Host 'Путь к корневой папке игры' }
 $GameRoot=[IO.Path]::GetFullPath($GameRoot.Trim().Trim('"'))
 $dll=Join-Path $GameRoot 'bin\xrCore.dll';$exe=Join-Path $GameRoot 'bin\XR_3DA.exe';$game=Join-Path $GameRoot 'bin\xrGame.dll'
 if(!(Test-Path -LiteralPath $dll -PathType Leaf) -or !(Test-Path -LiteralPath $exe -PathType Leaf)){throw 'В указанной папке не найдены bin\xrCore.dll и XR_3DA.exe.'}
 if((Digest ([IO.File]::ReadAllBytes($exe))) -ne $exeHash){throw 'Версия XR_3DA.exe не совпадает. Ничего не изменено.'}
 if(!(Test-Path -LiteralPath $game -PathType Leaf) -or (Digest ([IO.File]::ReadAllBytes($game))) -ne 'b3a74fa6dd45ba5c6306ab5b1971e91c98af87d4ee57f0148823d19dd8b4a432'){throw 'Не найдена точная xrGame.dll от V2. Ничего не изменено.'}
 [byte[]]$old=[IO.File]::ReadAllBytes($dll);$hash=Digest $old
 if($hash -eq $after){Write-Host 'Этот экспериментальный патч уже установлен.';exit 0}
 if($hash -ne $before){throw ('Версия xrCore.dll не совпадает. Ничего не изменено. SHA-256: '+$hash)}
 CheckBytes $old 0xd580 (Hex '568bf18b461c')
 CheckBytes $old 0x200 (Hex '84810200')
 CheckBytes $old 0x28590 (New-Object byte[] 112)
 [byte[]]$data=$old.Clone()
 [Array]::Copy((Hex 'e90bb0010090'),0,$data,0xd580,6)
 [byte[]]$guard=[Convert]::FromBase64String('nGCLVCQshdJ0B4N8JCgAdCCLQRwB0HIZO0EgdgepAAAAgHUNYZ1Wic6LRhzpxU/+/+gAAAAAWC3GkQIAaE1SRwBq//+QvKACAA8L')
 [Array]::Copy($guard,0,$data,0x28590,75)
 [Array]::Copy((Hex '00820200'),0,$data,0x200,4)
 if((Digest $data) -ne $after){throw 'Сборка DLL не прошла контрольный SHA-256. Ничего не изменено.'}
 $backupDir=Join-Path $GameRoot 'GRM_CORE_OVERFLOW_BACKUP'
 [IO.Directory]::CreateDirectory($backupDir) | Out-Null
 $backup=Join-Path $backupDir ('xrCore_'+(Get-Date -Format 'yyyyMMdd_HHmmss')+'_'+[Guid]::NewGuid().ToString('N')+'.dll')
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
 Write-Host 'При обнаруженном переполнении или NULL-источнике процесс будет завершён; проверка валидности указателей не реализована.'
} catch {Write-Host ('ОШИБКА: '+$_.Exception.Message);exit 1}
finally {if($temp -and (Test-Path -LiteralPath $temp)) {Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue}}
