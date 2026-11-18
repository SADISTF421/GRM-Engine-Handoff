from pathlib import Path
import hashlib,zipfile
root=Path('/data/grm/cleanpatch'); pkg=root/'package'; payload=pkg/'GRM_CleanDiag'
h=lambda b:hashlib.sha256(b).hexdigest()
gore=[Path('/data/grm/chance75/package/GRM_Chance75/grm_gore_test.script'),Path('/data/grm/fasthead/grm_gore_fast.script')]
binders=[Path('/data/grm/current/scripts.rar/scripts/bind_stalker.script'),Path('/data/grm/savefix/gamedata/scripts/bind_stalker.script')]
old=b'''    pcall(function()
        if db and db.actor then
            db.actor:give_game_news("GORE: " .. text, "ui\\\\ui_iconsTotal", Frect():set(83,470,83,47), 0, 5000)
        end
    end)
'''
rows=[]
for i,p in enumerate(gore):
 b=p.read_bytes();nl=b'\r\n' if b'\r\n' in b else b'\n'; needle=old.replace(b'\n',nl); assert b.count(needle)==1,(p,b.count(needle)); data=b.replace(needle,b'',1); assert b'give_game_news' not in data
 name=f'gore{i}.script';(payload/name).write_bytes(data);rows.append(('grm_gore_test.script',h(b),h(data),name))
probe=b'''    local function grm_save_probe(label)
        pcall(function() printf("[GRM_ACTOR_BYTES] %s %u", label, packet:w_tell()) end)
    end
    grm_save_probe("start")
'''
for i,p in enumerate(binders):
 b=p.read_bytes();nl=b'\r\n' if b'\r\n' in b else b'\n'; a=b'function actor_binder:save(packet)';end=b'function actor_binder:load(reader)'; assert b.count(a)==b.count(end)==1
 pos=b.index(a); last=b.index(end,pos); block=b[pos:last];assert block.count(a)==1
 block=block.replace(a,a+nl+probe.replace(b'\n',nl),1)
 for call,label in [(b'object_binder.save(self, packet)',b'binder'),(b'xr_logic.pstor_save_all(self.object, packet)',b'pstor'),(b'self.weather_manager:save(packet)',b'weather'),(b'sr_psy_antenna.save( packet )',b'antenna'),(b'treasure_manager.save(packet)',b'treasure'),(b'task_manager.save(packet)',b'tasks'),(b'self.actor_detector:save(packet)',b'detector')]:
  assert block.count(call)==1,(p,call);block=block.replace(call,call+nl+b'    grm_save_probe("'+label+b'")',1)
 data=b[:pos]+block+b[last:]; name=f'binder{i}.script';(payload/name).write_bytes(data);rows.append(('bind_stalker.script',h(b),h(data),name))
