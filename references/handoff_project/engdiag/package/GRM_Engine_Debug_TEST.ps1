$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Split-Path -Parent $MyInvocation.MyCommand.Path))
$dll = Join-Path $root 'bin\xrGame.dll'
$exe = Join-Path $root 'bin\XR_3DA.exe'
$temp=$null; $backup=$null; $replaced=$false
function Hash([byte[]]$bytes) {
    $s = [Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($s.ComputeHash($bytes))).Replace('-','').ToLowerInvariant() } finally { $s.Dispose() }
}
function Put([byte[]]$dest, [int]$offset, [byte[]]$part) { [Array]::Copy($part, 0, $dest, $offset, $part.Length) }
function Hex([string]$text) {
    $data = New-Object byte[] ($text.Length / 2)
    for ($i=0; $i -lt $data.Length; $i++) { $data[$i] = [Convert]::ToByte($text.Substring($i*2,2),16) }
    return ,$data
}
try {
    [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding
    if (@(Get-Process | Where-Object { $_.ProcessName -like 'XR_3DA*' }).Count -gt 0) { throw 'Закройте игру. Ничего не изменено.' }
    foreach ($f in @($dll,$exe)) { if (!(Test-Path -LiteralPath $f -PathType Leaf)) { throw ('Не найден файл: '+$f+'. Ничего не изменено.') } }
    if ((Hash ([IO.File]::ReadAllBytes($exe))) -ne '5d52602915fbcbc25798b617a89303117edebb36fefef894ed0abd36e7cd634b') { throw 'XR_3DA.exe другой версии. Ничего не изменено.' }
    [byte[]]$old = [IO.File]::ReadAllBytes($dll)
    $h = Hash $old
    if ($h -eq 'cc11e3ef7e9064783ba82a7fc8b3428cbca755b66bb72deff554681fe2dca92a' -or $h -eq '13ac4578e37c9cec44b103408f97b91dee68607ed3dd6d34f7faae75c8e3c600') { Write-Host 'Диагностика уже установлена.'; exit 0 }
    if ($h -eq '2ee185d32dc688e66daa6976e109ce52ec9acc2b51933a1d2c85b970fe092990') { $expected='cc11e3ef7e9064783ba82a7fc8b3428cbca755b66bb72deff554681fe2dca92a' }
    elseif ($h -eq '1fe8dffe83f3b808bfd9604f25e871adbf9b969f81e911ed0860296c2ffef168') { $expected='13ac4578e37c9cec44b103408f97b91dee68607ed3dd6d34f7faae75c8e3c600' }
    else { throw ('xrGame.dll отличается от двух проверенных версий. Ничего не изменено. SHA256: '+$h) }
    [byte[]]$data = New-Object byte[] ($old.Length + 0x400)
    [Array]::Copy($old, $data, $old.Length)
    Put $data 0x2c0 (Hex '70060000')
    Put $data 0x2c8 (Hex '00080000')
    Put $data 0x146310 (Hex 'e9eb844d0090')
    Put $data 0x1f1b9a (Hex 'e961ce420090')
    Put $data 0x603800 ([Convert]::FromBase64String('U1dWVYPsCInNi3QkHIt8JCCF/w+EFAEAAOgAAAAAW4HrHvRhAIn5jZNB9WEAigE6AnUIhMB0HkFC6/KJ+Y2TVvVhAIoBOgIPheAAAACEwHQLQULr7r8BAAAA6wW/AgAAAIX2D4S4AAAAxwYAAIC/x0YEAAAAAMdGCAAAAACF7Q+EnAAAAItFBIXAD4SRAAAAjZM0Q0gAORAPhYMAAACJBCSLiJAAAACFyXR2iwH/UBiFwHRticWNk231YQBSien/k6BqRgAPt8CJRCQEg/hAc1CD/wJ0C1DbBCSDxATZHutAagFqAFCJ6f+TiGdGAIsEJIuAsAAAAIXAdAWDwAzrBo2DmvVhAP90JARQjYN49WEAUP+TdG1GAIPEDMcGAACAP4nwg8QIXV5fW8IIAInpg8QIXV5fW1WJ5YPk+OnVebL/X19ncm1fdGVzdF9oZWFkX2lkX18AX19ncm1fdGVzdF9oaWRlX2hlYWRfXwBiaXAwMV9oZWFkAFtHUk1fSEVBRF9ESUFHXSB2aXN1YWw9JXMgYm9uZT0ldQB1bmtub3duAA=='))
    Put $data 0x603a00 ([Convert]::FromBase64String('iemLRQD/kJgBAAAPt8BrwGyLVCQUKfI5wnUF6YAxvf9SUOgAAAAAWYHpJ/ZhAI2RQ/ZhAFL/kXRtRgCDxAzpFjK9/1tHUk1fUEhZU19ESUFHXSBsaXZlX2J5dGVzPSV1IHNhdmVkX2J5dGVzPSV1AA=='))
    if ((Hash $data) -ne $expected) { throw 'Проверка патча не пройдена. Ничего не изменено.' }
    $dir = Split-Path -Parent $dll
    $temp = Join-Path $dir ([IO.Path]::GetRandomFileName() + '.tmp')
    $backup = Join-Path $dir ([IO.Path]::GetRandomFileName() + '.bak')
    [IO.File]::WriteAllBytes($temp,$data)
    if ((Hash ([IO.File]::ReadAllBytes($temp))) -ne $expected) { throw 'Проверка записи не пройдена. Ничего не изменено.' }
    [IO.File]::Replace($temp,$dll,$backup); $temp=$null; $replaced=$true
    if ((Hash ([IO.File]::ReadAllBytes($dll))) -ne $expected) { throw 'Проверка установленной DLL не пройдена.' }
    Remove-Item -LiteralPath $backup -Force -ErrorAction SilentlyContinue; $backup=$null
    Write-Host 'Диагностика движка установлена.'
} catch {
    Write-Host ('ОШИБКА: '+$_.Exception.Message)
    if ($replaced -and $backup -and (Test-Path -LiteralPath $backup)) {
        try { $discard = Join-Path (Split-Path -Parent $dll) ([IO.Path]::GetRandomFileName()+'.tmp'); [IO.File]::Replace($backup,$dll,$discard); Remove-Item -LiteralPath $discard -Force -ErrorAction SilentlyContinue; $backup=$null; Write-Host 'Прежняя DLL восстановлена.' }
        catch { Write-Host ('Исходная DLL сохранена здесь: '+$backup) }
    }
    exit 1
} finally { if ($temp -and (Test-Path -LiteralPath $temp)) { Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue } }
