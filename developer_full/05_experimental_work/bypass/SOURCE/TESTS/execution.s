.section .hook,"ax"
.global hook
hook: .incbin "hook.bin"
.section .normal,"ax"
normal:
    cmpl $0x12345678, %eax
    jne fail
    cmpl $obj, %ecx
    jne fail
    movl $1, result
    ret
.section .skip,"ax"
skip:
    test %ecx, %ecx
    jne fail
    movl $2, result
    ret
.section .cave,"ax"
.incbin "stub.bin"
.section .start,"ax"
.global _start
_start:
    movl $node, %esi
    movl $obj, node+16
    call hook
    cmpl $1,result
    jne fail
    movl $0,node+16
    call hook
    cmpl $2,result
    jne fail
    movl $1,%eax
    xorl %ebx,%ebx
    int $0x80
fail:
    movl $1,%eax
    movl $1,%ebx
    int $0x80
.section .data,"aw"
node: .space 20
obj: .long 0x12345678
result: .long 0
