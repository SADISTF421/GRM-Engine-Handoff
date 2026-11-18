.intel_syntax noprefix
.section .text
.global signal, pre, post
signal:
    ja signal_go
    cmp DWORD PTR [ecx+0x1dc],0
    je signal_exit
    push eax
    mov eax,[esp+0x10]
    test eax,eax
    jz signal_noactor
    push edx
    call s_pc
s_pc:
    pop edx
    sub edx,OFFSET s_pc-0x10000000
    add edx,0x491c3c
    cmp [eax],edx
    pop edx
    jne signal_noactor
    pop eax
signal_go:
    mov edx,[esp+0x10]
    jmp 0x10120074
signal_noactor:
    pop eax
signal_exit:
    jmp 0x10120096
pre:
    ja pre_alive
    cmp DWORD PTR [edi+0x1dc],0
    je pre_dead_exit
    test esi,esi
    jz pre_dead_exit
    push eax
    call p_pc
p_pc:
    pop eax
    sub eax,OFFSET p_pc-0x10000000
    add eax,0x491c3c
    cmp [esi],eax
    pop eax
    jne pre_dead_exit
    jmp 0x10013b76
pre_alive:
    jmp 0x10013b38
pre_dead_exit:
    jmp 0x10013d4a
post:
    push eax
    sub esp,16
    movdqu [esp],xmm0
    mov eax,[ebx+4]
    mov eax,[eax+0x1b8]
    movss xmm0,[eax+4]
    call c_pc
c_pc:
    pop eax
    sub eax,OFFSET c_pc-0x10000000
    comiss xmm0,DWORD PTR [eax+0x467fdc]
    movdqu xmm0,[esp]
    lea esp,[esp+16]
    pop eax
    jbe post_exit
    test esi,esi
    jz post_exit
    jmp 0x10013bd9
post_exit:
    jmp 0x10013d4a
