from pathlib import Path
p=Path('/data/grm/enginefix/package')
script=r'''$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$target = Join-Path $root 'bin\xrGame.dll'
$exe = Join-Path $root 'bin\XR_3DA.exe'
$temp = $null
function Get-Sha256([byte[]]$bytes) {
    $alg = [System.Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($alg.ComputeHash($bytes))).Replace('-', '').ToLowerInvariant() }
    finally { $alg.Dispose() }
}
function Convert-Hex([string]$value) {
    $result = New-Object byte[] ($value.Length / 2)
    for ($i = 0; $i -lt $result.Length; $i++) { $result[$i] = [Convert]::ToByte($value.Substring($i * 2, 2), 16) }
    return ,$result
}
try {
    [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding
    if (@(Get-Process | Where-Object { $_.ProcessName -like 'XR_3DA*' }).Count -gt 0) { throw 'Закройте игру перед установкой.' }
    if (!(Test-Path -LiteralPath $target -PathType Leaf) -or !(Test-Path -LiteralPath $exe -PathType Leaf)) { throw 'Распакуйте архив в папку игры, рядом с папкой bin.' }
    $expectedExe = '5d52602915fbcbc25798b617a89303117edebb36fefef894ed0abd36e7cd634b'
    $expectedOriginal = '15a71719936493aeb534538e12b74235baded7466f7b1d9e4b0defee46716751'
    $expectedPatched = '9bdbf1265882862b2f3df0edc638798d1c8c21381f5e9ca54015aa44c5ec8668'
    if ((Get-Sha256 ([IO.File]::ReadAllBytes($exe))) -ne $expectedExe) { throw 'Версия XR_3DA.exe отличается. Ничего не изменено.' }
    [byte[]]$bytes = [IO.File]::ReadAllBytes($target)
    $hash = Get-Sha256 $bytes
    if ($hash -eq $expectedPatched) { Write-Host 'Патч уже установлен.'; exit 0 }
    if ($hash -ne $expectedOriginal) { throw 'Версия xrGame.dll отличается. Ничего не изменено.' }
    [byte[]]$first = Convert-Hex '8b81ac00000085c0740531d2895004e9ceb32c00cccccccccccccccccccccccc'
    [byte[]]$second = Convert-Hex '8b81ac00000085c0741031d28950048991ac000000e9a2b32c00c3cccccccccc'
    [byte[]]$reloc = Convert-Hex '0f092f09'
    [Array]::Copy($first, 0, $bytes, 0x192d00, $first.Length)
    [Array]::Copy($second, 0, $bytes, 0x192d20, $second.Length)
    [Array]::Copy($reloc, 0, $bytes, 0x57e9aa, $reloc.Length)
    if ((Get-Sha256 $bytes) -ne $expectedPatched) { throw 'Проверка патча не пройдена. Ничего не изменено.' }
    $temp = Join-Path (Split-Path -Parent $target) ([IO.Path]::GetRandomFileName())
    [IO.File]::WriteAllBytes($temp, $bytes)
    if ((Get-Sha256 ([IO.File]::ReadAllBytes($temp))) -ne $expectedPatched) { throw 'Проверка записи не пройдена. Ничего не изменено.' }
    [IO.File]::Replace($temp, $target, $null)
    $temp = $null
    Write-Host 'Патч движка установлен. Скрипты и эффекты не менялись.'
} catch {
    Write-Host ('ОШИБКА: ' + $_.Exception.Message)
    exit 1
} finally {
    if ($temp -and (Test-Path -LiteralPath $temp)) { Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue }
}
'''
(p/'GRM_Engine_Particles_TEST.ps1').write_text(script,encoding='utf-8-sig',newline='\r\n')
(p/'INSTALL_GRM_Engine_TEST.bat').write_bytes(b'@echo off\r\nchcp 65001 >nul\r\npowershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0GRM_Engine_Particles_TEST.ps1"\r\npause\r\n')
