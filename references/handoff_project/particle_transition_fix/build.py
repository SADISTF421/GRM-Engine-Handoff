from pathlib import Path
import hashlib,zipfile
r=Path('/data/grm/particle_transition_fix'); pkg=r/'package';out=pkg/'GRM_ParticleTransition';out.mkdir(parents=True,exist_ok=True)
h=lambda x:hashlib.sha256(x).hexdigest()
inputs=[('/data/grm/chance75/package/GRM_Chance75/grm_gore_test.script','100ms_popup'),('/data/grm/fasthead/grm_gore_fast.script','50ms_popup'),('/data/grm/cleanpatch/package/GRM_CleanDiag/gore0.script','100ms_quiet'),('/data/grm/cleanpatch/package/GRM_CleanDiag/gore1.script','50ms_quiet'),('/data/grm/corpsegore/package/GRM_Corpse/gore0.script','100ms_corpse'),('/data/grm/corpsegore/package/GRM_Corpse/gore1.script','50ms_corpse')]
rows=[]
for path,name in inputs:
 b=Path(path).read_bytes();nl=b'\r\n' if b'\r\n' in b else b'\n'
 old=b'''    if not rawequal(actor, particle_actor) or map ~= particle_level then\n        particle_pool = {}\n        particle_actor, particle_level = actor, map\n    end'''.replace(b'\n',nl)
 new='''    if not rawequal(actor, particle_actor) or map ~= particle_level then\n        -- Ссылки предыдущей карты больше не удерживают частицы после перехода.\n        -- Сборщик Lua освободит их; принудительно останавливать эффекты нельзя.\n        particle_pool = {}\n        held_particles = {}\n        particle_actor, particle_level = actor, map\n    end'''.encode('cp1251').replace(b'\n',nl)
 assert b.count(old)==1;result=b.replace(old,new,1);fn=name+'.script';(out/fn).write_bytes(result);rows.append((h(b),h(result),fn));assert result.replace(new,old,1)==b
 print(name,h(b),h(result))
