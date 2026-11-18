from pathlib import Path
import hashlib,zipfile
root=Path('/data/grm/corpse_callback_fix');pkg=root/'package';d=pkg/'GRM_Corpse_Callback';d.mkdir(parents=True,exist_ok=True)
h=lambda x:hashlib.sha256(x).hexdigest()
s=Path('/data/grm/corpsegore/package/GRM_Corpse/motivator.script').read_bytes();assert h(s)=='cc39221b2fb38bd844058dbdec2dd7b8828063343a32e55022bdb83ac3ea3915'
nl=b'\r\n' if b'\r\n' in s else b'\n';a=s.index(b'function motivator_binder:death_callback(');b=s.index(b'function motivator_binder:use_callback(',a);block=s[a:b];needle=b'\tself:clear_callbacks()';assert block.count(needle)==1
add='''\t-- Для трупа оставляем только обработчик попаданий; при удалении он отключается.\n\tself.object:set_callback(callback.hit, motivator_binder.hit_callback, self)'''.encode('cp1251').replace(b'\n',nl)
block=block.replace(needle,needle+nl+add,1);out=s[:a]+block+s[b:]
old=b'''\t\tpcall(function() grm_gore_test.corpse_hit(self, who, bone_index) end)''';new='''\t\tlocal now = time_global()\n\t\tif not self.grm_corpse_log_time or now < self.grm_corpse_log_time or now - self.grm_corpse_log_time >= 500 then\n\t\t\tself.grm_corpse_log_time = now\n\t\t\tpcall(function() printf("[GRM_CORPSE] hit bone=%s", tostring(bone_index)) end)\n\t\tend\n\t\tlocal ok, err = pcall(function() grm_gore_test.corpse_hit(self, who, bone_index) end)\n\t\tif not ok then pcall(function() printf("[GRM_CORPSE] error %s", tostring(err)) end) end'''.encode('cp1251').replace(b'\n',nl)
assert out.count(old)==1;out=out.replace(old,new,1);(d/'xr_motivator.script').write_bytes(out)
newhash=h(out);print('old',h(s),'new',newhash)
ps=r'''$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Split-Path -Parent $MyInvocation.MyCommand.Path))
function Hash([string]$p) { return (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLowerInvariant() }
$tmp=$null; $bak=$null; $replaced=$false
try {
 [Console]::OutputEncoding=New-Object System.Text.UTF8Encoding
 if (@(Get-Process | Where-Object { $_.ProcessName -like 'XR_3DA*' }).Count -gt 0) { throw 'Закройте игру.' }
 $exe=Join-Path $root 'bin\XR_3DA.exe'; $dll=Join-Path $root 'bin\xrGame.dll'; $gore=Join-Path $root 'gamedata\scripts\grm_gore_test.script'; $target=Join-Path $root 'gamedata\scripts\xr_motivator.script'; $source=Join-Path $root 'GRM_Corpse_Callback\xr_motivator.script'
 foreach ($p in @($exe,$dll,$gore,$target,$source)) { if (!(Test-Path -LiteralPath $p -PathType Leaf)) { throw ('Не найден файл: '+$p) } }
 if ((Hash $exe) -ne '5d52602915fbcbc25798b617a89303117edebb36fefef894ed0abd36e7cd634b') { throw 'Другая версия EXE.' }
 if (@('969d116337e15a0f5c0af212c8c49ea5262bba3b2d93e4ca7af7ff140e2856d7','f59cdeeeb652adcb8f76ec621a32e72552f2037db457e7f3ea3e19633f702fbd') -notcontains (Hash $dll)) { throw ('Нужна установленная предыдущая версия патча. xrGame.dll SHA256: '+(Hash $dll)) }
 if (@('ebf92bc9fd6a18272eb58eb3432e29cc7d807560a5e4bc2909c7e2fe9c800e64','7e3118d4fe9abbe94dc255412d346134c7167e6c8211a6140378baeb9a6e4c7e') -notcontains (Hash $gore)) { throw ('Другая версия скрипта grm_gore_test.script SHA256: '+(Hash $gore)) }
 $targetHash=Hash $target
 if ($targetHash -eq 'NEWHASH') { Write-Host 'Уже установлен.'; exit 0 }
 if ($targetHash -ne 'cc39221b2fb38bd844058dbdec2dd7b8828063343a32e55022bdb83ac3ea3915') { throw ('Другая версия xr_motivator.script SHA256: '+$targetHash) }
 if ((Hash $source) -ne 'NEWHASH') { throw 'Файл патча повреждён.' }
 $dir=Split-Path -Parent $target; $tmp=Join-Path $dir ([IO.Path]::GetRandomFileName()+'.tmp'); $bak=Join-Path $dir ([IO.Path]::GetRandomFileName()+'.bak')
 [IO.File]::Copy($source,$tmp); if ((Hash $tmp) -ne 'NEWHASH') { throw 'Ошибка проверки временного файла.' }
 [IO.File]::Replace($tmp,$target,$bak); $replaced=$true
 if ((Hash $target) -ne 'NEWHASH') { throw 'Ошибка проверки записи.' }
 Remove-Item -LiteralPath $bak -Force -ErrorAction SilentlyContinue; $bak=$null
 Write-Host 'Готово. Проверьте в игре.'
} catch {
 if ($replaced -and $bak -and (Test-Path -LiteralPath $bak)) { try { $discard=Join-Path (Split-Path -Parent $target) ([IO.Path]::GetRandomFileName()+'.tmp'); [IO.File]::Replace($bak,$target,$discard); Remove-Item -LiteralPath $discard -Force -ErrorAction SilentlyContinue; $bak=$null } catch { Write-Host ('Исходный файл: '+$bak) } }
 Write-Host ('ОШИБКА: '+$_.Exception.Message); exit 1
} finally { if ($tmp -and (Test-Path -LiteralPath $tmp)) { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue } }
'''.replace('NEWHASH',newhash)
(pkg/'GRM_Corpse_Callback.ps1').write_text(ps,encoding='utf-8-sig',newline='\r\n')
(pkg/'INSTALL_GRM_Corpse_Callback.bat').write_bytes(b'@echo off\r\nchcp 65001 >nul\r\npowershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0GRM_Corpse_Callback.ps1"\r\npause\r\n')
(pkg/'ПРОЧТИ.txt').write_text('''ИСПРАВЛЕНИЕ ОБРАБОТЧИКА ТРУПОВ: ЭКСПЕРИМЕНТ\n\nНужен установленный предыдущий GRM_Corpse_Headshot_TEST. В его xr_motivator.script обработчик попаданий отключался при смерти NPC. Этот патч оставляет обработчик попаданий после смерти и отключает его при удалении объекта. Существующие обработчики живых NPC не меняются. Движок и шанс не изменяются.\n\nПолностью закройте игру, сделайте полный бэкап игры и сохранений. Распакуйте в папку игры, запустите INSTALL_GRM_Corpse_Callback.bat. Установщик сверит все нужные версии.\n\nТест в игре необходим: убейте NPC без отрыва головы, затем несколько раз выстрелите ему в голову из ТОЗ-34, СВД или СВУ, поскольку шанс 75%. Проверьте сохранение, загрузку, переход и разделку ножом. В xray_user.log должны быть строки [GRM_CORPSE] hit и [GRM_GORE] CORPSE. При отсутствии результата передайте лог; всплывающих сообщений нет. jump_to_level перезаписывает автосейв.\n''',encoding='utf-8-sig')
with zipfile.ZipFile('/data/GRM_Corpse_Callback_FIX_TEST.zip','w',zipfile.ZIP_DEFLATED) as z:
 for f in pkg.rglob('*'):
  if f.is_file():z.write(f,f.relative_to(pkg))
with zipfile.ZipFile('/data/GRM_Corpse_Callback_FIX_TEST.zip') as z:assert z.testzip() is None
