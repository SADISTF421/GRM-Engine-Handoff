.intel_syntax noprefix
.code32
.section .lookup,"ax"
.global fake_lookup
fake_lookup: pxor xmm0,xmm0; pxor xmm1,xmm1; mov eax,[head_id]; ret 4
.section .sitex,"ax"
call stub_x
jmp DWORD PTR [dst]
.section .sitey,"ax"
call stub_y
jmp yafter
.section .sitez,"ax"
call stub_z
jmp zafter
.section .main,"ax"
.global _start
_start:
 # 5 bones; head=3, neck=1, child=4; non-head=2
 mov DWORD PTR [kin+0x88],OFFSET bonevec
 mov DWORD PTR [kin+0x84],OFFSET instances
 mov DWORD PTR [kin+0x90],OFFSET namemap
 mov DWORD PTR [kin+0xa4],0xffffffe7 # 3/4 hidden
 mov DWORD PTR [kin+0xa8],0xffffffff
 mov DWORD PTR [bonevec+4],OFFSET boneptrs
 mov DWORD PTR [bonevec+8],OFFSET boneptrs+20
 mov WORD PTR [bone3+6],1
 mov WORD PTR [bone4+6],3
 mov WORD PTR [bone2+6],0
 mov DWORD PTR [renderthis+4],OFFSET kin
 mov DWORD PTR [instances+160+0x30],0x3f800000
 mov DWORD PTR [instances+160+0x34],0x40000000
 mov DWORD PTR [instances+160+0x38],0x40400000
 mov DWORD PTR [matrix+0x30],0xdeadbeef
 mov DWORD PTR [matrix+0x34],0xdeadbeee
 mov DWORD PTR [matrix+0x38],0xdeadbeed
 sub esp,0x20
 mov DWORD PTR [esp+0x10],OFFSET renderthis
 mov DWORD PTR [dst],OFFSET xafter
 mov ebx,3
 mov edx,OFFSET matrix
 jmp 0x467514
xafter:
 movd eax,xmm3
 cmp eax,0x3f800000
 jne bad
 mov ebx,4
 mov edx,OFFSET matrix
 jmp 0x4675ce
yafter:
 movd eax,xmm3
 cmp eax,0x40000000
 jne bad
 mov ebx,3
 mov edx,OFFSET matrix
 jmp 0x467688
zafter:
 movd eax,xmm3
 cmp eax,0x40400000
 jne bad
 # Verify head visible: return original translation.
 mov DWORD PTR [kin+0xa4],0xffffffff
 mov DWORD PTR [dst],OFFSET head_visible
 mov ebx,3
 mov edx,OFFSET matrix
 jmp 0x467514
head_visible:
 movd eax,xmm3
 cmp eax,0xdeadbeef
 jne bad
 # Hidden unrelated bone: original value.
 mov DWORD PTR [kin+0xa4],0xffffffe3
 mov DWORD PTR [dst],OFFSET unrelated
 mov ebx,2
 mov edx,OFFSET matrix
 jmp 0x467514
unrelated:
 movd eax,xmm3
 cmp eax,0xdeadbeef
 jne bad
 # Neck hidden: do not modify.
 mov DWORD PTR [kin+0xa4],0xffffffe5
 mov DWORD PTR [dst],OFFSET neck_hidden
 mov ebx,3
 mov edx,OFFSET matrix
 jmp 0x467514
neck_hidden:
 movd eax,xmm3
 cmp eax,0xdeadbeef
 jne bad
 # Unknown head ID: do not modify.
 mov DWORD PTR [kin+0xa4],0xffffffe7
 mov DWORD PTR [head_id],0xffff
 mov DWORD PTR [dst],OFFSET missing
 mov ebx,3
 mov edx,OFFSET matrix
 jmp 0x467514
missing:
 movd eax,xmm3
 cmp eax,0xdeadbeef
 jne bad
 mov DWORD PTR [head_id],3
 # Parent loop: bounded and no modification.
 mov WORD PTR [bone4+6],4
 mov DWORD PTR [dst],OFFSET cyclic
 mov ebx,4
 mov edx,OFFSET matrix
 jmp 0x467514
cyclic:
 movd eax,xmm3
 cmp eax,0xdeadbeef
 jne bad
 mov WORD PTR [bone4+6],3
 # Preserve caller flags, registers and unrelated SSE.
 mov DWORD PTR [dst],OFFSET preserve
 mov ebx,3
 mov edx,OFFSET matrix
 mov eax,0x11223344
 mov ecx,0x55667788
 mov esi,0x13572468
 mov edi,0x24681357
 movd xmm0,eax
 movd xmm1,ecx
 stc
 jmp 0x467514
preserve:
 jnc bad
 cmp eax,0x11223344
 jne bad
 cmp ecx,0x55667788
 jne bad
 cmp ebx,3
 jne bad
 cmp edx,OFFSET matrix
 jne bad
 cmp esi,0x13572468
 jne bad
 cmp edi,0x24681357
 jne bad
 movd eax,xmm0
 cmp eax,0x11223344
 jne bad
 movd eax,xmm1
 cmp eax,0x55667788
 jne bad
 add esp,0x20
 mov eax,1
 xor ebx,ebx
 int 0x80
bad:
 mov eax,1
 mov ebx,1
 int 0x80
.section .data
.balign 16
dst: .long 0
head_id: .long 3
kin: .space 0xac
bonevec: .long 0,0,0
boneptrs: .long bone0,bone1,bone2,bone3,bone4
bone0: .long 0; .short 0,0xffff
bone1: .long 0; .short 1,0
bone2: .long 0; .short 2,0
bone3: .long 0; .short 3,0
bone4: .long 0; .short 4,0
namemap: .space 16
renderthis: .long 0,0
instances: .space 800
matrix: .space 64
