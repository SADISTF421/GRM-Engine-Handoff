.intel_syntax noprefix
.section .text
.global _start
_start:
    push ebx
    push edi
    push esi
    push ebp
    sub esp,8
    mov ebp,ecx
    mov esi,[esp+28]
    mov edi,[esp+32]
    test edi,edi
    jz normal
    call here
here:
    pop ebx
    sub ebx, OFFSET here - 0x10000000
    mov ecx,edi
    lea edx,[ebx + idname - 0x10000000]
cmpid:
    mov al,[ecx]
    cmp al,[edx]
    jne checkhide
    test al,al
    jz foundid
    inc ecx
    inc edx
    jmp cmpid
checkhide:
    mov ecx,edi
    lea edx,[ebx + hidename - 0x10000000]
cmphide:
    mov al,[ecx]
    cmp al,[edx]
    jne normal
    test al,al
    jz foundhide
    inc ecx
    inc edx
    jmp cmphide
foundid:
    mov edi,1
    jmp action
foundhide:
    mov edi,2
action:
    test esi,esi
    jz done
    mov DWORD PTR [esi],0xbf800000
    mov DWORD PTR [esi+4],0
    mov DWORD PTR [esi+8],0
    test ebp,ebp
    jz done
    mov eax,[ebp+4]
    test eax,eax
    jz done
    lea edx,[ebx+0x484334]
    cmp [eax],edx
    jne done
    mov [esp],eax
    mov ecx,[eax+0x90]
    test ecx,ecx
    jz done
    mov eax,[ecx]
    call DWORD PTR [eax+0x18]
    test eax,eax
    jz done
    mov ebp,eax
    lea edx,[ebx + bonename - 0x10000000]
    push edx
    mov ecx,ebp
    call DWORD PTR [ebx+0x466aa0]
    movzx eax,ax
    mov [esp+4],eax
    cmp eax,64
    jae done
    cmp edi,2
    je hide
    push eax
    fild DWORD PTR [esp]
    add esp,4
    fstp DWORD PTR [esi]
    jmp done
hide:
    push 1
    push 0
    push eax
    mov ecx,ebp
    call DWORD PTR [ebx+0x466788]
    mov eax,[esp]
    mov eax,[eax+0xb0]
    test eax,eax
    jz empty_visual
    add eax,12
    jmp log_visual
empty_visual:
    lea eax,[ebx + empty - 0x10000000]
log_visual:
    push DWORD PTR [esp+4]
    push eax
    lea eax,[ebx + message - 0x10000000]
    push eax
    call DWORD PTR [ebx+0x466d74]
    add esp,12
    mov DWORD PTR [esi],0x3f800000
done:
    mov eax,esi
    add esp,8
    pop ebp
    pop esi
    pop edi
    pop ebx
    ret 8
normal:
    mov ecx,ebp
    add esp,8
    pop ebp
    pop esi
    pop edi
    pop ebx
    push ebp
    mov ebp,esp
    and esp,0xfffffff8
    jmp 0x10146f16
idname: .asciz "__grm_test_head_id__"
hidename: .asciz "__grm_test_hide_head__"
bonename: .asciz "bip01_head"

message: .asciz "[GRM_HEAD_DIAG] visual=%s bone=%u"
empty: .asciz "unknown"
