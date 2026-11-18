#include <windows.h>
#include <stdint.h>
#include <string.h>
typedef struct lua_State lua_State;
typedef int (__cdecl *lua_fn)(lua_State *);
typedef void (__cdecl *ct_fn)(lua_State*,int,int);
typedef void (__cdecl *pc_fn)(lua_State*,lua_fn,int);
typedef void (__cdecl *sf_fn)(lua_State*,int,const char*);
typedef void (__cdecl *pb_fn)(lua_State*,int);
typedef struct { float x,y,z; } vec3;
typedef vec3* (__attribute__((thiscall)) *position_fn)(void*,vec3*,const char*);
typedef void* (__attribute__((thiscall)) *getkin_fn)(void*);
typedef unsigned short (__attribute__((thiscall)) *boneid_fn)(void*,const char*);
typedef void (__attribute__((thiscall)) *hide_fn)(void*,unsigned short,int,int);
static ct_fn createtable; static pc_fn pushclosure; static sf_fn setfield; static pb_fn pushbool;
static position_fn original_position; static boneid_fn boneid; static hide_fn hidebone;
static int installed;
/* Отдельные команды не добавляют общие методы Lua и не активируют старые эксперименты. */
static vec3* __attribute__((fastcall)) bridge(void *self,void *edx,vec3 *out,const char *name){
 (void)edx;
 if(name && (strcmp(name,"__grm_test_head_id__")==0 || strcmp(name,"__grm_test_hide_head__")==0 || strcmp(name,"__grm_test_anchor__")==0)){
  int hide = strcmp(name,"__grm_test_hide_head__")==0; int anchor = strcmp(name,"__grm_test_anchor__")==0; void *obj,*visual,*kin; unsigned short id;
  if(!out)return out; out->x=-1.f;out->y=0.f;out->z=0.f;
  if(!self || !(obj=*(void**)((char*)self+4)) || !(visual=*(void**)((char*)obj+0x90)))return out;
  if(!*(void***)visual || !(*(void***)visual)[6])return out;
  kin=((getkin_fn)(*(void***)visual)[6])(visual); if(!kin)return out;
  id=boneid(kin,"bip01_head"); if(id==0xffff || id>=64)return out;
  if(hide){hidebone(kin,id,0,1);out->x=1.f;}
  else if(anchor){
   /* Смешанные вершины стягиваются к шее, а не к началу модели. */
   unsigned short neck=boneid(kin,"bip01_neck"); unsigned char *instances=*(unsigned char**)((char*)kin+0x84); unsigned int *mask=(unsigned int*)((char*)kin+0xa4); float *src,*dst; unsigned i;
   if(!instances || neck==0xffff || neck>=64 || neck==id || (mask[id/32] & (1u<<(id%32))))return out;
   src=(float*)(instances+160u*neck+0x30);dst=(float*)(instances+160u*id+0x70);
   for(i=0;i<3;i++)if(!(src[i]==src[i]) || src[i] < -10000.f || src[i] > 10000.f)return out;
   /* Глаза и челюсть тоже могут влиять на вершины разных моделей. */
   { static const char *names[]={"eye_left","eye_right","eyelid_1","jaw_1"}; unsigned j;
     for(i=0;i<3;i++)dst[i]=src[i];
     for(j=0;j<4;j++){
       unsigned short child=boneid(kin,names[j]);
       if(child==0xffff || child>=64 || child==neck || (mask[child/32] & (1u<<(child%32))))continue;
       dst=(float*)(instances+160u*child+0x70);
       for(i=0;i<3;i++)dst[i]=src[i];
     }
   }
   out->x=1.f;
  }else out->x=(float)id;
  return out;
 }
 return original_position(self,out,name);
}
static int __cdecl install(lua_State* L){
 HMODULE game=GetModuleHandleA("xrGame.dll"),exe=GetModuleHandleA(NULL),pin;
 unsigned char *base=(unsigned char*)game,*target,*tramp; DWORD old,unused,i; IMAGE_NT_HEADERS32 *nt,*en; IMAGE_DEBUG_DIRECTORY *debug;
 const unsigned char expected[]={0x55,0x8b,0xec,0x83,0xe4,0xf8,0x83,0xec,0x44,0x53,0x56,0x8b,0x75,0x0c,0x8b,0xc6};
 const unsigned char guid[]={0x51,0x68,0x4c,0x72,0x9e,0x5c,0xf9,0x40,0xbb,0x95,0xfc,0x13,0xb7,0x5f,0x7e,0x67}; int guid_ok=0;
 if(installed){pushbool(L,1);return 1;}
 if(!game||!exe){pushbool(L,0);return 1;}
 if(((IMAGE_DOS_HEADER*)base)->e_magic!=IMAGE_DOS_SIGNATURE || ((IMAGE_DOS_HEADER*)exe)->e_magic!=IMAGE_DOS_SIGNATURE){pushbool(L,0);return 1;}
 nt=(IMAGE_NT_HEADERS32*)(base+((IMAGE_DOS_HEADER*)base)->e_lfanew);en=(IMAGE_NT_HEADERS32*)((char*)exe+((IMAGE_DOS_HEADER*)exe)->e_lfanew);
 if(nt->Signature!=IMAGE_NT_SIGNATURE || nt->OptionalHeader.Magic!=IMAGE_NT_OPTIONAL_HDR32_MAGIC || nt->FileHeader.TimeDateStamp!=0x6ae21fea || nt->OptionalHeader.SizeOfImage!=0x620000 || en->Signature!=IMAGE_NT_SIGNATURE || en->FileHeader.TimeDateStamp!=0x6a95ab5b || en->OptionalHeader.SizeOfImage!=0x16d000){pushbool(L,0);return 1;}
 { IMAGE_DATA_DIRECTORY d=nt->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_DEBUG];
  if(d.VirtualAddress>0 && d.VirtualAddress<0x620000 && d.Size<=0x620000-d.VirtualAddress){ debug=(IMAGE_DEBUG_DIRECTORY*)(base+d.VirtualAddress); for(i=0;i<d.Size/sizeof(*debug);i++){DWORD r=debug[i].AddressOfRawData;if(debug[i].Type==2 && debug[i].SizeOfData>=24 && r<=0x620000-24 && !memcmp(base+r,"RSDS",4) && !memcmp(base+r+4,guid,16) && *(DWORD*)(base+r+20)==22)guid_ok=1;}}
 }
 /* Проверка доступа к массиву костей и их матрицам в исполняемом файле. */
 { static const unsigned char sig[]={0x8d,0x04,0xbf,0xc1,0xe0,0x05,0x03,0x86,0x84,0x00,0x00,0x00};
   if(memcmp((unsigned char*)exe+0x5c7f5,sig,sizeof(sig))){pushbool(L,0);return 1;}}
 target=base+0x146f10;
 if(!guid_ok || memcmp(target,expected,sizeof(expected))){pushbool(L,0);return 1;}
 boneid=(boneid_fn)GetProcAddress(exe,"?LL_BoneID@CKinematics@@QAEGPBD@Z");hidebone=(hide_fn)GetProcAddress(exe,"?LL_SetBoneVisible@CKinematics@@QAEXGHH@Z");
 if(!boneid||!hidebone || *(void**)(base+0x466aa0)!=(void*)boneid || *(void**)(base+0x466788)!=(void*)hidebone){pushbool(L,0);return 1;}
 tramp=(unsigned char*)VirtualAlloc(NULL,16,MEM_COMMIT|MEM_RESERVE,PAGE_EXECUTE_READWRITE);if(!tramp){pushbool(L,0);return 1;}
 memcpy(tramp,target,6);tramp[6]=0xe9;*(int32_t*)(tramp+7)=(int32_t)((target+6)-(tramp+11));FlushInstructionCache(GetCurrentProcess(),tramp,11);original_position=(position_fn)tramp;
 if(!GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS|GET_MODULE_HANDLE_EX_FLAG_PIN,(LPCSTR)(uintptr_t)&bridge,&pin)){VirtualFree(tramp,0,MEM_RELEASE);pushbool(L,0);return 1;}
 if(!VirtualProtect(target,6,PAGE_EXECUTE_READWRITE,&old)){VirtualFree(tramp,0,MEM_RELEASE);pushbool(L,0);return 1;}
 target[0]=0xe9;*(int32_t*)(target+1)=(int32_t)((unsigned char*)(uintptr_t)&bridge-(target+5));target[5]=0x90;
 FlushInstructionCache(GetCurrentProcess(),target,6);VirtualProtect(target,6,old,&unused);installed=1;pushbool(L,1);return 1;
}
__declspec(dllexport) int __cdecl luaopen_grm_gore_bridge(lua_State* L){
 HMODULE lua=GetModuleHandleA("xrLUA.dll");if(!lua)return 0;
 createtable=(ct_fn)GetProcAddress(lua,"lua_createtable");pushclosure=(pc_fn)GetProcAddress(lua,"lua_pushcclosure");setfield=(sf_fn)GetProcAddress(lua,"lua_setfield");pushbool=(pb_fn)GetProcAddress(lua,"lua_pushboolean");
 if(!createtable||!pushclosure||!setfield||!pushbool)return 0;
 createtable(L,0,1);pushclosure(L,install,0);setfield(L,-2,"install");return 1;
}
BOOL WINAPI DllMain(HINSTANCE h,DWORD reason,LPVOID reserved){(void)h;(void)reason;(void)reserved;return TRUE;}
