.intel_syntax noprefix
.section .text
.global _start
_start:
  mov DWORD PTR [obj],0x10484334
  mov DWORD PTR [obj+0x1a4],0x12345678
  mov DWORD PTR [po+0x10],0xffffffdf
  mov DWORD PTR [po+0x14],0xffffffff
  mov WORD PTR [po+0x18],0
  mov DWORD PTR [boneid],5
  mov DWORD PTR [cnt],0
  call doearly
  cmp DWORD PTR [cnt],0
  jne fail
  call dolate
  cmp DWORD PTR [cnt],1
  jne fail
  cmp DWORD PTR [lastlow],0xffffffdf
  jne fail
  cmp DWORD PTR [lasthi],0xffffffff
  jne fail
  cmp DWORD PTR [logs],1
  jne fail
  mov DWORD PTR [obj],0x10491c3c
  mov DWORD PTR [cnt],0
  call doearly
  call dolate
  cmp DWORD PTR [cnt],1
  jne fail
  mov DWORD PTR [obj],0x10484334
  mov DWORD PTR [po+0x10],0xffffffff
  mov DWORD PTR [cnt],0
  call doearly
  call dolate
  cmp DWORD PTR [cnt],1
  jne fail
  mov DWORD PTR [po+0x10],0xffffffdf
  mov WORD PTR [po+0x18],1
  mov DWORD PTR [cnt],0
  call doearly
  call dolate
  cmp DWORD PTR [cnt],1
  jne fail
  mov WORD PTR [po+0x18],0
  mov DWORD PTR [boneid],0xffff
  mov DWORD PTR [cnt],0
  call doearly
  call dolate
  cmp DWORD PTR [cnt],1
  jne fail
  mov DWORD PTR [boneid],40
  mov DWORD PTR [po+0x10],0xffffffff
  mov DWORD PTR [po+0x14],0xfffffeff
  mov DWORD PTR [cnt],0
  call doearly
  cmp DWORD PTR [cnt],0
  jne fail
  call dolate
  cmp DWORD PTR [cnt],1
  jne fail
  mov eax,4
  mov ebx,1
  mov ecx,OFFSET okmsg
  mov edx,70
  int 0x80
  xor ebx,ebx
  mov eax,1
  int 0x80
fail:
  mov eax,1
  mov ebx,1
  int 0x80
doearly:
  sub esp,16
  mov DWORD PTR [esp+8],OFFSET obj
  mov edi,OFFSET po
  mov ebx,OFFSET kin
  call early
  add esp,16
  ret
dolate:
  sub esp,16
  mov DWORD PTR [esp+8],OFFSET obj
  mov edi,OFFSET po
  mov ebx,OFFSET kin
  call late
  cmp edi,OFFSET obj
  jne fail
  cmp ecx,0x12345678
  jne fail
  add esp,16
  ret
mock_set:
  inc DWORD PTR [cnt]
  mov eax,[esp+4]
  mov [lastlow],eax
  mov eax,[esp+8]
  mov [lasthi],eax
  ret 8
mock_bone:
  mov eax,[boneid]
  ret 4
mock_msg:
  inc DWORD PTR [logs]
  ret
.section .earlyret,"ax"
  ret
.section .lateret,"ax"
  ret
.section .iatset,"aw"
.long mock_set
.section .iatbone,"aw"
.long mock_bone
.section .iatmsg,"aw"
.long mock_msg
.section .data
obj: .space 0x1a8
po: .space 0x20
kin: .space 4
cnt: .long 0
logs: .long 0
boneid: .long 0
lastlow: .long 0
lasthi: .long 0
okmsg: .ascii "PASS: delayed head mask; exclusions; 64-bit mask; calling conventions\n"
okend:
