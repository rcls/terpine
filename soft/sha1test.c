#include <stdio.h>
#include <stdlib.h>

static unsigned rol(unsigned x, int a)
{
    unsigned hi = x << a;
    unsigned lo = x >> (32 - a);
    return hi | lo;
}

static unsigned rol5(unsigned x)
{
    return rol(x,5);
}
static unsigned rol30(unsigned x)
{
    return rol(x, 30);
}

static unsigned expand(unsigned v)
{
    unsigned res = 0;
    for (int i = 0; i < 4; ++i) {
        unsigned bits = (v >> i * 5) & 31;
        if (bits < 10)
            bits = bits + '0';
        else
            bits = bits - 10 + 'a';
        res += bits << i * 8;
    }
    printf("%05x -> %08x\n", v, res);
    return res;
}


int main (int argc, char * const argv[])
{
    static unsigned input[80] = {
#if 0
        0x54686973, 0x20697320, 0x61207465, 0x73742031,
        0x32332e0a, 0x80000000, 0x00000000, 0x00000000,
        0x00000000, 0x00000000, 0x00000000, 0x00000000,
        0x00000000, 0x00000000, 0x00000000, 0x000000a0
#endif
#if 0
        0x61626380, 0x00000000, 0x00000000, 0x00000000,
        0x00000000, 0x00000000, 0x00000000, 0x00000000,
        0x00000000, 0x00000000, 0x00000000, 0x00000000,
        0x00000000, 0x00000000, 0x00000000, 0x00000018,
#endif
        0x74653269,
        0x69743968,
        0x706e6e67,
        0x63753471,
        0x32387135,
        0x80000000, 0x00000000, 0x00000000,
        0x00000000, 0x00000000, 0x00000000, 0x00000000,
        0x00000000, 0x00000000, 0x00000000, 0x000000a0
    };
    for (int i = 1; i < argc; ++i)
        input[i-1] = expand(strtoul(argv[i], NULL, 16));

    for (int i = 16; i != 80; ++i) {
        input[i] = rol(input[i-3] ^ input[i-8] ^ input[i-14] ^ input[i-16], 1);
        printf ("%02i %08x\n", i, input[i]);
    }

    unsigned h0 = 0x67452301;
    unsigned h1 = 0xEFCDAB89;
    unsigned h2 = 0x98BADCFE;
    unsigned h3 = 0x10325476;
    unsigned h4 = 0xC3D2E1F0;

    unsigned A = h0;
    unsigned B = h1;
    unsigned C = h2;
    unsigned D = h3;
    unsigned E = h4;

    for (int i = 0; i != 80; ++i) {
        unsigned F;
        unsigned K;
        switch (i / 20) {
        case 0:
            F = (B & C) | ((~ B) & D);
            K = 0x5a827999;
            break;
        case 1:
            F = B ^ C ^ D;
            K = 0x6ed9eba1;
            break;
        case 2:
            F = (B & C) | (B & D) | (C & D);
            K = 0x8f1bbcdc;
            break;
        case 3:
            F = B ^ C ^ D;
            K = 0xca62c1d6;
            break;
        default:
            abort();
        }

        unsigned I3 = K + input[i];
        unsigned I2 = I3 + E;
        unsigned I1 = I2 + F;
        unsigned R = rol5(A) + I1;
        E = D;
        D = C;
        C = rol30(B);
        B = A;
        A = R;

        printf ("%2i %08x %08x %08x %08x %08x\n", i, A, I1, I2, I3, input[i]);
        //printf ("%2i %08x %08x %08x %08x %08x\n", i, A, B, C, D, E);
    }

    h0 += A;
    h1 += B;
    h2 += C;
    h3 += D;
    h4 += E;

    printf("%08x %08x %08x %08x %08x\n", h0, h1, h2, h3, h4);
    unsigned nE = (h2 << 4  | h3 >> 28) & 0xfffff;
    unsigned nD = (h1 << 16 | h2 >> 16) & 0xfffff;
    unsigned nC =  h1 >> 4             & 0xfffff;
    unsigned nB = (h0 <<  8 | h1 >> 24) & 0xfffff;
    unsigned nA =  h0 >> 12            & 0xfffff;

    printf("%05x %05x %05x %05x %05x\n", nE, nD, nC, nB, nA);
    return 0;
}
