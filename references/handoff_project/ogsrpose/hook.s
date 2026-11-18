.intel_syntax noprefix
.section .text
.global early,late
early:
    pushfd
    pushad
    mov ebp,esp
    sub esp,0x210
    and esp,0xfffffff0
    fxsave [esp]
    call gete
gete:
    pop esi
    sub esi, OFFSET gete - 0x10000000
    call check
    test eax,eax
    jnz early_done
    push DWORD PTR [edi+0x14]
    push DWORD PTR [edi+0x10]
    mov ecx,ebx
    call DWORD PTR [esi+0x46678c]
early_done:
    fxrstor [esp]
    mov esp,ebp
    popad
    popfd
    jmp 0x101f22c3
late:
    pushfd
    pushad
    mov ebp,esp
    sub esp,0x210
    and esp,0xfffffff0
    fxsave [esp]
    call getl
getl:
    pop esi
    sub esi, OFFSET getl - 0x10000000
    test ebx,ebx
    jz late_done
    call check
    test eax,eax
    jz late_done
    push DWORD PTR [edi+0x14]
    push DWORD PTR [edi+0x10]
    mov ecx,ebx
    call DWORD PTR [esi+0x46678c]
    lea eax,[esi+message-0x10000000]
    push eax
    call DWORD PTR [esi+0x466d74]
    add esp,4
late_done:
    fxrstor [esp]
    mov esp,ebp
    popad
    popfd
    mov edi,[esp+0xc]
    mov ecx,[edi+0x1a4]
    jmp 0x101f22e4
check:
    xor eax,eax
    mov edx,[ebp+0x30]
    test edx,edx
    jz no
    lea ecx,[esi+0x484334]
    cmp [edx],ecx
    jne no
    cmp WORD PTR [edi+0x18],0
    jne no
    lea eax,[esi+bonename-0x10000000]
    push eax
    mov ecx,ebx
    call DWORD PTR [esi+0x466aa0]
    movzx eax,ax
    cmp eax,64
    jae no
    bt DWORD PTR [edi+0x10],eax
    jc no
    mov eax,1
    ret
no:
    xor eax,eax
    ret
bonename: .asciz "bip01_head"
message: .asciz "[GRM_OGSR_POSE] NPC head mask applied after physics restoration"
