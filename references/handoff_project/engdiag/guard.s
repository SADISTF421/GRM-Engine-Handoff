.intel_syntax noprefix
.section .text
.global _start
_start:
    mov ecx, ebp
    mov eax, [ebp]
    call DWORD PTR [eax+0x198]
    movzx eax,ax
    imul eax,eax,108
    mov edx,[esp+0x14]
    sub edx,esi
    cmp edx,eax
    jne mismatch
    jmp 0x101f27a0
mismatch:
    push edx
    push eax
    call here
here:
    pop ecx
    sub ecx, OFFSET here - 0x10000000
    lea edx,[ecx + message - 0x10000000]
    push edx
    call DWORD PTR [ecx+0x466d74]
    add esp,12
    jmp 0x101f2859
message: .asciz "[GRM_PHYS_DIAG] live_bytes=%u saved_bytes=%u"
