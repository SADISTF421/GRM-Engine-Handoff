.intel_syntax noprefix
.section .text
.global _start
_start:
  mov DWORD PTR [npc+0x1dc],123
  mov DWORD PTR [actor],0x10491c3c
  mov DWORD PTR [other],0x11111111
  mov DWORD PTR [npc+0x1b8],OFFSET health
  mov DWORD PTR [mgr+4],OFFSET npc
  mov DWORD PTR [health+4],0
  mov DWORD PTR [route],0
  mov eax,OFFSET actor
  call sig_dead
  cmp DWORD PTR [route],1
  jne fail
  cmp DWORD PTR [received],17
  jne fail
  mov DWORD PTR [route],0
  mov eax,OFFSET other
  call sig_dead
  cmp DWORD PTR [route],2
  jne fail
  mov DWORD PTR [route],0
  xor eax,eax
  call sig_dead
  cmp DWORD PTR [route],2
  jne fail
  mov DWORD PTR [npc+0x1dc],0
  mov eax,OFFSET actor
  call sig_dead
  cmp DWORD PTR [route],2
  jne fail
  mov eax,OFFSET other
  call sig_alive
  cmp DWORD PTR [route],1
  jne fail
  mov edi,OFFSET npc
  mov esi,OFFSET actor
  mov DWORD PTR [npc+0x1dc],3
  xor eax,eax
  cmp eax,1
  call pre
  cmp DWORD PTR [route],4
  jne fail
  mov esi,OFFSET other
  xor eax,eax
  cmp eax,1
  call pre
  cmp DWORD PTR [route],5
  jne fail
  mov eax,2
  cmp eax,1
  call pre
  cmp DWORD PTR [route],3
  jne fail
  mov ebx,OFFSET mgr
  mov esi,OFFSET actor
  mov eax,0x12345678
  mov DWORD PTR [health+4],0xbf800000
  call post
  cmp DWORD PTR [route],5
  jne fail
  cmp eax,0x12345678
  jne fail
  mov DWORD PTR [health+4],0x3f800000
  call post
  cmp DWORD PTR [route],6
  jne fail
  mov esi,0
  call post
  cmp DWORD PTR [route],5
  jne fail
  mov eax,4
  mov ebx,1
  mov ecx,OFFSET msg
  mov edx,57
  int 0x80
  xor ebx,ebx
  mov eax,1
  int 0x80
fail:
  mov ebx,1
  mov eax,1
  int 0x80
sig_dead:
  push 17
  push eax
  push 0
  push 0
  mov ecx,OFFSET npc
  xor edx,edx
  cmp edx,1
  call signal
  ret
sig_alive:
  push 17
  push eax
  push 0
  push 0
  mov ecx,OFFSET npc
  mov edx,2
  cmp edx,1
  call signal
  ret
.section .siggo,"ax"
  mov [received],edx
  mov DWORD PTR [route],1
  ret 16
.section .sigexit,"ax"
  mov DWORD PTR [route],2
  ret 16
.section .prealive,"ax"
  mov DWORD PTR [route],3
  ret
.section .predead,"ax"
  mov DWORD PTR [route],4
  ret
.section .exit,"ax"
  mov DWORD PTR [route],5
  ret
.section .postalive,"ax"
  mov DWORD PTR [route],6
  ret
.section .constzero,"a"
 .long 0
.section .data
npc: .space 0x350
health: .space 0x20
actor: .space 4
other: .space 4
mgr: .space 8
route: .long 0
received: .long 0
msg: .ascii "PASS: corpse-only dispatch, actor checks and living flow\n"
msgend:
