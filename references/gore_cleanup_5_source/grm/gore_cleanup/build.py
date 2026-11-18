from pathlib import Path
import hashlib,json,zipfile,shutil
r=Path('/data/grm/gore_cleanup');pkg=r/'package';shutil.rmtree(pkg,ignore_errors=True);(pkg/'GRM_Cleanup').mkdir(parents=True)
sha=lambda b:hashlib.sha256(b).hexdigest(); rows=json.loads((r/'rows.json').read_text());shutil.copytree(r/'payload',pkg/'GRM_Cleanup',dirs_exist_ok=True)
dllsrc=['/data/grm/newbin_last/bin/xrGame.dll','/data/grm/ogsrpose/package/GRM_OGSR_POSE/xrGame.dll','/data/grm/corpsegore/package/GRM_Corpse/engine0.dll','/data/grm/corpsegore/package/GRM_Corpse/engine1.dll']; versions=[Path(x).read_bytes() for x in dllsrc]
for x in list(versions):
 n=bytearray(x)
 for off in (0x7285e,0x728b5): assert n[off:off+7]==bytes.fromhex('e89dbd5a009090') if off==0x7285e else n[off:off+7]==bytes.fromhex('e846bd5a009090'); n[off:off+7]=bytes.fromhex('8b842418200000')
 versions.append(bytes(n))
dllrows=[]
for b in versions:
 assert b[0x6038ee:0x6038f1]==bytes.fromhex('8b0424') and b[0x60391b:0x603921]==bytes.fromhex('c7060000803f')
 d=bytearray(b);d[0x6038ee:0x6038f0]=bytes.fromhex('eb2b');dllrows.append({'old':sha(b),'new':sha(d)})
