from pathlib import Path
import base64,struct
p=Path('/data/grm/boneengine'); out=p/'package'; hook=base64.b64encode((p/'stub.bin').read_bytes()).decode(); jump=(b'\xe9'+struct.pack('<i',0x1061f2a0-0x10146f10-5)+b'\x90').hex()
s=r'''$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Split-Path -Parent $MyInvocation.MyCommand.Path))
$dll = Join-Path $root 'bin\xrGame.dll'
$exe = Join-Path $root 'bin\XR_3DA.exe'
$script = Join-Path $root 'gamedata\scripts\grm_gore_test.script'
$payload = Join-Path $root 'GRM_Head_Engine_TEST\grm_gore_test.script'
$tempDll = $null; $tempScript = $null; $bakDll = $null; $bakScript = $null; $dllDone = $false; $scriptDone = $false
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
function Temp([string]$target, [string]$suffix) { return (Join-Path (Split-Path -Parent $target) ([IO.Path]::GetRandomFileName() + $suffix)) }
try {
    [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding
    if (@(Get-Process | Where-Object { $_.ProcessName -like 'XR_3DA*' }).Count -gt 0) { throw 'Закрой игру перед установкой.' }
    foreach ($f in @($dll,$exe,$script,$payload)) { if (!(Test-Path -LiteralPath $f -PathType Leaf)) { throw ('Не найден файл: ' + $f + '. Ничего не изменено.') } }
    if ((Hash ([IO.File]::ReadAllBytes($exe))) -ne '5d52602915fbcbc25798b617a89303117edebb36fefef894ed0abd36e7cd634b') { throw 'XR_3DA.exe другой версии. Ничего не изменено.' }
    [byte[]]$data = [IO.File]::ReadAllBytes($dll)
    [byte[]]$oldScript = [IO.File]::ReadAllBytes($script)
    [byte[]]$newScript = [IO.File]::ReadAllBytes($payload)
    $dllhash = Hash $data; $scripthash = Hash $oldScript
    $sOld = 'eb224878303cd8c190a253e2b839e00a7776aea1f8dbba85cb29b252d1e1e293'
    $sNew = '355233bef26a35994ab718f703ad05b10e61f4542a1ecd30ac7f44ec80b50364'
    if ((Hash $newScript) -ne $sNew) { throw 'Файл патча повреждён. Ничего не изменено.' }
    if (($dllhash -eq '2ee185d32dc688e66daa6976e109ce52ec9acc2b51933a1d2c85b970fe092990' -or $dllhash -eq '1fe8dffe83f3b808bfd9604f25e871adbf9b969f81e911ed0860296c2ffef168') -and $scripthash -eq $sNew) { Write-Host 'Патч уже установлен.'; exit 0 }
    if ($scripthash -ne $sOld) { throw 'grm_gore_test.script отличается от проверенной версии PreAim. Ничего не изменено.' }
    if ($dllhash -eq 'b04af51804921c634ca427fce1abaed57964b6beba3e9b0de4bdf8d864e44844') { $expected='2ee185d32dc688e66daa6976e109ce52ec9acc2b51933a1d2c85b970fe092990' }
    elseif ($dllhash -eq '5e1930428bc8a859a378c709eee65fbddfef64cb571b6341b6c60736977a1018') { $expected='1fe8dffe83f3b808bfd9604f25e871adbf9b969f81e911ed0860296c2ffef168' }
    else { throw 'xrGame.dll отличается от проверенной версии с предыдущей защитой. Ничего не изменено.' }
    Put $data 0x2c0 (Hex 'cb030000')
    Put $data 0x146310 (Hex 'JUMP')
    Put $data 0x6036a0 ([Convert]::FromBase64String('HOOK'))
    if ((Hash $data) -ne $expected) { throw 'Проверка DLL не пройдена. Ничего не изменено.' }
    $tempDll = Temp $dll '.tmp'; $bakDll = Temp $dll '.bak'
    $tempScript = Temp $script '.tmp'; $bakScript = Temp $script '.bak'
    [IO.File]::WriteAllBytes($tempDll,$data)
    [IO.File]::WriteAllBytes($tempScript,$newScript)
    if ((Hash ([IO.File]::ReadAllBytes($tempDll))) -ne $expected -or (Hash ([IO.File]::ReadAllBytes($tempScript))) -ne $sNew) { throw 'Проверка записи не пройдена. Ничего не изменено.' }
    [IO.File]::Replace($tempDll,$dll,$bakDll); $tempDll=$null; $dllDone=$true
    [IO.File]::Replace($tempScript,$script,$bakScript); $tempScript=$null; $scriptDone=$true
    if ((Hash ([IO.File]::ReadAllBytes($dll))) -ne $expected -or (Hash ([IO.File]::ReadAllBytes($script))) -ne $sNew) { throw 'Проверка установленных файлов не пройдена.' }
    Remove-Item -LiteralPath $bakDll,$bakScript -Force -ErrorAction SilentlyContinue
    $bakDll=$null; $bakScript=$null
    Write-Host 'Экспериментальная версия установлена.'
} catch {
    Write-Host ('ОШИБКА: ' + $_.Exception.Message)
    if ($scriptDone -and $bakScript -and (Test-Path -LiteralPath $bakScript)) {
        try { $discard=Temp $script '.tmp'; [IO.File]::Replace($bakScript,$script,$discard); Remove-Item -LiteralPath $discard -Force -ErrorAction SilentlyContinue; $bakScript=$null }
        catch { Write-Host ('Исходный скрипт сохранён здесь: ' + $bakScript) }
    }
    if ($dllDone -and $bakDll -and (Test-Path -LiteralPath $bakDll)) {
        try { $discard=Temp $dll '.tmp'; [IO.File]::Replace($bakDll,$dll,$discard); Remove-Item -LiteralPath $discard -Force -ErrorAction SilentlyContinue; $bakDll=$null }
        catch { Write-Host ('Исходная DLL сохранена здесь: ' + $bakDll) }
    }
    exit 1
} finally {
    foreach ($f in @($tempDll,$tempScript)) { if ($f -and (Test-Path -LiteralPath $f)) { Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue } }
}
'''.replace('JUMP',jump).replace('HOOK',hook)
(out/'GRM_Head_Engine_TEST.ps1').write_text(s,encoding='utf-8-sig',newline='\r\n')
(out/'INSTALL_GRM_Head_Engine_TEST.bat').write_bytes(b'@echo off\r\nchcp 65001 >nul\r\npowershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0GRM_Head_Engine_TEST.ps1"\r\npause\r\n')
readme='''ЭКСПЕРИМЕНТ: СКРЫТИЕ ГОЛОВЫ В ДВИЖКЕ\r\n\r\nПолностью закрой игру, сделай полный бэкап игры и сохранений. Распакуй архив в папку игры рядом с bin и gamedata. Запусти INSTALL_GRM_Head_Engine_TEST.bat. Установщик сверяет хэши EXE, DLL и текущего скрипта, без совпадения не меняет файлы. Нужна версия с предыдущей защитой восстановления физики и скрипт из GRM_Gore_PreAim_TEST.\r\n\r\nВ этой версии скрывается кость головы штатным вызовом движка. Кость физически не удаляется. Перехват GPU-плагина больше не загружается этим скриптом, прямые записи в матрицы костей не выполняются. Оставлены шанс 25%% на весь эффект, мясо, кровь и звук. Выстрелы по уже мёртвым NPC не подключены.\r\n\r\nЭто эксперимент: стабильность сохранений, загрузок и переходов, вид модели без растяжений и сохранность других механик не подтверждены в игре. При несовпадении физического скелета при загрузке защита может сбросить позу трупа. Проверяй на копии старого сохранения. jump_to_level перезаписывает user_autosave.sav.\r\n'''.replace('25%%','25%')
(out/'READ_ME.txt').write_bytes(readme.encode('utf-8-sig'))
