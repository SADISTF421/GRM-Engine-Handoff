.intel_syntax noprefix
.section .text
.global _start
_start:
    sub esp, 0x30
    mov ebp, OFFSET object
    mov edi, 0x12345678
    mov ebx, 0x33445566
    mov esi, 0x200000
    mov DWORD PTR [count], 5
    mov DWORD PTR [esp+0x10], 0x200000+540
    call hook
    cmp eax, 1
    jne fail
    cmp edi, 0x12345678
    jne fail
    cmp ebx, 0x33445566
    jne fail
    cmp esi, 0x200000
    jne fail
    cmp ebp, OFFSET object
    jne fail
    mov DWORD PTR [esp+0x10], 0x200000+648
    call hook
    cmp eax, 2
    jne fail
    mov DWORD PTR [esp+0x10], 0x200000+432
    call hook
    cmp eax, 2
    jne fail
    mov DWORD PTR [esp+0x10], 0x200000+541
    call hook
    cmp eax, 2
    jne fail
    mov DWORD PTR [count], 0
    mov DWORD PTR [esp+0x10], 0x200000+108
    call hook
    cmp eax, 2
    jne fail
    cmp DWORD PTR [logs],4
    jne fail
    cmp DWORD PTR [lastlive],0
    jne fail
    cmp DWORD PTR [lastsaved],108
    jne fail
    mov eax, 1
    xor ebx, ebx
    int 0x80
fail:
    mov eax, 1
    mov ebx, 1
    int 0x80
fake_count:
    mov eax, DWORD PTR [count]
    mov ecx, 0xabc
    mov edx, 0xdef
    ret
mock_log:
    inc DWORD PTR [logs]
    mov eax,[esp+8]
    mov [lastlive],eax
    mov eax,[esp+12]
    mov [lastsaved],eax
    mov eax,0x11
    mov ecx,0x22
    mov edx,0x33
    ret
.section .iatmsg,"a"
.long mock_log
.section .data
logs: .long 0
lastlive: .long 0
lastsaved: .long 0
count: .long 0
object: .long vtable
vtable: .space 0x198
.long fake_count
.section .hook,"ax"
hook: .incbin "/data/grm/engdiag/guard.bin"
.section .normal,"ax"
normal: mov eax,1
ret
.section .mismatch,"ax"
mismatch: mov eax,2
ret
