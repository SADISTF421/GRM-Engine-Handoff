.intel_syntax noprefix
.code32
.section .text
.global stub_x,stub_y,stub_z
stub_x: push 0; jmp common
stub_y: push 4; jmp common
stub_z: push 8; jmp common
common:
 pushfd
 pushad
 mov ebp,esp

 mov ecx,[ebp+36]
 mov [ebp+12],ecx
 mov eax,[ebp+20]
 mov eax,[eax+ecx+0x30]
 mov [ebp+36],eax
 mov ebx,[ebp+16]
 cmp ebx,64
 jae finished
 mov eax,[ebp+60]
 test eax,eax
 jz finished
 mov esi,[eax+4]
 test esi,esi
 jz finished
 bt DWORD PTR [esi+0xa4],ebx
 jc finished
 cmp DWORD PTR [esi+0x90],0
 je finished
 mov edi,[esi+0x88]
 test edi,edi
 jz finished
 mov eax,[edi+4]
 mov edx,[edi+8]
 test eax,eax
 jz finished
 cmp edx,eax
 jb finished
 sub edx,eax
 test edx,3
 jnz finished
 shr edx,2
 test edx,edx
 jz finished
 cmp edx,64
 ja finished
 cmp ebx,edx
 jae finished

 sub esp,0x210
 and esp,0xfffffff0
 fxsave [esp]
 mov ecx,esi
 call pc
pc: pop eax
 lea eax,[eax+headname-pc]
 push eax
 call 0x45abd0
 movzx eax,ax
 mov edi,[esi+0x88]
 mov edx,[edi+8]
 sub edx,[edi+4]
 shr edx,2
 cmp eax,edx
 jae fx_done
 cmp eax,64
 jae fx_done
 bt DWORD PTR [esi+0xa4],eax
 jc fx_done
 mov edi,[edi+4]
 mov ecx,ebx



 mov [esp+512],edx
walk:
 cmp ecx,eax
 je found
 cmp ecx,edx
 jae fx_done
 mov ecx,[edi+ecx*4]
 test ecx,ecx
 jz fx_done
 movzx ecx,WORD PTR [ecx+6]
 dec DWORD PTR [esp+512]
 jnz walk
 jmp fx_done
found:

 mov ecx,[edi+eax*4]
 test ecx,ecx
 jz fx_done
 movzx ecx,WORD PTR [ecx+6]
 mov edi,[esi+0x88]
 mov edx,[edi+8]
 sub edx,[edi+4]
 shr edx,2
 cmp ecx,edx
 jae fx_done
 cmp ecx,64
 jae fx_done
 bt DWORD PTR [esi+0xa4],ecx
 jnc fx_done
 mov edi,[esi+0x84]
 test edi,edi
 jz fx_done
 imul ecx,ecx,160
 mov edx,[ebp+12]
 add ecx,edx
 mov eax,[edi+ecx+0x30]
 mov [ebp+36],eax
fx_done:
 fxrstor [esp]
finished:
 movss xmm3,DWORD PTR [ebp+36]
 mov esp,ebp
 popad
 popfd
 lea esp,[esp+4]
 ret
headname: .asciz "bip01_head"
