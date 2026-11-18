from pathlib import Path
import hashlib,struct,sys,zipfile
sys.path.insert(0,'/data/grm/pylibs');import pefile
r=Path('/data/grm/corpsegore'); pkg=r/'package'; dest=pkg/'GRM_Corpse';dest.mkdir(parents=True,exist_ok=True)
h=lambda b:hashlib.sha256(b).hexdigest()
engine=[('/data/grm/newbin_last/bin/xrGame.dll','c5f1968e680b1bef8d000a0a2d37adf343026628994fffcb138fea1c3130e9fb'),('/data/grm/ogsrpose/package/GRM_OGSR_POSE/xrGame.dll','4a6e84f3397b853124158865bd71b54f9c438d11384bad6a90eaa08c20216959')]
rows=[]
for i,(name,expected) in enumerate(engine):
 b=Path(name).read_bytes();assert h(b)==expected;p=pefile.PE(data=b);assert p.OPTIONAL_HEADER.ImageBase==0x10000000
 sec=[x for x in p.sections if x.Name.rstrip(b'\0')==b'.grm'];assert len(sec)==1;sec=sec[0];assert sec.VirtualAddress==0x61f000 and sec.PointerToRawData==0x603400
 hook=(r/'hook.bin').read_bytes();assert len(hook)==179 and len(b)<=0x604000
 out=bytearray(b)+bytearray(0x604400-len(b)); assert out[0x604000:0x604000+len(hook)]==bytes(len(hook));out[0x604000:0x604000+len(hook)]=hook
 struct.pack_into('<I',out,sec.get_file_offset()+8,0xc00+len(hook));struct.pack_into('<I',out,sec.get_file_offset()+16,0x1000)
 sites=[(0x1012006e,'76268b542410',0x1061fc00),(0x10013b32,'0f8612020000',0x1061fc3c),(0x10013bd1,'85f60f8471010000',0x1061fc70)]
 rels={x.rva for block in p.DIRECTORY_ENTRY_BASERELOC for x in block.entries if x.type}
 for va,old,hookva in sites:
  orig=bytes.fromhex(old);off=p.get_offset_from_rva(va-0x10000000);assert b[off:off+len(orig)]==orig,(name,hex(va));assert not any(va-0x10000000<=q<va-0x10000000+len(orig) for q in rels)
  out[off:off+len(orig)]=b'\xe9'+struct.pack('<i',hookva-(va+5))+b'\x90'*(len(orig)-5)
 q=pefile.PE(data=bytes(out));assert q.sections[-1].Misc_VirtualSize==0xcb3 and q.sections[-1].SizeOfRawData==0x1000 and q.OPTIONAL_HEADER.SizeOfImage>=0x61fcb3
 filename=f'engine{i}.dll';(dest/filename).write_bytes(out);rows.append(('bin\\xrGame.dll',expected,h(out),filename))
base=Path('/data/grm/current/scripts.rar/scripts/xr_motivator.script').read_bytes();assert h(base)=='70213e46b6a60b54befd23581f6998aeb27b51910424e9b7a692c0eabe8ba9c8'
nl=b'\r\n' if b'\r\n' in base else b'\n';needle=b'function motivator_binder:hit_callback(obj, amount, local_direction, who, bone_index)'+nl
insert='''\t-- Попадания по трупам не передаются в обработчики живого НПС.\n\tif not self.object:alive() then\n\t\tpcall(function() grm_gore_test.corpse_hit(self, who, bone_index) end)\n\t\treturn\n\tend\n'''.encode('cp1251').replace(b'\n',nl);assert base.count(needle)==1
out=base.replace(needle,needle+insert);(dest/'motivator.script').write_bytes(out);rows.append(('gamedata\\scripts\\xr_motivator.script',h(base),h(out),'motivator.script'))
oldgore=[Path('/data/grm/chance75/package/GRM_Chance75/grm_gore_test.script'),Path('/data/grm/fasthead/grm_gore_fast.script')]
for i in range(2):
 old=Path(f'/data/grm/cleanpatch/package/GRM_CleanDiag/gore{i}.script').read_bytes();nl=b'\r\n' if b'\r\n' in old else b'\n';needle=b'function death(binder, who)';assert old.count(needle)==1
 insert='''-- Для трупов учитываем только попадание игрока в кость головы.\nfunction corpse_hit(binder, who, bone)\n    if not binder or not binder.object or binder.object:alive() then return end\n    if binder.grm_gore_pending or binder.grm_gore_anchored then return end\n    local kind, section = actor_weapon(who)\n    if not kind or not setup() then return end\n    local ok, id = pcall(function() return binder.object:bone_position("__grm_test_head_id__").x end)\n    id = ok and tonumber(id) or nil\n    if not id or id < 0 or id >= 64 or tonumber(bone) ~= id then return end\n    if math.random(1, 100) > 75 then\n        notice("CORPSE CHANCE SKIPPED")\n        return\n    end\n    notice("CORPSE HEAD HIT " .. tostring(section))\n    schedule_hide(binder)\nend\n'''.encode('cp1251').replace(b'\n',nl)
 out=old.replace(needle,insert+needle,1); comment='-- Попадания по уже мёртвым НПС пока не обрабатываются.'.encode('cp1251'); assert out.count(comment)==1;out=out.replace(comment,'-- Попадания по трупам проверяются отдельно.'.encode('cp1251'));filename=f'gore{i}.script';(dest/filename).write_bytes(out)
 for prev in [old,oldgore[i].read_bytes()]:rows.append(('gamedata\\scripts\\grm_gore_test.script',h(prev),h(out),filename))
