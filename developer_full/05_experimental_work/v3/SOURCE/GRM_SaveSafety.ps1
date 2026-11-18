param([string]$SaveDir = '')
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding
try {
    if (@(Get-Process -Name 'XR_3DA*' -ErrorAction SilentlyContinue).Count -gt 0) { throw 'Закройте игру перед копированием.' }
    $tool = $PSScriptRoot
    $game = Split-Path -Parent $tool
    if ([string]::IsNullOrWhiteSpace($SaveDir)) { $SaveDir = Join-Path $game 'appdata\savedgames' }
    if (!(Test-Path -LiteralPath $SaveDir -PathType Container)) { throw ('Папка сохранений не найдена: ' + $SaveDir + '. Перетащите её на BAT.') }
    $source = (Get-Item -LiteralPath $SaveDir).FullName.TrimEnd('\')
    if ((Get-Item -LiteralPath $source).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Папка сохранений является ссылкой: копирование остановлено.' }
    $backupRoot = Join-Path $tool 'Backups'
    $fullBackupRoot = [IO.Path]::GetFullPath($backupRoot)
    if ($fullBackupRoot.StartsWith($source + '\', [StringComparison]::OrdinalIgnoreCase) -or $fullBackupRoot.Equals($source, [StringComparison]::OrdinalIgnoreCase)) { throw 'Папка копий находится внутри папки сохранений.' }
    $files = @(Get-ChildItem -LiteralPath $source -Force -Recurse | Where-Object { -not $_.PSIsContainer })
    if ($files.Count -eq 0) { throw 'Папка сохранений пуста.' }
    $items = @(Get-ChildItem -LiteralPath $source -Force -Recurse)
    if (@($items | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint }).Count -gt 0) { throw 'Найдена ссылка внутри папки сохранений; копирование остановлено.' }
    New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null
    $name = (Get-Date -Format 'yyyyMMdd_HHmmss') + '_' + [Guid]::NewGuid().ToString('N').Substring(0,8)
    $stage = Join-Path $backupRoot ('.tmp_' + $name)
    $dest = Join-Path $backupRoot $name
    New-Item -ItemType Directory -Path $stage | Out-Null
    $records = New-Object 'System.Collections.Generic.List[object]'
    foreach ($f in $files) {
        $rel = $f.FullName.Substring($source.Length).TrimStart('\')
        $target = Join-Path (Join-Path $stage 'savedgames') $rel
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
        $before = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash
        [IO.File]::Copy($f.FullName, $target, $false)
        $copy = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
        $after = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash
        if ($before -ne $copy -or $after -ne $before) { throw ('Файл изменился либо не скопирован точно: ' + $rel) }
        $header = 'не проверялся'
        if ($f.Extension -ieq '.sav') {
            $header = 'подозрительный заголовок или файл короче 13 байт'
            $stream = [IO.File]::OpenRead($target)
            try {
                if ($stream.Length -ge 13) {
                    $b = New-Object byte[] 12
                    if ($stream.Read($b, 0, 12) -eq 12) {
                        $sig = [BitConverter]::ToUInt32($b,0); $version = [BitConverter]::ToUInt32($b,4); $unpacked = [BitConverter]::ToUInt32($b,8)
                        if ($sig -eq [uint32]::MaxValue -and $unpacked -gt 0) { $header = 'заголовок похож на SoC: версия=' + $version + ', распакованный размер=' + $unpacked }
                    }
                }
            } finally { $stream.Dispose() }
        }
        $records.Add([pscustomobject]@{path=$rel;sha256=$copy.ToLowerInvariant();bytes=$f.Length;header=$header})
    }
    $again = @(Get-ChildItem -LiteralPath $source -Force -Recurse | Where-Object { -not $_.PSIsContainer })
    if ($again.Count -ne $files.Count) { throw 'Список файлов изменился во время копирования.' }
    $report = [pscustomobject]@{created=(Get-Date).ToString('o'); source=$source; caveat='Заголовок не доказывает целостность LZO, объектов и загрузку в игре.'; files=$records.ToArray()}
    $report | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $stage 'manifest.json') -Encoding UTF8
    Move-Item -LiteralPath $stage -Destination $dest
    Write-Host ('Создана отдельная копия: ' + $dest)
    Write-Host ('Файлов: ' + $records.Count + '. SHA-256 проверены. Оригиналы не изменялись.')
    Write-Host 'Проверка заголовка не доказывает исправность или загрузку сейва.'
} catch {
    Write-Host ('ОШИБКА: ' + $_.Exception.Message)
    if ($stage -and (Test-Path -LiteralPath $stage)) { Write-Host ('Неполная копия оставлена для проверки: ' + $stage) }
    exit 1
}
