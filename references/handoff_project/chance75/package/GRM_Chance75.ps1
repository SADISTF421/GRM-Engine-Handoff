$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Split-Path -Parent $MyInvocation.MyCommand.Path))
$target = Join-Path $root 'gamedata\scripts\grm_gore_test.script'
$payload = Join-Path $root 'GRM_Chance75\grm_gore_test.script'
$dll = Join-Path $root 'bin\xrGame.dll'
$exe = Join-Path $root 'bin\XR_3DA.exe'
$temp=$null; $backup=$null
function Hash([byte[]]$data) {
    $a = [Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($a.ComputeHash($data))).Replace('-','').ToLowerInvariant() }
    finally { $a.Dispose() }
}
try {
    [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding
    if (@(Get-Process | Where-Object { $_.ProcessName -like 'XR_3DA*' }).Count -gt 0) { throw 'Закрой игру перед установкой.' }
    foreach ($f in @($target,$payload,$dll,$exe)) { if (!(Test-Path -LiteralPath $f -PathType Leaf)) { throw ('Не найден файл: ' + $f + '. Ничего не изменено.') } }
    if ((Hash ([IO.File]::ReadAllBytes($exe))) -ne '5d52602915fbcbc25798b617a89303117edebb36fefef894ed0abd36e7cd634b') { throw 'XR_3DA.exe другой версии. Ничего не изменено.' }
    $dllHash = Hash ([IO.File]::ReadAllBytes($dll))
    if ($dllHash -ne '2ee185d32dc688e66daa6976e109ce52ec9acc2b51933a1d2c85b970fe092990' -and $dllHash -ne '1fe8dffe83f3b808bfd9604f25e871adbf9b969f81e911ed0860296c2ffef168') { throw 'Не установлена проверенная версия GRM_Head_Engine_TEST. Ничего не изменено.' }
    [byte[]]$replacement=[IO.File]::ReadAllBytes($payload)
    $newHash='796b2db67e21ec231fb7455f09da9e0bcabb03b9550aeea663b96d411c8946e9'
    if ((Hash $replacement) -ne $newHash) { throw 'Файл патча повреждён. Ничего не изменено.' }
    $oldHash=Hash ([IO.File]::ReadAllBytes($target))
    if ($oldHash -eq $newHash) { Write-Host 'Обновление уже установлено.'; exit 0 }
    if ($oldHash -ne '355233bef26a35994ab718f703ad05b10e61f4542a1ecd30ac7f44ec80b50364') { throw 'Скрипт отличается от проверенной версии. Ничего не изменено.' }
    $temp=Join-Path (Split-Path -Parent $target) ([IO.Path]::GetRandomFileName()+'.tmp')
    $backup=Join-Path (Split-Path -Parent $target) ([IO.Path]::GetRandomFileName()+'.bak')
    [IO.File]::WriteAllBytes($temp,$replacement)
    if ((Hash ([IO.File]::ReadAllBytes($temp))) -ne $newHash) { throw 'Ошибка проверки записи. Ничего не изменено.' }
    [IO.File]::Replace($temp,$target,$backup); $temp=$null
    if ((Hash ([IO.File]::ReadAllBytes($target))) -ne $newHash) { throw ('Ошибка проверки скрипта. Исходный файл сохранён: ' + $backup) }
    Remove-Item -LiteralPath $backup -Force -ErrorAction SilentlyContinue; $backup=$null
    Write-Host 'Готово: шанс 75%, ТОЗ, СВД и СВУ.'
} catch { Write-Host ('ОШИБКА: ' + $_.Exception.Message); exit 1 }
finally { if ($temp -and (Test-Path -LiteralPath $temp)) { Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue } }
