from pathlib import Path
import base64,struct
p=Path('/data/grm/restoreguard'); out=p/'package'; hook=base64.b64encode((p/'hook.bin').read_bytes()).decode(); jump=(b'\xe9'+struct.pack('<i',0x1061f270-0x101f279a-5)+b'\x90').hex()
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
    if (@(Get-Process | Where-Object { $_.ProcessName -like 'XR_3DA*' }).Count -gt 0) { throw 'Закрой игру перед установкой.' }
    if (!(Test-Path -LiteralPath $target -PathType Leaf) -or !(Test-Path -LiteralPath $exe -PathType Leaf)) { throw 'Распакуй архив в папку игры, рядом с bin.' }
    if ((Hash ([IO.File]::ReadAllBytes($exe))) -ne '5d52602915fbcbc25798b617a89303117edebb36fefef894ed0abd36e7cd634b') { throw 'XR_3DA.exe другой версии. Ничего не изменено.' }
    [byte[]]$data = [IO.File]::ReadAllBytes($target)
    $oldhash = Hash $data
    $sourceA = '18ee5800ce2bdfb3dfb912ccb108148626a9ad3dd04cae40ca35d9d85d77c827'
    $sourceB = 'f927a2f5fee2e57b848730e23c7e0bcebe2b9478859d618293835abcbf8be01a'
    $newA = 'b04af51804921c634ca427fce1abaed57964b6beba3e9b0de4bdf8d864e44844'
    $newB = '5e1930428bc8a859a378c709eee65fbddfef64cb571b6341b6c60736977a1018'
    if ($oldhash -eq $newA -or $oldhash -eq $newB) { Write-Host 'Защита уже установлена.'; exit 0 }
    if ($oldhash -eq $sourceA) { $expected = $newA }
    elseif ($oldhash -eq $sourceB) { $expected = $newB }
    else { throw 'Версия xrGame.dll отличается. Ничего не изменено.' }
    Put $data 0x2c0 (Hex '97020000')
    Put $data 0x1f1b9a (Hex 'JUMP')
    Put $data 0x603670 ([Convert]::FromBase64String('HOOK'))
    if ((Hash $data) -ne $expected) { throw 'Проверка результата не пройдена. Ничего не изменено.' }
    $temp = Join-Path (Split-Path -Parent $target) ([IO.Path]::GetRandomFileName())
    $backup = Join-Path (Split-Path -Parent $target) ([IO.Path]::GetRandomFileName() + '.bak')
    [IO.File]::WriteAllBytes($temp, $data)
    if ((Hash ([IO.File]::ReadAllBytes($temp))) -ne $expected) { throw 'Проверка записи не пройдена. Ничего не изменено.' }
    [IO.File]::Replace($temp, $target, $backup)
    $temp = $null
    if ((Hash ([IO.File]::ReadAllBytes($target))) -ne $expected) { throw ('Проверка установленной DLL не пройдена. Исходный файл сохранён: ' + $backup) }
    Remove-Item -LiteralPath $backup -Force -ErrorAction SilentlyContinue
    $backup = $null
    Write-Host 'Защита восстановления скелета установлена. Эффект головы не менялся.'
} catch {
    Write-Host ('ОШИБКА: ' + $_.Exception.Message)
    exit 1
} finally {
    if ($temp -and (Test-Path -LiteralPath $temp)) { Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue }
}
'''.replace('JUMP',jump).replace('HOOK',hook)
(out/'GRM_Physics_Restore_Guard_TEST.ps1').write_text(s,encoding='utf-8-sig',newline='\r\n')
(out/'INSTALL_GRM_Physics_Guard_TEST.bat').write_bytes(b'@echo off\r\nchcp 65001 >nul\r\npowershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0GRM_Physics_Restore_Guard_TEST.ps1"\r\npause\r\n')
readme='''ЭКСПЕРИМЕНТАЛЬНАЯ ЗАЩИТА ВОССТАНОВЛЕНИЯ ФИЗИКИ\r\n\r\nЗакрой игру. Сделай полный бэкап игры и сохранений. Распакуй архив в папку игры рядом с bin и запусти INSTALL_GRM_Physics_Guard_TEST.bat. Установщик проверяет SHA-256 EXE и DLL до замены. При несовпадении ничего не изменяет.\r\n\r\nПри загрузке объекта защита сравнивает число сохранённых физических состояний с числом элементов нового физического скелета. При несовпадении сохранённая поза конкретного объекта не применяется; текущая физическая поза может измениться. При совпадении используется штатный код. Остальные файлы не изменяются.\r\n\r\nПатч НЕ удаляет и НЕ скрывает голову, не устраняет доказанно вылет при записи сохранения. Это отдельная проверка против ошибки восстановления скелета при загрузке; в игре не проверен. Тестируй на копии старого сохранения: после эффекта сохранись, загрузи игру и проверь переход между локациями. jump_to_level перезаписывает user_autosave.sav.\r\n'''
(out/'ПРОЧИТАЙ.txt').write_bytes(readme.encode('utf-8-sig'))
