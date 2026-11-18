param([Parameter(Position=0)][string]$Path)
$ErrorActionPreference='Stop'
[Console]::OutputEncoding=New-Object System.Text.UTF8Encoding
try {
 if([string]::IsNullOrWhiteSpace($Path) -or !(Test-Path -LiteralPath $Path -PathType Leaf)) { throw 'Передайте путь к .sav или перетащите файл на BAT.' }
 $f=Get-Item -LiteralPath $Path
 if($f.Length -lt 13) { throw 'Файл короче заголовка и сжатого содержимого.' }
 $s=[IO.File]::Open($f.FullName,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
 try { $b=New-Object byte[] 12;if($s.Read($b,0,12) -ne 12){throw 'Заголовок усечён.'} } finally { $s.Dispose() }
 $sig=[BitConverter]::ToUInt32($b,0);$ver=[BitConverter]::ToUInt32($b,4);$size=[BitConverter]::ToUInt32($b,8)
 if($sig -ne [uint32]::MaxValue){throw 'Нет ожидаемого маркера SoC.'}
 if($size -eq 0 -or $size -gt 536870912){throw 'Недопустимый или подозрительный объявленный размер.'}
 Write-Host ('Файл: '+$f.Name+'; размер: '+$f.Length+'; SHA-256: '+(Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash)
 Write-Host ('Заголовок похож на SoC. Версия: '+$ver+'; распакованный размер: '+$size)
 Write-Host 'НЕПОЛНАЯ ПРОВЕРКА: LZO, чанки, объекты, задачи, физика, звук и загрузка НЕ проверены.'
 Write-Host 'Это не подтверждение исправности и не разрешение на замену рабочего сейва.'
 exit 2
} catch { Write-Host ('ОШИБКА ЗАГОЛОВКА: '+$_.Exception.Message);exit 1 }
