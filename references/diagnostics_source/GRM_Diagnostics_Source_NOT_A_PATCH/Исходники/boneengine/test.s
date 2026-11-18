.intel_syntax noprefix
.section .text
.global _start
_start:
  mov DWORD PTR [obj],0x10484334
  mov DWORD PTR [obj+0x90], OFFSET visual
  mov DWORD PTR [visual],OFFSET visualvt
  mov DWORD PTR [wrapper+4],OFFSET obj
  mov DWORD PTR [bone_id],13
  mov ebx,0x11111111
  mov edi,0x22222222
  mov esi,0x33333333
  mov ebp,0x44444444
  push OFFSET idname
  push OFFSET result
  mov ecx,OFFSET wrapper
  call hook
  cmp eax,OFFSET result
  jne fail
  cmp DWORD PTR [result],0x41500000
  jne fail
  cmp DWORD PTR [result+4],0
  jne fail
  cmp DWORD PTR [result+8],0
  jne fail
  cmp ebx,0x11111111
  jne fail
  cmp edi,0x22222222
  jne fail
  cmp esi,0x33333333
  jne fail
  cmp ebp,0x44444444
  jne fail
  push OFFSET hidename
  push OFFSET result
  mov ecx,OFFSET wrapper
  call hook
  cmp DWORD PTR [result],0x3f800000
  jne fail
  cmp DWORD PTR [hide_calls],1
  jne fail
  cmp DWORD PTR [hide_id],13
  jne fail
  mov DWORD PTR [obj],0
  push OFFSET hidename
  push OFFSET result
  mov ecx,OFFSET wrapper
  call hook
  cmp DWORD PTR [result],0xbf800000
  jne fail
  cmp DWORD PTR [hide_calls],1
  jne fail
  mov DWORD PTR [obj],0x10484334
  mov DWORD PTR [bone_id],65535
  push OFFSET hidename
  push OFFSET result
  mov ecx,OFFSET wrapper
  call hook
  cmp DWORD PTR [result],0xbf800000
  jne fail
  cmp DWORD PTR [hide_calls],1
  jne fail
  push OFFSET othername
  push OFFSET result
  mov ecx,OFFSET wrapper
  call hook
  cmp eax,0x55667788
  jne fail
  cmp DWORD PTR [fallback_this],OFFSET wrapper
  jne fail
  mov eax,1
  xor ebx,ebx
  int 0x80
fail:
  mov eax,1
  mov ebx,1
  int 0x80
visual_to_kin:
  mov eax, OFFSET kin
  ret
mock_bone:
  cmp ecx, OFFSET kin
  jne fail
  mov eax,[bone_id]
  ret 4
mock_hide:
  cmp ecx, OFFSET kin
  jne fail
  cmp DWORD PTR [esp+8],0
  jne fail
  cmp DWORD PTR [esp+12],1
  jne fail
  mov eax,[esp+4]
  mov [hide_id],eax
  inc DWORD PTR [hide_calls]
  ret 12
.section .data
wrapper: .space 8
obj: .space 0x94
visual: .long 0
visualvt: .space 0x18
.long visual_to_kin
kin: .long 0
bone_id: .long 0
hide_calls: .long 0
hide_id: .long 0
fallback_this: .long 0
result: .space 12
idname: .asciz "__grm_test_head_id__"
hidename: .asciz "__grm_test_hide_head__"
othername: .asciz "bip01_neck"
.section .fallback,"ax"
  mov [fallback_this],ecx
  mov esp,ebp
  pop ebp
  mov eax,0x55667788
  ret 8
.section .iata,"a"
.long mock_hide
.section .iatb,"a"
.long mock_bone
.section .vt,"a"
.long 0
.section .hook,"ax"
hook: .incbin "/data/grm/boneengine/stub.bin"
