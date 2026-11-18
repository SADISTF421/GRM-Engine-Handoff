from pathlib import Path
import struct,hashlib,base64,zipfile
p=Path('/data/grm/engdiag'); out=p/'package';out.mkdir(exist_ok=True)
head=(p/'head.bin').read_bytes(); guard=(p/'guard.bin').read_bytes(); assert len(head)<=0x200 and len(guard)<=0x200
jump1=b'\xe9'+struct.pack('<i',0x1061f400-0x10146f10-5)+b'\x90';jump2=b'\xe9'+struct.pack('<i',0x1061f600-0x101f279a-5)+b'\x90'
hashes=[]
for name in ('original','particlefixed'):
 d=(Path('/data/grm/boneengine')/(name+'.dll')).read_bytes(); h=hashlib.sha256(d).hexdigest(); assert len(d)==0x603800 and d[0x146310:0x146316].hex()=='e98b834d0090' and d[0x1f1b9a:0x1f1ba0].hex()=='e9d1ca420090' and struct.unpack_from('<I',d,0x2c0)[0]==0x3cb and struct.unpack_from('<I',d,0x2c8)[0]==0x400
 a=bytearray(d+b'\0'*0x400);struct.pack_into('<I',a,0x2c0,0x600+len(guard));struct.pack_into('<I',a,0x2c8,0x800); a[0x146310:0x146316]=jump1;a[0x1f1b9a:0x1f1ba0]=jump2;a[0x603800:0x603800+len(head)]=head;a[0x603a00:0x603a00+len(guard)]=guard
 (p/(name+'_diag.dll')).write_bytes(a); hashes.append((h,hashlib.sha256(a).hexdigest()))
