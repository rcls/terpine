
#include "model.h"
#include "server.h"

#include <string.h>

static bool callback1(const text_code_t * in, uint64_t count, text_code_t * out)
{
    printf(".");
    fflush(NULL);
    return false;
}


static bool callback2(const text_code_t * in, uint64_t count, text_code_t * out)
{
    if (strcmp(out[0], out[1]) == 0) {
        printf("Hit at @%lu + 1: %s,%s -> %s,%s\n",
               count, in[0].text, in[1].text, out[0].text, out[1].text);
        return true;
    }

    printf(".");
    fflush(NULL);
    return false;
}


int main(void)
{
    IterationServer::bist();

    text_code_t A[4] = {
        {"00008icvopj700lv0000"}, {"0000ilj1a3mc00sn0000"}, {"A"}, {"B"} };
    uint64_t S0 = 12996530530;
    uint64_t E0 = 14200470893; // 18:10
    uint64_t S1 = 16145714848;
    uint64_t E1 = 16707594314; // 19:21

    E0 -= S0;
    E1 -= S1;

    if (E1 > E0) {
        printf("Catchup 1 %li\n", E1 - E0);
        cycle<1>(&A[1], E1 - E0, callback1);
        E1 = E0;
    }
    if (E0 > E1) {
        printf("Catchup 0 %li\n", E0 - E1);
        cycle<1>(&A[0], E0 - E1, callback1);
        E0 = E1;
    }

    printf("Compare (up to %li)\n", E0);
    uint64_t done = cycle<4>(A, E0, callback2);
    if (done == E0)
        printf("These are not the 'droids you are looking for.\n");

    return 0;
}


// ......................................Compare (up to 561879466)
// ...........Hit @ 168184463
// 0000ni7ti99p8kvob607 -> 0000tjdrg2ee7op5gj4k
// 00006a8nt6458qkqdkjl -> 0000tjdrg2ee7op5gj4k
// Hit @ 168184464
// 0000tjdrg2ee7op5gj4k -> 0000ia1g6s0imkqis9c9
// 0000tjdrg2ee7op5gj4k -> 0000ia1g6s0imkqis9c9
// Hit @ 168184465
// 0000ni7ti99p8kvob607 -> 84c943e325809ceecdbb7d13aeafe12943c33b0f
// 00006a8nt6458qkqdkjl -> 84c943e325809ceecdbb9ca599ad5fb105bde84f
