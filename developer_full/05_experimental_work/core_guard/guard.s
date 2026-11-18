.intel_syntax noprefix
.section .patch,"ax"
.global guard
guard:
 pushfd
 pushad
 mov edx,DWORD PTR [esp+44]
 test edx,edx
 jz calc
 cmp DWORD PTR [esp+40],0
 je stop
calc:
 mov eax,DWORD PTR [ecx+0x1c]
 add eax,edx
 jc stop
 cmp eax,DWORD PTR [ecx+0x20]
 jbe resume
 test eax,0x80000000
 jnz stop
resume:
 popad
 popfd
 push esi
 mov esi,ecx
 mov eax,DWORD PTR [esi+0x1c]
 jmp normal
stop:
 call here
.global here
here:
 pop eax
 sub eax, OFFSET FLAT:here_rva
 push 0x47524d
 push -1
 call DWORD PTR [eax+0x2a0bc]
 ud2
