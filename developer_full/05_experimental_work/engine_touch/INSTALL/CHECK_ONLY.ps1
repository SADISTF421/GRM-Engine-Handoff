param([Parameter(Mandatory=$true)][string]$GameRoot)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding
try {
 $dll = Join-Path $GameRoot 'bin\xrGame.dll'
 if (!(Test-Path -LiteralPath $dll -PathType Leaf)) { throw 'Не найдена bin\xrGame.dll.' }
 $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $dll).Hash.ToLowerInvariant()
 $expected = '7526ad7042e1ad3eead1a89baf15d1ac7be1dcae71bc27db2b0f24010c690d45'
 if ($hash -ne $expected) { Write-Host 'DLL отличается от анализируемой. Движковая часть пропущена.'; exit 2 }
 $b = [IO.File]::ReadAllBytes($dll)
 foreach ($o in @(0x7285e,0x728b5)) {
   $expectedBytes = [byte[]](0x8b,0x84,0x24,0x18,0x20,0x00,0x00)
   if ($b.Length -lt ($o + $expectedBytes.Length)) { throw 'Усечённый файл.' }
   for ($i=0; $i -lt $expectedBytes.Length; $i++) { if ($b[$o+$i] -ne $expectedBytes[$i]) { throw 'Контрольные байты не совпали.' } }
 }
 Write-Host 'Контроль SHA-256 и двух последовательностей пройден. Движковая часть отсутствует и не установлена.'
 Write-Host 'Этот сценарий ничего не изменяет и не устанавливает защиту сейвов.'
} catch { Write-Host ('Ошибка проверки: '+$_.Exception.Message); exit 1 }
