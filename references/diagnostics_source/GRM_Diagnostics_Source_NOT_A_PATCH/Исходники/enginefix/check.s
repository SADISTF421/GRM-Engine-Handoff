.section .patch,"ax"
.incbin "/data/grm/enginefix/code1.bin"
.incbin "/data/grm/enginefix/code2.bin"
.section .thunks,"ax"
jmp stub_destroy
.byte 0xcc
jmp stub_internal
.section .text
.global _start
_start:
 # Ordinary destruction: clear owner's pointer and detach owner, call base exactly once.
 movl $owner, object+0xac
 movl $0x12345678, owner+4
 movl $object,%ecx
 call 0x10193920
 cmpl $0,owner+4
 jne fail
 cmpl $0,object+0xac
 jne fail
 cmpl $1,count_destroy
 jne fail
 # Repeated call must not enqueue a second time.
 movl $object,%ecx
 call 0x10193920
 cmpl $1,count_destroy
 jne fail
 # Simulate freed inaccessible owner. The deferred delete must not touch it.
 movl $125,%eax
 movl $owner,%ebx
 movl $4096,%ecx
 xorl %edx,%edx
 int $0x80
 testl %eax,%eax
 jne fail
 movl $object,%ecx
 call 0x10193900
 cmpl $1,count_internal
 jne fail
 # Restore owner page and verify direct level teardown on still-live wrapper.
 movl $125,%eax
 movl $owner,%ebx
 movl $4096,%ecx
 movl $3,%edx
 int $0x80
 testl %eax,%eax
 jne fail
 movl $owner, object+0xac
 movl $0x87654321,owner+4
 movl $object,%ecx
 call 0x10193900
 cmpl $0,owner+4
 jne fail
 cmpl $2,count_internal
 jne fail
 xorl %ebx,%ebx
 movl $1,%eax
 int $0x80
fail:
 movl $1,%ebx
 movl $1,%eax
 int $0x80
stub_destroy:
 incl count_destroy
 ret
stub_internal:
 incl count_internal
 ret
.section .bss
.align 4096
owner: .skip 4096
object: .skip 0xb0
count_destroy: .skip 4
count_internal: .skip 4
