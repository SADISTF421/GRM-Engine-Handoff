$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
try {
    $root = $PSScriptRoot
    $target = Join-Path $root 'gamedata\scripts\task_manager.script'
    $payload = Join-Path $root 'GRM_Save_Fix\task_manager.script'
    $game = Join-Path $root 'bin\xrGame.dll'
    $expectedScript = '2d7faa7f503adaf2eee425a17b329e2b48310396a33c2b47e913f156d24a7e09'
    $expectedGame = 'f927a2f5fee2e57b848730e23c7e0bcebe2b9478859d618293835abcbf8be01a'
    $expectedPatch = 'fdb96acef7e9127e21c13e0795dc5d80086ab00a6512dc28a547575f5b51c84e'
    if (Get-Process -Name 'XR_3DA*' -ErrorAction SilentlyContinue) { throw 'Закрой игру перед установкой.' }
    foreach ($path in @($target, $payload, $game)) {
        if (-not [IO.File]::Exists($path)) { throw "Файл не найден: $path. Распакуй архив в папку игры." }
    }
    if ((Get-FileHash -Algorithm SHA256 -LiteralPath $game).Hash.ToLowerInvariant() -ne $expectedGame) { throw 'Версия bin\xrGame.dll отличается от проверенной. Установка остановлена.' }
    if ((Get-FileHash -Algorithm SHA256 -LiteralPath $payload).Hash.ToLowerInvariant() -ne $expectedPatch) { throw 'Файл патча повреждён. Установка остановлена.' }
    $current = (Get-FileHash -Algorithm SHA256 -LiteralPath $target).Hash.ToLowerInvariant()
    if ($current -eq $expectedPatch) { Write-Host 'Патч уже установлен.'; exit 0 }
    if ($current -ne $expectedScript) { throw 'Текущий task_manager.script отличается от присланного. Установка остановлена.' }
    $token = [Guid]::NewGuid().ToString('N')
    $temp = Join-Path (Split-Path -Parent $target) ('.grm-' + $token + '.tmp')
    $backup = Join-Path (Split-Path -Parent $target) ('.grm-' + $token + '.bak')
    try {
        [IO.File]::Copy($payload, $temp)
        [IO.File]::Replace($temp, $target, $backup)
        if ((Get-FileHash -Algorithm SHA256 -LiteralPath $target).Hash.ToLowerInvariant() -ne $expectedPatch) { throw "Проверка установленного файла не пройдена. Копия исходника: $backup" }
        [IO.File]::Delete($backup)
    } finally {
        if ([IO.File]::Exists($temp)) { [IO.File]::Delete($temp) }
    }
    Write-Host 'Готово: установлен тест компактного сохранения задач.'
} catch {
    Write-Host ('ОШИБКА: ' + $_.Exception.Message)
    exit 1
}
