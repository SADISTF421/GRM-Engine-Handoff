.intel_syntax noprefix
.code32
.section .text
.global _start
_start:
  mov eax, dword ptr [esp+0x201c]
  pushfd
  pushad
  mov ebp, esp
  sub esp, 0x210
  and esp, -16
  fxsave [esp]
  mov eax, dword ptr [edi]
  push edi
  call dword ptr [eax+0x14]
  test eax, eax
  jz skiplog
  push dword ptr [ebp+0x1c]
  push eax
  call getpc
getpc:
  pop eax
  lea edx, [eax+message-getpc]
  push edx
  .byte 0xff, 0x90
.global iat_disp
iat_disp:
  .long 0
  add esp, 12
skiplog:
  fxrstor [esp]
  mov esp, ebp
  popad
  popfd
  ret
message:
  .asciz "[GRM_SAVE_DIAG] %s bytes=%u"
