.intel_syntax noprefix
.section .hook,"ax"
.global hook
hook: .byte 0xe9,0x5b,0xc4,0x5a,0x00
.section .normal,"ax"
normal:
    pushfd
    pop DWORD PTR [flag_value]
    mov DWORD PTR [seen_eax],eax
    mov DWORD PTR [seen_ecx],ecx
    mov DWORD PTR [result],1
    ret
.section .skip,"ax"
skip:
    pushfd
    pop DWORD PTR [flag_value]
    mov DWORD PTR [result],2
    ret
.section .iat,"aw"
.long mock_query
.section .cave,"ax"
.incbin "../guard.bin"
.section .start,"ax"
.global _start
_start:
    mov DWORD PTR [node+16], OFFSET FLAT:obj
    mov DWORD PTR [mode],0
    call run_test
    cmp DWORD PTR [result],1
    jne fail
    cmp DWORD PTR [seen_eax], OFFSET FLAT:vtable
    jne fail
    cmp DWORD PTR [seen_ecx], OFFSET FLAT:obj
    jne fail
    mov DWORD PTR [node+16],0
    call run_test
    cmp DWORD PTR [result],2
    jne fail
    mov DWORD PTR [node+16],0xfeeefeee
    call run_test
    cmp DWORD PTR [result],2
    jne fail
    mov DWORD PTR [node+16], OFFSET FLAT:obj
    mov DWORD PTR [mode],1
    call run_test
    cmp DWORD PTR [result],2
    jne fail
    mov DWORD PTR [mode],2
    call run_test
    cmp DWORD PTR [result],2
    jne fail
    mov DWORD PTR [mode],3
    call run_test
    cmp DWORD PTR [result],2
    jne fail
    mov DWORD PTR [mode],4
    call run_test
    cmp DWORD PTR [result],2
    jne fail
    mov DWORD PTR [mode],5
    call run_test
    cmp DWORD PTR [result],2
    jne fail
    mov DWORD PTR [mode],6
    call run_test
    cmp DWORD PTR [result],2
    jne fail
    mov eax,1
    xor ebx,ebx
    int 0x80
run_test:
    mov DWORD PTR [stack_before],esp
    mov esi,OFFSET FLAT:node
    mov edi,0x66554433
    mov ebx,0x12345678
    mov ebp,0x76543210
    mov edx,0x10203040
    stc
    call hook
    cmp esp,DWORD PTR [stack_before]
    jne fail
    cmp esi,OFFSET FLAT:node
    jne fail
    cmp edi,0x66554433
    jne fail
    cmp ebx,0x12345678
    jne fail
    cmp ebp,0x76543210
    jne fail
    cmp edx,0x10203040
    jne fail
    test DWORD PTR [flag_value],1
    jz fail
    ret
fail:
    mov eax,1
    mov ebx,1
    int 0x80
# Фиктивный stdcall VirtualQuery для проверки маршрутов, а не Windows API.
mock_query:
    mov eax,DWORD PTR [esp+4]
    mov edx,DWORD PTR [esp+8]
    cmp eax,OFFSET FLAT:obj
    je mock_object
    cmp eax,OFFSET FLAT:vtable
    je mock_table
    cmp eax,OFFSET FLAT:method
    je mock_method
    xor eax,eax
    ret 12
mock_object:
    cmp DWORD PTR [mode],1
    je mock_fail
    mov DWORD PTR [edx], OFFSET FLAT:obj
    mov DWORD PTR [edx+12],0x1000
    mov DWORD PTR [edx+16],0x1000
    mov DWORD PTR [edx+20],4
    mov DWORD PTR [edx+24],0x20000
    cmp DWORD PTR [mode],4
    jne object_not_guard
    mov DWORD PTR [edx+20],0x104
object_not_guard:
    cmp DWORD PTR [mode],5
    jne object_not_short
    mov DWORD PTR [edx+12],2
object_not_short:
    cmp DWORD PTR [mode],6
    jne mock_good
    mov DWORD PTR [edx+16],0x2000
    jmp mock_good
mock_table:
    mov DWORD PTR [edx], OFFSET FLAT:vtable
    mov DWORD PTR [edx+12],0x1000
    mov DWORD PTR [edx+16],0x1000
    mov DWORD PTR [edx+20],2
    mov DWORD PTR [edx+24],0x1000000
    cmp DWORD PTR [mode],2
    jne mock_good
    mov DWORD PTR [edx+24],0x20000
    jmp mock_good
mock_method:
    mov DWORD PTR [edx], OFFSET FLAT:method
    mov DWORD PTR [edx+12],0x1000
    mov DWORD PTR [edx+16],0x1000
    mov DWORD PTR [edx+20],0x20
    mov DWORD PTR [edx+24],0x1000000
    cmp DWORD PTR [mode],3
    jne mock_good
    mov DWORD PTR [edx+20],2
mock_good:
    mov eax,28
    ret 12
mock_fail:
    xor eax,eax
    ret 12
method: ret
.section .data,"aw"
node: .space 20
obj: .long vtable
vtable: .space 160
.long method
result: .long 0
flag_value: .long 0
seen_eax: .long 0
seen_ecx: .long 0
stack_before: .long 0
mode: .long 0
