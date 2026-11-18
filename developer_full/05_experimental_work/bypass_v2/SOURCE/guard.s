.intel_syntax noprefix
.section .patch,"ax"
.global guard
guard:
    pushfd
    pushad
    call here
here:
    pop ebp
    sub ebp, 0x61fa07
    mov ebx, DWORD PTR [esi+0x10]
    test ebx,ebx
    jz reject
    mov eax,ebx
    mov edx,4
    xor ecx,ecx
    call check_page
    test eax,eax
    jz reject
    mov edi,DWORD PTR [ebx]
    mov eax,edi
    mov edx,0xa4
    mov ecx,1
    call check_page
    test eax,eax
    jz reject
    mov eax,DWORD PTR [edi+0xa0]
    mov edx,1
    mov ecx,2
    call check_page
    test eax,eax
    jz reject
    popad
    popfd
    mov ecx,DWORD PTR [esi+0x10]
    mov eax,DWORD PTR [ecx]
    jmp normal
reject:
    popad
    popfd
    jmp skip

# EAX — адрес, EDX — длина, ECX — тип страницы: 0 чтение, 1 образ, 2 код образа.
# VirtualQuery проверяет страницы, но не определяет время жизни объекта.
check_page:
    push ebx
    push esi
    push edi
    sub esp,28
    mov esi,eax
    mov edi,edx
    mov ebx,ecx
    push 28
    lea eax,[esp+4]
    push eax
    push esi
    call DWORD PTR [ebp+0x46601c]
    cmp eax,28
    jne bad
    cmp DWORD PTR [esp+16],0x1000
    jne bad
    mov eax,DWORD PTR [esp+20]
    test eax,0x101
    jnz bad
    and eax,0xff
    cmp ebx,2
    je execute_page
    cmp eax,2
    je protection_ok
    cmp eax,4
    je protection_ok
    cmp eax,8
    je protection_ok
    cmp eax,0x20
    je protection_ok
    cmp eax,0x40
    je protection_ok
    cmp eax,0x80
    je protection_ok
    jmp bad
execute_page:
    cmp eax,0x10
    je protection_ok
    cmp eax,0x20
    je protection_ok
    cmp eax,0x40
    je protection_ok
    cmp eax,0x80
    jne bad
protection_ok:
    test ebx,ebx
    jz span_check
    cmp DWORD PTR [esp+24],0x1000000
    jne bad
span_check:
    test edi,edi
    jz bad
    dec edi
    add edi,esi
    jc bad
    mov eax,DWORD PTR [esp]
    add eax,DWORD PTR [esp+12]
    jc bad
    cmp edi,eax
    jae bad
    mov eax,1
    jmp done
bad:
    xor eax,eax
done:
    add esp,28
    pop edi
    pop esi
    pop ebx
    ret
