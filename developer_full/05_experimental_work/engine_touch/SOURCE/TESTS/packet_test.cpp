#include "../packet_guard.h"
#include <cassert>
#include <cstdio>
#include <cstring>
#include <limits>
int main() {
    unsigned char b[8194]; std::memset(b,0xcc,sizeof b);
    unsigned char x[8192]={}; size_t n=0;
    assert(grm_packet_append(b+1,8191,n,x,8191));
    assert(n==8191 && b[0]==0xcc && b[8192]==0xcc);
    assert(!grm_packet_append(b+1,8191,n,x,1) && n==8191 && b[8192]==0xcc);
    assert(!grm_packet_append(b+1,8191,n,x,std::numeric_limits<size_t>::max()));
    size_t p=8190; unsigned char out[2]={4,5};
    assert(!grm_packet_read(b+1,n,p,out,2) && p==8190 && out[0]==4);
    assert(grm_packet_read(b+1,n,p,out,1) && p==8191);
    std::puts("PASS: guard rejects overflow without writing; read rejects truncation");
}
