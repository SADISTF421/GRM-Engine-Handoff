.intel_syntax noprefix
.code32
.section .hook,"ax"
.incbin "/data/grm/savediag/hook.bin"
.section .iat,"aw"
.long mock_msg
.section .text
.global _start
_start:
  sub esp,0x2020
  mov DWORD PTR [esp+0x2018],37
  mov edi, OFFSET FLAT:obj
  mov ebx, 0x12345678
  mov ecx, 0x55667788
  mov edx, 0x24681357
  mov esi, 0x11223344
  mov ebp, 0x44556677
  pxor xmm0,xmm0
  stc
  call 0x1061f200
  jnc fail
  cmp eax,37
  jne fail
  cmp ebx,0x12345678
  jne fail
  cmp ecx,0x55667788
  jne fail
  cmp edx,0x24681357
  jne fail
  cmp esi,0x11223344
  jne fail
  cmp ebp,0x44556677
  jne fail
  cmp edi, OFFSET FLAT:obj
  jne fail
  pmovmskb eax,xmm0
  test eax,eax
  jne fail
  cmp DWORD PTR [seen],1
  jne fail
  add esp,0x2020
  xor ebx,ebx
  mov eax,1
  int 0x80
fail:
  mov ebx,1
  mov eax,1
  int 0x80
mock_name:
  mov eax,OFFSET FLAT:name
  ret 4
mock_msg:
  cmp DWORD PTR [esp+8], OFFSET FLAT:name
  jne fail
  cmp DWORD PTR [esp+12],37
  jne fail
  pcmpeqb xmm0,xmm0
  mov DWORD PTR [seen],1
  ret
.section .data
vtable: .zero 20
.long mock_name
obj: .long vtable
name: .asciz "npc_test"
seen: .long 0
