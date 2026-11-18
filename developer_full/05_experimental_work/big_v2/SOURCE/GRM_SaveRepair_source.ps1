param([Parameter(Position=0)][string]$Path)
[Console]::OutputEncoding=New-Object System.Text.UTF8Encoding
Write-Host 'Ремонт выключен: достоверной процедуры восстановления в этом пакете нет.'
Write-Host 'Оригинал не открывался на запись, не копировался и не изменялся.'
Write-Host 'Проверка только заголовка не определяет безопасные исправления.'
exit 2