print('hashes',hashes)
s=r'''$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Split-Path -Parent $MyInvocation.MyCommand.Path))
$dll = Join-Path $root 'bin\xrGame.dll'
$exe = Join-Path $root 'bin\XR_3DA.exe'
$temp=$null; $backup=$null; $replaced=$false
function Hash([byte[]]$bytes) {
    $s = [Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($s.ComputeHash($bytes))).Replace('-','').ToLowerInvariant() } finally { $s.Dispose() }
}
function Put([byte[]]$dest, [int]$offset, [byte[]]$part) { [Array]::Copy($part, 0, $dest, $offset, $part.Length) }
function Hex([string]$text) {
    $data = New-Object byte[] ($text.Length / 2)
    for ($i=0; $i -lt $data.Length; $i++) { $data[$i] = [Convert]::ToByte($text.Substring($i*2,2),16) }
    return ,$data
}
try {
    [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding
    if (@(Get-Process | Where-Object { $_.ProcessName -like 'XR_3DA*' }).Count -gt 0) { throw 'Закройте игру. Ничего не изменено.' }
    foreach ($f in @($dll,$exe)) { if (!(Test-Path -LiteralPath $f -PathType Leaf)) { throw ('Не найден файл: '+$f+'. Ничего не изменено.') } }
    if ((Hash ([IO.File]::ReadAllBytes($exe))) -ne '5d52602915fbcbc25798b617a89303117edebb36fefef894ed0abd36e7cd634b') { throw 'XR_3DA.exe другой версии. Ничего не изменено.' }
    [byte[]]$old = [IO.File]::ReadAllBytes($dll)
    $h = Hash $old
    if ($h -eq 'OUT0' -or $h -eq 'OUT1') { Write-Host 'Диагностика уже установлена.'; exit 0 }
    if ($h -eq 'IN0') { $expected='OUT0' }
    elseif ($h -eq 'IN1') { $expected='OUT1' }
    else { throw ('xrGame.dll отличается от двух проверенных версий. Ничего не изменено. SHA256: '+$h) }
    [byte[]]$data = New-Object byte[] ($old.Length + 0x400)
    [Array]::Copy($old, $data, $old.Length)
    Put $data 0x2c0 (Hex 'VIRTUAL')
    Put $data 0x2c8 (Hex '00080000')
    Put $data 0x146310 (Hex 'JUMP1')
    Put $data 0x1f1b9a (Hex 'JUMP2')
    Put $data 0x603800 ([Convert]::FromBase64String('HEAD'))
    Put $data 0x603a00 ([Convert]::FromBase64String('GUARD'))
    if ((Hash $data) -ne $expected) { throw 'Проверка патча не пройдена. Ничего не изменено.' }
    $dir = Split-Path -Parent $dll
    $temp = Join-Path $dir ([IO.Path]::GetRandomFileName() + '.tmp')
    $backup = Join-Path $dir ([IO.Path]::GetRandomFileName() + '.bak')
    [IO.File]::WriteAllBytes($temp,$data)
    if ((Hash ([IO.File]::ReadAllBytes($temp))) -ne $expected) { throw 'Проверка записи не пройдена. Ничего не изменено.' }
    [IO.File]::Replace($temp,$dll,$backup); $temp=$null; $replaced=$true
    if ((Hash ([IO.File]::ReadAllBytes($dll))) -ne $expected) { throw 'Проверка установленной DLL не пройдена.' }
    Remove-Item -LiteralPath $backup -Force -ErrorAction SilentlyContinue; $backup=$null
    Write-Host 'Диагностика движка установлена.'
} catch {
    Write-Host ('ОШИБКА: '+$_.Exception.Message)
    if ($replaced -and $backup -and (Test-Path -LiteralPath $backup)) {
        try { $discard = Join-Path (Split-Path -Parent $dll) ([IO.Path]::GetRandomFileName()+'.tmp'); [IO.File]::Replace($backup,$dll,$discard); Remove-Item -LiteralPath $discard -Force -ErrorAction SilentlyContinue; $backup=$null; Write-Host 'Прежняя DLL восстановлена.' }
        catch { Write-Host ('Исходная DLL сохранена здесь: '+$backup) }
    }
    exit 1
} finally { if ($temp -and (Test-Path -LiteralPath $temp)) { Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue } }
'''
for a,b in {'IN0':hashes[0][0],'IN1':hashes[1][0],'OUT0':hashes[0][1],'OUT1':hashes[1][1],'HEAD':base64.b64encode(head).decode(),'GUARD':base64.b64encode(guard).decode(),'JUMP1':jump1.hex(),'JUMP2':jump2.hex(),'VIRTUAL':struct.pack('<I',0x600+len(guard)).hex()}.items(): s=s.replace(a,b)
(out/'GRM_Engine_Debug_TEST.ps1').write_text(s,encoding='utf-8-sig',newline='\r\n')
(out/'INSTALL_GRM_Engine_Debug_TEST.bat').write_bytes(b'@echo off\r\nchcp 65001 >nul\r\npowershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0GRM_Engine_Debug_TEST.ps1"\r\npause\r\n')
r='''ДИАГНОСТИКА ДВИЖКА GRM — ЭКСПЕРИМЕНТ\r\n\r\nЗакройте игру. Сделайте полный бэкап игры и сохранений. Распакуйте архив в папку игры рядом с bin и gamedata и запустите INSTALL_GRM_Engine_Debug_TEST.bat. Установщик изменяет только bin\\xrGame.dll, проверяет хэши EXE и DLL и отказывается работать с другими версиями. Скрипты, модели и другие файлы игры не меняются.\r\n\r\nВ логе xray_user.log [GRM_HEAD_DIAG] показывает имя модели и номер кости при скрытии головы; [GRM_PHYS_DIAG] сообщает о несовпадении количества данных физики при восстановлении. Отсутствие сообщений не доказывает отсутствие ошибок. Диагностика не создаёт crash dump и не исправляет растянутые полигоны.\r\n\r\nВ игре диагностика не проверена; сохранения и переходы проверяйте на копии старого сохранения. jump_to_level перезаписывает user_autosave.sav. После воспроизведения проблемы отправьте xray_user.log целиком.\r\n'''
(out/'ПРОЧТИ.txt').write_bytes(r.encode('utf-8-sig'))
with zipfile.ZipFile('/data/GRM_Engine_Debug_TEST.zip','w',zipfile.ZIP_DEFLATED) as z:
 for f in out.iterdir(): z.write(f,f.name)