entries=',\n'.join("  [pscustomobject]@{old='%s';new='%s';file='%s'}"%x for x in rows)
ps=r'''$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Split-Path -Parent $MyInvocation.MyCommand.Path))
function Hash([string]$p) { return (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLowerInvariant() }
$specs=@(
ROWS
)
$tmp=$null; $bak=$null; $replaced=$false
try {
 [Console]::OutputEncoding=New-Object System.Text.UTF8Encoding
 if (@(Get-Process | Where-Object { $_.ProcessName -like 'XR_3DA*' }).Count -gt 0) { throw 'Закройте игру.' }
 $exe=Join-Path $root 'bin\XR_3DA.exe'; $dll=Join-Path $root 'bin\xrGame.dll'; $target=Join-Path $root 'gamedata\scripts\grm_gore_test.script'
 foreach ($f in @($exe,$dll,$target)) { if (!(Test-Path -LiteralPath $f -PathType Leaf)) { throw ('Нет файла: '+$f) } }
 if ((Hash $exe) -ne '5d52602915fbcbc25798b617a89303117edebb36fefef894ed0abd36e7cd634b') { throw 'Версия XR_3DA.exe не совпадает. Изменений нет.' }
 $dh=Hash $dll
 if (@('c5f1968e680b1bef8d000a0a2d37adf343026628994fffcb138fea1c3130e9fb','4a6e84f3397b853124158865bd71b54f9c438d11384bad6a90eaa08c20216959','969d116337e15a0f5c0af212c8c49ea5262bba3b2d93e4ca7af7ff140e2856d7','f59cdeeeb652adcb8f76ec621a32e72552f2037db457e7f3ea3e19633f702fbd') -notcontains $dh) { throw ('Другая версия xrGame.dll. Изменений нет. SHA256: '+$dh) }
 $sh=Hash $target
 foreach ($s in $specs) { if ($sh -eq $s.new) { Write-Host 'Патч уже установлен.'; exit 0 } }
 $entry=$specs | Where-Object { $_.old -eq $sh } | Select-Object -First 1
 if (!$entry) { throw ('Другая версия grm_gore_test.script. Изменений нет. SHA256: '+$sh) }
 $source=Join-Path $root ('GRM_ParticleTransition\'+$entry.file)
 if (!(Test-Path -LiteralPath $source -PathType Leaf) -or (Hash $source) -ne $entry.new) { throw 'Нет файла патча или он повреждён.' }
 $dir=Split-Path -Parent $target
 $tmp=Join-Path $dir ([IO.Path]::GetRandomFileName()+'.tmp');$bak=Join-Path $dir ([IO.Path]::GetRandomFileName()+'.bak')
 [IO.File]::Copy($source,$tmp); if ((Hash $tmp) -ne $entry.new) { throw 'Ошибка проверки записи.' }
 [IO.File]::Replace($tmp,$target,$bak); $replaced=$true
 if ((Hash $target) -ne $entry.new) { throw 'Ошибка проверки установленного файла.' }
 Remove-Item -LiteralPath $bak -Force -ErrorAction SilentlyContinue; $bak=$null
 Write-Host 'Исправление установлено.'
} catch {
 if ($replaced -and $bak -and (Test-Path -LiteralPath $bak)) { try { $discard=Join-Path (Split-Path -Parent $target) ([IO.Path]::GetRandomFileName()+'.tmp'); [IO.File]::Replace($bak,$target,$discard); Remove-Item -LiteralPath $discard -Force -ErrorAction SilentlyContinue; $bak=$null } catch { Write-Host ('Исходный файл: '+$bak) } }
 Write-Host ('ОШИБКА: '+$_.Exception.Message); exit 1
} finally { if ($tmp -and (Test-Path -LiteralPath $tmp)) { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue } }
'''.replace('ROWS',entries)
(pkg/'GRM_ParticleTransition.ps1').write_text(ps,encoding='utf-8-sig',newline='\r\n');(pkg/'INSTALL_GRM_ParticleTransition.bat').write_bytes(b'@echo off\r\nchcp 65001 >nul\r\npowershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0GRM_ParticleTransition.ps1"\r\npause\r\n')
(pkg/'ПРОЧТИ.txt').write_text('''ЭКСПЕРИМЕНТ: СБРОС ССЫЛОК НА ЧАСТИЦЫ ПРИ ПЕРЕХОДЕ\n\nЗакройте игру. Сделайте полный бэкап игры и сохранений. Распакуйте архив в папку игры и запустите INSTALL_GRM_ParticleTransition.bat. Установщик сверяет EXE, DLL и скрипт: при несовпадении ничего не меняет.\n\nИзменяется только gamedata\\scripts\\grm_gore_test.script. При обнаружении нового уровня или смены объекта игрока сбрасываются ссылки на частицы предыдущей сессии. Явных вызовов stop и принудительного запуска сборщика мусора нет. Эффекты текущей карты удерживаются прежним пулом. Исходная проверка адресов и зависимость от исправленной версии движка сохраняются.\n\nПравка не гарантирует отсутствие вылетов и не доказывает, что старые вылеты были вызваны частицами. В игре не проверялась. На копии старого ручного сохранения проверьте убийства с кровью, переходы в несколько локаций, сохранение и загрузку. jump_to_level перезаписывает user_autosave.sav.\n''',encoding='utf-8-sig')
with zipfile.ZipFile('/data/GRM_Particle_Transition_FIX_TEST.zip','w',zipfile.ZIP_DEFLATED) as z:
 for f in pkg.rglob('*'):
  if f.is_file():z.write(f,f.relative_to(pkg))
with zipfile.ZipFile('/data/GRM_Particle_Transition_FIX_TEST.zip') as z:assert z.testzip() is None