print('\n'.join(' '.join(row) for row in rows))
ps=r'''$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Split-Path -Parent $MyInvocation.MyCommand.Path))
function Hash([string]$p) { return (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLowerInvariant() }
$entries=@(
ROWS
)
$changes=New-Object System.Collections.ArrayList
try {
 [Console]::OutputEncoding=New-Object System.Text.UTF8Encoding
 if (@(Get-Process | Where-Object { $_.ProcessName -like 'XR_3DA*' }).Count -gt 0) { throw 'Закройте игру.' }
 $exe=Join-Path $root 'bin\XR_3DA.exe'
 if (!(Test-Path -LiteralPath $exe -PathType Leaf) -or (Hash $exe) -ne '5d52602915fbcbc25798b617a89303117edebb36fefef894ed0abd36e7cd634b') { throw 'EXE не совпадает. Файлы не изменены.' }
 foreach ($name in @('bin\xrGame.dll','gamedata\scripts\xr_motivator.script','gamedata\scripts\grm_gore_test.script')) {
  $target=Join-Path $root $name
  if (!(Test-Path -LiteralPath $target -PathType Leaf)) { throw ('Нет файла: '+$name) }
  $hash=Hash $target; $choices=@($entries | Where-Object { $_.target -eq $name })
  if (@($choices | Where-Object { $_.new -eq $hash }).Count -gt 0) { continue }
  $entry=$choices | Where-Object { $_.old -eq $hash } | Select-Object -First 1
  if (!$entry) { throw ('Неизвестная версия: '+$name+' SHA256: '+$hash) }
  $payload=Join-Path $root ('GRM_Corpse\'+$entry.file)
  if (!(Test-Path -LiteralPath $payload -PathType Leaf) -or (Hash $payload) -ne $entry.new) { throw ('Повреждён файл патча: '+$entry.file) }
  $dir=Split-Path -Parent $target
  $tmp=Join-Path $dir ([IO.Path]::GetRandomFileName()+'.tmp')
  $bak=Join-Path $dir ([IO.Path]::GetRandomFileName()+'.bak')
  [void]$changes.Add([pscustomobject]@{target=$target;payload=$payload;expected=$entry.new;tmp=$tmp;bak=$bak;replaced=$false})
 }
 foreach ($c in $changes) { [IO.File]::Copy($c.payload,$c.tmp); if ((Hash $c.tmp) -ne $c.expected) { throw 'Ошибка проверки временного файла.' } }
 foreach ($c in $changes) { [IO.File]::Replace($c.tmp,$c.target,$c.bak); $c.replaced=$true; if ((Hash $c.target) -ne $c.expected) { throw 'Ошибка проверки установленного файла.' } }
 foreach ($c in $changes) { if (Test-Path -LiteralPath $c.bak) { Remove-Item -LiteralPath $c.bak -Force -ErrorAction SilentlyContinue } }
 Write-Host 'Готово. Проверяйте в игре на копии сохранения.'
} catch {
 Write-Host ('ОШИБКА: '+$_.Exception.Message)
 for ($i=$changes.Count-1; $i -ge 0; $i--) { $c=$changes[$i]; if ($c.replaced -and (Test-Path -LiteralPath $c.bak)) { try { $discard=Join-Path (Split-Path -Parent $c.target) ([IO.Path]::GetRandomFileName()+'.tmp'); [IO.File]::Replace($c.bak,$c.target,$discard); Remove-Item -LiteralPath $discard -Force -ErrorAction SilentlyContinue } catch { Write-Host ('Исходный файл: '+$c.bak) } } }
 exit 1
} finally { foreach ($c in $changes) { if (Test-Path -LiteralPath $c.tmp) { Remove-Item -LiteralPath $c.tmp -Force -ErrorAction SilentlyContinue } } }
'''
psrows=',\n'.join(" [pscustomobject]@{target='%s';old='%s';new='%s';file='%s'}"%row for row in rows)
(pkg/'GRM_Corpse.ps1').write_text(ps.replace('ROWS',psrows),encoding='utf-8-sig',newline='\r\n')
(pkg/'INSTALL_GRM_Corpse.bat').write_bytes(b'@echo off\r\nchcp 65001 >nul\r\npowershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0GRM_Corpse.ps1"\r\npause\r\n')
(pkg/'ПРОЧТИ.txt').write_text('''ЭКСПЕРИМЕНТ: ПОПАДАНИЕ В ГОЛОВУ ТРУПА\n\nЗакройте игру. Сделайте полный бэкап игры и сохранений. Распакуйте архив в корень игры и запустите INSTALL_GRM_Corpse.bat. Установщик проверяет EXE и точные версии трёх изменяемых файлов; при несовпадении ничего не меняет и выводит SHA256.\n\nТолько попадания игрока по кости головы из поддерживаемых дробовиков, СВД и СВУ. Шанс 75%, эффекты и задержка вашего варианта сохраняются. Всплывающие диагностические сообщения убраны. После перезагрузки защита от повторного срабатывания на том же трупе не сохраняется; не во всякую скрытую голову можно попасть. Сохранения, рэгдоллы, логику ранений и другие механики патч специально не меняет, но совместимость не доказана.\n\nПроверено в имитации, НЕ проверено в игре. На копии старого ручного сейва проверьте убийства и выстрелы в труп, повторное сохранение, загрузку и переход. jump_to_level перезаписывает user_autosave.sav. Патч не исправляет подтверждённо растянутые полигоны или прежние вылеты.\n''',encoding='utf-8-sig')
with zipfile.ZipFile('/data/GRM_Corpse_Headshot_TEST.zip','w',zipfile.ZIP_DEFLATED,compresslevel=9) as z:
 for f in pkg.rglob('*'):
  if f.is_file():z.write(f,f.relative_to(pkg))
with zipfile.ZipFile('/data/GRM_Corpse_Headshot_TEST.zip') as z:assert z.testzip() is None