def psrows(rows):return ',\n'.join('[pscustomobject]@{old=\'%s\';new=\'%s\'%s}'%(x['old'],x['new'],";file='%s'"%x['file'] if 'file' in x else '') for x in rows)
ps=r'''$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Split-Path -Parent $MyInvocation.MyCommand.Path))
function Hash([string]$p) { (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLowerInvariant() }
$ss=@(
SCRIPTROWS
)
$ds=@(
DLLROWS
)
$work=@();$success=$false
try {
 [Console]::OutputEncoding=New-Object System.Text.UTF8Encoding
 if (@(Get-Process | Where-Object { $_.ProcessName -like 'XR_3DA*' }).Count -gt 0) { throw 'Закройте игру.' }
 $exe=Join-Path $root 'bin\XR_3DA.exe';$dll=Join-Path $root 'bin\xrGame.dll';$script=Join-Path $root 'gamedata\scripts\grm_gore_test.script'
 foreach ($p in @($exe,$dll,$script)) { if (!(Test-Path -LiteralPath $p -PathType Leaf)) { throw ('Нет файла: '+$p) } }
 if (@('5d52602915fbcbc25798b617a89303117edebb36fefef894ed0abd36e7cd634b','ae91b0b55e7e9d80a5dee21213ae4224d6d6809fbe99d1fbac5dd54f8cbbc525') -notcontains (Hash $exe)) { throw 'Неизвестная версия EXE. Изменений нет.' }
 $sh=Hash $script;$dh=Hash $dll
 $sr=$ss | Where-Object { $_.old -eq $sh -or $_.new -eq $sh } | Select-Object -First 1
 $dr=$ds | Where-Object { $_.old -eq $dh -or $_.new -eq $dh } | Select-Object -First 1
 if (!$sr) { throw ('Неизвестная версия скрипта. SHA256: '+$sh) }
 if (!$dr) { throw ('Неизвестная версия xrGame.dll. SHA256: '+$dh) }
 if ($sh -ne $sr.new) {
  $source=Join-Path $root ('GRM_Cleanup\'+$sr.file)
  if (!(Test-Path -LiteralPath $source -PathType Leaf) -or (Hash $source) -ne $sr.new) { throw 'Нет файла патча либо он повреждён.' }
  $dir=Split-Path -Parent $script; $tmp=Join-Path $dir ([IO.Path]::GetRandomFileName()+'.tmp');$bak=Join-Path $dir ([IO.Path]::GetRandomFileName()+'.bak')
  [IO.File]::Copy($source,$tmp);$work+=,[pscustomobject]@{target=$script;temp=$tmp;backup=$bak;new=$sr.new;done=$false}
 }
 if ($dh -ne $dr.new) {
  [byte[]]$bytes=[IO.File]::ReadAllBytes($dll)
  if ($bytes[0x6038ee] -ne 0x8b -or $bytes[0x6038ef] -ne 0x04 -or $bytes[0x6038f0] -ne 0x24) { throw 'Проверка инструкций DLL не пройдена.' }
  $bytes[0x6038ee]=0xeb; $bytes[0x6038ef]=0x2b
  $dir=Split-Path -Parent $dll; $tmp=Join-Path $dir ([IO.Path]::GetRandomFileName()+'.tmp');$bak=Join-Path $dir ([IO.Path]::GetRandomFileName()+'.bak')
  [IO.File]::WriteAllBytes($tmp,$bytes);$work+=,[pscustomobject]@{target=$dll;temp=$tmp;backup=$bak;new=$dr.new;done=$false}
 }
 foreach ($w in $work) { if ((Hash $w.temp) -ne $w.new) { throw 'Проверка подготовленных файлов не пройдена.' } }
 foreach ($w in $work) { [IO.File]::Replace($w.temp,$w.target,$w.backup);$w.done=$true; if ((Hash $w.target) -ne $w.new) { throw 'Проверка установки не пройдена.' } }
 $success=$true
 foreach ($w in $work) { if (Test-Path -LiteralPath $w.backup) { Remove-Item -LiteralPath $w.backup -Force -ErrorAction SilentlyContinue } }
 Write-Host 'Патч очистки установлен. Если уже установлен, изменений нет.'
} catch {
 Write-Host ('ОШИБКА: '+$_.Exception.Message)
 [array]::Reverse($work)
 foreach ($w in $work) { if ($w.done -and (Test-Path -LiteralPath $w.backup)) { try { $discard=Join-Path (Split-Path -Parent $w.target) ([IO.Path]::GetRandomFileName()+'.tmp');[IO.File]::Replace($w.backup,$w.target,$discard);Remove-Item -LiteralPath $discard -Force -ErrorAction SilentlyContinue } catch { Write-Host ('Исходный файл сохранён: '+$w.backup) } } }
 exit 1
} finally { foreach ($w in $work) { if (Test-Path -LiteralPath $w.temp) { Remove-Item -LiteralPath $w.temp -Force -ErrorAction SilentlyContinue } } }
'''.replace('SCRIPTROWS',psrows(rows)).replace('DLLROWS',psrows(dllrows))
(pkg/'GRM_Cleanup.ps1').write_text(ps,encoding='utf-8-sig',newline='\r\n');(pkg/'INSTALL_GRM_Cleanup.bat').write_bytes(b'@echo off\r\nchcp 65001 >nul\r\npowershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0GRM_Cleanup.ps1"\r\npause\r\n')
(pkg/'ПРОЧТИ.txt').write_text('''ЭКСПЕРИМЕНТ: ОЧИСТКА GORE\n\nЗакройте игру. Сделайте полный бэкап игры и сохранений. Распакуйте архив в папку игры; запустите INSTALL_GRM_Cleanup.bat. Установщик сверяет EXE, DLL и скрипт. При несовпадении версий он откажется от установки. Изменяются только gamedata\\scripts\\grm_gore_test.script и два байта bin\\xrGame.dll; EXE не меняется. Существующие эффекты, шанс и вариант обработки трупов сохраняются.\n\nПоследнее подтверждённое попадание в тело отменяет отметку головы; запись живого NPC истекает через 300 мс. Это меняет поведение при смешанных попаданиях дроби одного выстрела. Если попадание не установлено, прежняя проверка прицеливания остаётся. После смерти временные данные удаляются.\n\nКровь запускается до 5 секунд, последние частицы не обрываются: свободные объекты освобождаются не ранее 10 секунд после запуска, после проверки что уже не играют и только когда вызывается обновление скрипта. Пул ограничен, в случае перехода старые ссылки отбрасываются без опроса выгруженных объектов; гарантий безопасности нет. Состояние головы и физика специально не переписываются.\n\nОбычные сообщения GRM_GORE и GRM_HEAD_DIAG отключены; сообщения об ошибках ограничены. Для подробного скриптового лога в grm_gore_test.script изменить GORE_DEBUG с false на true; повторная установка тогда отклонит этот файл как неизвестный. Это не включает старую диагностику движка.\n\nВ игре патч не проверен и не гарантирует отсутствия вылетов. Проверьте ТОЗ/СВД/СВУ, тело после головы, кровотечение, сохранение, загрузку и переход. Используйте копию старого ручного сейва; jump_to_level перезаписывает user_autosave.sav.\n''',encoding='utf-8-sig')
(r/'dllrows.json').write_text(json.dumps(dllrows,indent=2));
with zipfile.ZipFile('/data/GRM_Gore_Cleanup_5_TEST.zip','w',zipfile.ZIP_DEFLATED) as z:
 for f in pkg.rglob('*'):
  if f.is_file():z.write(f,f.relative_to(pkg))
with zipfile.ZipFile('/data/GRM_Gore_Cleanup_5_TEST.zip') as z:assert z.testzip() is None
print('script mappings',len(rows),'DLL mappings',len(dllrows))
