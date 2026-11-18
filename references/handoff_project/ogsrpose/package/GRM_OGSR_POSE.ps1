$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Split-Path -Parent $MyInvocation.MyCommand.Path))
$dll = Join-Path $root 'bin\xrGame.dll'
$exe = Join-Path $root 'bin\XR_3DA.exe'
$payload = Join-Path $root 'GRM_OGSR_POSE\xrGame.dll'
$temp=$null; $backup=$null; $replaced=$false
function HashFile([string]$path) { $s=[Security.Cryptography.SHA256]::Create(); $f=[IO.File]::OpenRead($path); try { return ([BitConverter]::ToString($s.ComputeHash($f))).Replace('-','').ToLowerInvariant() } finally { $f.Dispose(); $s.Dispose() } }
try {
 [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding
 if (@(Get-Process | Where-Object { $_.ProcessName -like 'XR_3DA*' }).Count -gt 0) { throw 'Закройте игру. Ничего не изменено.' }
 foreach($f in @($dll,$exe,$payload)) { if (!(Test-Path -LiteralPath $f -PathType Leaf)) { throw ('Не найден файл: '+$f+'. Распакуйте архив в папку игры.') } }
 if ((HashFile $exe) -ne '5d52602915fbcbc25798b617a89303117edebb36fefef894ed0abd36e7cd634b') { throw 'Другая версия XR_3DA.exe. Ничего не изменено.' }
 $old=HashFile $dll
 if ($old -eq '4a6e84f3397b853124158865bd71b54f9c438d11384bad6a90eaa08c20216959') { Write-Host 'Патч уже установлен.'; exit 0 }
 if ($old -ne 'c5f1968e680b1bef8d000a0a2d37adf343026628994fffcb138fea1c3130e9fb') { throw ('Другая версия xrGame.dll. Ничего не изменено. SHA256: '+$old) }
 if ((HashFile $payload) -ne '4a6e84f3397b853124158865bd71b54f9c438d11384bad6a90eaa08c20216959') { throw 'Файл патча повреждён. Ничего не изменено.' }
 $dir=Split-Path -Parent $dll
 $temp=Join-Path $dir ([IO.Path]::GetRandomFileName()+'.tmp')
 $backup=Join-Path $dir ([IO.Path]::GetRandomFileName()+'.bak')
 [IO.File]::Copy($payload,$temp)
 if ((HashFile $temp) -ne '4a6e84f3397b853124158865bd71b54f9c438d11384bad6a90eaa08c20216959') { throw 'Ошибка проверки записи. Ничего не изменено.' }
 [IO.File]::Replace($temp,$dll,$backup); $temp=$null; $replaced=$true
 if ((HashFile $dll) -ne '4a6e84f3397b853124158865bd71b54f9c438d11384bad6a90eaa08c20216959') { throw 'Ошибка проверки установленной DLL.' }
 Remove-Item -LiteralPath $backup -Force -ErrorAction SilentlyContinue; $backup=$null
 Write-Host 'Экспериментальная правка движка установлена.'
} catch {
 Write-Host ('ОШИБКА: '+$_.Exception.Message)
 if ($replaced -and $backup -and (Test-Path -LiteralPath $backup)) {
   try { $discard=Join-Path (Split-Path -Parent $dll) ([IO.Path]::GetRandomFileName()+'.tmp'); [IO.File]::Replace($backup,$dll,$discard); Remove-Item -LiteralPath $discard -Force -ErrorAction SilentlyContinue; $backup=$null; Write-Host 'Прежняя DLL восстановлена.' }
   catch { Write-Host ('Исходная DLL сохранена здесь: '+$backup) }
 }
 exit 1
} finally { if ($temp -and (Test-Path -LiteralPath $temp)) { Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue } }
