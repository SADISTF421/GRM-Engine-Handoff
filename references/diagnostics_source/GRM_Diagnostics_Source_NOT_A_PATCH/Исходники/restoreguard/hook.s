.intel_syntax noprefix
.section .text
.global _start
_start:
    mov ecx, ebp
    mov eax, [ebp]
    call DWORD PTR [eax+0x198]
    movzx eax, ax
    imul eax, eax, 108
    mov edx, [esp+0x14]
    sub edx, esi
    cmp edx, eax
    jne mismatch
    jmp normal
mismatch:
    jmp 0x101f2859
normal:
    jmp 0x101f27a0