for row in rows:print(*row)
ps='''$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Split-Path -Parent $MyInvocation.MyCommand.Path))
function Hash([string]$p) { return (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLowerInvariant() }
function Install-One([string]$target,[string]$payload,[string]$expected) {
 $dir=Split-Path -Parent $target; $tmp=Join-Path $dir ([IO.Path]::GetRandomFileName()+'.tmp'); $bak=Join-Path $dir ([IO.Path]::GetRandomFileName()+'.bak'); $replaced=$false
 try {
  if ((Hash $payload) -ne $expected) { throw 'Файл патча повреждён.' }
  [IO.File]::Copy($payload,$tmp)
  if ((Hash $tmp) -ne $expected) { throw 'Ошибка проверки записи.' }
  [IO.File]::Replace($tmp,$target,$bak); $replaced=$true
  if ((Hash $target) -ne $expected) { throw 'Ошибка проверки установленного файла.' }
  Remove-Item -LiteralPath $bak -Force -ErrorAction SilentlyContinue; $bak=$null
 } catch {
  if ($replaced -and $bak -and (Test-Path -LiteralPath $bak)) {
   try { $discard=Join-Path $dir ([IO.Path]::GetRandomFileName()+'.tmp'); [IO.File]::Replace($bak,$target,$discard); Remove-Item -LiteralPath $discard -Force -ErrorAction SilentlyContinue; $bak=$null }
   catch { Write-Host ('Исходный файл находится здесь: '+$bak) }
  }; throw
 } finally { if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue } }
}
try {
 [Console]::OutputEncoding=New-Object System.Text.UTF8Encoding
 if (@(Get-Process | Where-Object { $_.ProcessName -like 'XR_3DA*' }).Count -gt 0) { throw 'Закройте игру.' }
 $exe=Join-Path $root 'bin\\XR_3DA.exe'; $dll=Join-Path $root 'bin\\xrGame.dll'
 foreach ($f in @($exe,$dll)) { if (!(Test-Path -LiteralPath $f -PathType Leaf)) { throw ('Не найден: '+$f+'. Распакуйте архив в папку игры.') } }
 if ((Hash $exe) -ne '5d52602915fbcbc25798b617a89303117edebb36fefef894ed0abd36e7cd634b') { throw 'Другая версия EXE.' }
 if (@('c5f1968e680b1bef8d000a0a2d37adf343026628994fffcb138fea1c3130e9fb','4a6e84f3397b853124158865bd71b54f9c438d11384bad6a90eaa08c20216959') -notcontains (Hash $dll)) { throw 'Другая версия xrGame.dll.' }
 $specs = @(
ROWS
 )
 foreach ($name in @('grm_gore_test.script','bind_stalker.script')) {
  $target=Join-Path $root ('gamedata\\scripts\\'+$name)
  if (!(Test-Path -LiteralPath $target -PathType Leaf)) { Write-Host ($name+': файл не найден, пропущен.'); continue }
  $hash=Hash $target; $choices=@($specs | Where-Object { $_.target -eq $name }); $done=$false
  foreach ($c in $choices) { if ($hash -eq $c.new) { Write-Host ($name+': уже установлен.'); $done=$true; break } }
  if ($done) { continue }
  $entry=$choices | Where-Object { $_.old -eq $hash } | Select-Object -First 1
  if (!$entry) { Write-Host ($name+': неизвестная версия, пропущен. SHA256: '+$hash); continue }
  $payload=Join-Path $root ('GRM_CleanDiag\\'+$entry.file)
  if (!(Test-Path -LiteralPath $payload -PathType Leaf)) { throw ('Не найден файл патча: '+$payload) }
  Install-One $target $payload $entry.new
  Write-Host ($name+': установлен.')
 }
} catch { Write-Host ('ОШИБКА: '+$_.Exception.Message); exit 1 }
'''
psrows=',\n'.join("  [pscustomobject]@{target='%s';old='%s';new='%s';file='%s'}"%row for row in rows)
(pkg/'GRM_CleanDiag.ps1').write_text(ps.replace('ROWS',psrows),encoding='utf-8-sig',newline='\r\n')
(pkg/'INSTALL_GRM_CleanDiag.bat').write_bytes(b'@echo off\r\nchcp 65001 >nul\r\npowershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0GRM_CleanDiag.ps1"\r\npause\r\n')
(pkg/'ПРОЧТИ.txt').write_text('''ЭКСПЕРИМЕНТ: ДИАГНОСТИКА И УМЕНЬШЕНИЕ МУСОРА\n\nЗакройте игру. Создайте полный бэкап игры и сохранений. Распакуйте архив в папку игры, запустите INSTALL_GRM_CleanDiag.bat. Проверяются версии EXE, DLL и каждого скрипта; неподходящие скрипты пропускаются отдельно.\n\nДля GORE убрана отправка диагностических сообщений в PDA. Диагностика остаётся в xray_user.log; кровь, звуки, скрытие, шанс и частицы не меняются. Старые новости PDA не удаляются. Реестр сообщений хранится движком и сериализуется в сохранениях, но связь с последним вылетом не доказана.\n\nВ скрипт игрока добавлены замеры [GRM_ACTOR_BYTES] перед сохранением и после его этапов. Формат сейва не меняется. Замеры не исправляют переполнение. Увеличение лимита пакета и удаление частиц не выполняется.\n\nПатч не проверен в игре. Используйте копию ручного сейва. После убийств проверьте повторные сохранения, загрузку и переход; новый xray_user.log содержит измерения.\n''',encoding='utf-8-sig')
with zipfile.ZipFile('/data/GRM_Gore_Clean_Save_Diag_TEST.zip','w',zipfile.ZIP_DEFLATED) as z:
 for f in pkg.rglob('*'):
  if f.is_file():z.write(f,f.relative_to(pkg))
with zipfile.ZipFile('/data/GRM_Gore_Clean_Save_Diag_TEST.zip') as z: assert z.testzip() is None
