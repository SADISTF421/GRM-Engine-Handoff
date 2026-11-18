from pathlib import Path
import base64,struct
p=Path('/data/grm/savediag'); hook=base64.b64encode((p/'hook.bin').read_bytes()).decode()
def call(a):return (b'\xe8'+struct.pack('<i',0x1061f200-a-5)+b'\x90\x90').hex()
s=r'''$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Split-Path -Parent $MyInvocation.MyCommand.Path))
$target = Join-Path $root 'bin\xrGame.dll'
$exe = Join-Path $root 'bin\XR_3DA.exe'
$temp = $null
$backup = $null
function Hash([byte[]]$data) {
    $a = [Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($a.ComputeHash($data))).Replace('-','').ToLowerInvariant() }
    finally { $a.Dispose() }
}
function Hex([string]$text) {
    $result = New-Object byte[] ($text.Length / 2)
    for ($i = 0; $i -lt $result.Length; $i++) { $result[$i] = [Convert]::ToByte($text.Substring($i * 2, 2), 16) }
    return ,$result
}
function Put([byte[]]$dest, [int]$offset, [byte[]]$part) { [Array]::Copy($part, 0, $dest, $offset, $part.Length) }
try {
    [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding
    if (@(Get-Process | Where-Object { $_.ProcessName -like 'XR_3DA*' }).Count -gt 0) { throw 'Закройте игру перед установкой.' }
    if (!(Test-Path -LiteralPath $target -PathType Leaf) -or !(Test-Path -LiteralPath $exe -PathType Leaf)) { throw 'Распакуйте архив в папку игры рядом с папкой bin.' }
    if ((Hash ([IO.File]::ReadAllBytes($exe))) -ne '5d52602915fbcbc25798b617a89303117edebb36fefef894ed0abd36e7cd634b') { throw 'Версия XR_3DA.exe отличается. Ничего не изменено.' }
    [byte[]]$old = [IO.File]::ReadAllBytes($target)
    $oldhash = Hash $old
    $sourceA = '15a71719936493aeb534538e12b74235baded7466f7b1d9e4b0defee46716751'
    $sourceB = '9bdbf1265882862b2f3df0edc638798d1c8c21381f5e9ca54015aa44c5ec8668'
    $newA = '18ee5800ce2bdfb3dfb912ccb108148626a9ad3dd04cae40ca35d9d85d77c827'
    $newB = 'f927a2f5fee2e57b848730e23c7e0bcebe2b9478859d618293835abcbf8be01a'
    if ($oldhash -eq $newA -or $oldhash -eq $newB) { Write-Host 'Диагностика уже установлена.'; exit 0 }
    if ($oldhash -eq $sourceA) { $expected = $newA }
    elseif ($oldhash -eq $sourceB) { $expected = $newB }
    else { throw 'Версия xrGame.dll отличается. Ничего не изменено.' }
    [byte[]]$data = New-Object byte[] ($old.Length + 512)
    [Array]::Copy($old, $data, $old.Length)
    Put $data 0x2c0 (Hex '61020000')
    Put $data 0x2c8 (Hex '00040000')
    Put $data 0x7285e (Hex 'CALL1')
    Put $data 0x728b5 (Hex 'CALL2')
    Put $data 0x603600 ([Convert]::FromBase64String('HOOK'))
    if ((Hash $data) -ne $expected) { throw 'Проверка патча не пройдена. Ничего не изменено.' }
    $temp = Join-Path (Split-Path -Parent $target) ([IO.Path]::GetRandomFileName())
    $backup = Join-Path (Split-Path -Parent $target) ([IO.Path]::GetRandomFileName() + '.bak')
    [IO.File]::WriteAllBytes($temp, $data)
    if ((Hash ([IO.File]::ReadAllBytes($temp))) -ne $expected) { throw 'Проверка записи не пройдена. Ничего не изменено.' }
    [IO.File]::Replace($temp, $target, $backup)
    $temp = $null
    if ((Hash ([IO.File]::ReadAllBytes($target))) -ne $expected) { throw ('Проверка установленной DLL не пройдена. Исходный файл сохранён: ' + $backup) }
    Remove-Item -LiteralPath $backup -Force -ErrorAction SilentlyContinue
    $backup = $null
    Write-Host 'Диагностика сохранения установлена. Скрипты и эффекты не менялись.'
} catch {
    Write-Host ('ОШИБКА: ' + $_.Exception.Message)
    exit 1
} finally {
    if ($temp -and (Test-Path -LiteralPath $temp)) { Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue }
}
'''.replace('CALL1',call(0x1007345e)).replace('CALL2',call(0x100734b5)).replace('HOOK',hook)
(p/'package/GRM_Save_Diagnostics.ps1').write_text(s,encoding='utf-8-sig',newline='\r\n')
(p/'package/INSTALL_GRM_Save_Diagnostics.bat').write_bytes(b'@echo off\r\nchcp 65001 >nul\r\npowershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0GRM_Save_Diagnostics.ps1"\r\npause\r\n')
print('ready',call(0x1007345e),call(0x100734b5))
