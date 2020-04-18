#include "check.h"

#include <string.h>

int main(void)
{
    text_code_t A = { "00008icvopj700lv0000" };
    uint64_t As = 12996530530;
    uint64_t Ae = 14200470893; // 18:10
    text_code_t B = { "0000ilj1a3mc00sn0000" };
    uint64_t Bs = 16145714848;
    uint64_t Be = 16707594314; // 19:21

    Ae -= As;
    Be -= Bs;

    if (Ae < Be) {
        printf("Catchup B %li\n", Be - Ae);
        for (uint64_t i = 0; i < Be - Ae; ++i) {
            if ((i & 0xfffff) == 0) {
                printf(".");
                fflush(stdout);
            }
            B = once(B);
        }
        Be = Ae;
    }
    if (Be < Ae) {
        printf("Catchup A %li\n", Ae - Be);
        for (uint64_t i = 0; i < Ae - Be; ++i) {
            if ((i & 0xffffff) == 0) {
                printf(".");
                fflush(stdout);
            }
            A = once(A);
        }
        Ae = Be;
    }

    printf("Compare (up to %li)\n", Ae);

    for (uint64_t i = 0; i < Ae; ++i) {
        if ((i & 0xffffff) == 0) {
            printf(".");
            fflush(stdout);
        }
        auto nA = once(A);
        auto nB = once(B);
        if (strcmp(nA, nB) == 0) {
            printf("Hit @ %lu\n", i);
            printf("%s -> %s\n", A.text, nA.text);
            printf("%s -> %s\n", B.text, nB.text);
            break;
        }
        A = nA;
        B = nB;
    }

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