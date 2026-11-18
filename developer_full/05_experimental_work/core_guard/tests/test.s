.intel_syntax noprefix
.section .hook,"ax"
hook: .incbin "hook.bin"
.section .normal,"ax"
normal:
 pushfd
 pop DWORD PTR [flags_seen]
 cmp esi, OFFSET FLAT:writer
 jne fail
 cmp eax,DWORD PTR [writer+0x1c]
 jne fail
 pop esi
 ret 8
.section .guard,"ax"
.incbin "guard.bin"
.section .iat,"aw"
.long fake_terminate
.section .start,"ax"
.global _start
_start:
 mov DWORD PTR [writer+0x1c], 0
 mov DWORD PTR [writer+0x20], 128
 mov DWORD PTR [src], 1
 mov DWORD PTR [n], 1
 mov DWORD PTR [bad],0
 mov eax,DWORD PTR [esp]
 cmp eax,1
 jbe run
 mov eax,DWORD PTR [esp+8]
 mov al,BYTE PTR [eax]
 cmp al,'1'
 jne try2
 mov DWORD PTR [n],1000000
 jmp run
try2: cmp al,'2'
 jne try3
 mov DWORD PTR [writer+0x1c],0xfffffff0
 mov DWORD PTR [n],32
 mov DWORD PTR [bad],1
 jmp run
try3: cmp al,'3'
 jne try4
 mov DWORD PTR [n],0x80000000
 mov DWORD PTR [bad],1
 jmp run
try4: cmp al,'4'
 jne try5
 mov DWORD PTR [src],0
 mov DWORD PTR [bad],1
 jmp run
try5: cmp al,'5'
 jne run
 mov DWORD PTR [src],0
 mov DWORD PTR [n],0
run:
 mov DWORD PTR [saved_esp],esp
 mov ecx,OFFSET FLAT:writer
 mov esi,0x11223344
 mov edi,0x55443322
 mov ebx,0x12345678
 mov ebp,0x76543210
 stc
 push DWORD PTR [n]
 push DWORD PTR [src]
 call hook
 cmp DWORD PTR [bad],0
 jne fail
 cmp esp,DWORD PTR [saved_esp]
 jne fail
 cmp esi,0x11223344
 jne fail
 cmp edi,0x55443322
 jne fail
 cmp ebx,0x12345678
 jne fail
 cmp ebp,0x76543210
 jne fail
 test DWORD PTR [flags_seen],1
 jz fail
success:
 mov eax,1
 xor ebx,ebx
 int 0x80
fail:
 mov eax,1
 mov ebx,1
 int 0x80
fake_terminate:
 cmp DWORD PTR [bad],1
 jne fail
 cmp DWORD PTR [esp+4],-1
 jne fail
 cmp DWORD PTR [esp+8],0x47524d
 jne fail
 jmp success
.section .data,"aw"
writer: .space 0x28
n: .long 0
src: .long 0
bad: .long 0
saved_esp: .long 0
flags_seen: .long 0
