
#include <stdint.h>
#include <stdio.h>

#define POLY 0x04C11DB7
// Do the calculation bit-reversed, i.e., highest order coeff in low bit.
#define REV 0xedb88320
//#define POLY 0xDB710641
// 104c11db7
// 1000 0010 0110 0000 1000 1110 1101 1011 1
// db710641

// LSB = highest order bit.
static inline uint32_t shift(uint32_t a)
{
    if (a & 1)
        return a >> 1 ^ REV;
    else
        return a >> 1;
}


static inline uint32_t unshift(uint32_t a)
{
    if (a & 0x80000000)
        return (a ^ REV) << 1 | 1;
    else
        return a << 1;
}

static uint32_t stir8(uint32_t a, uint8_t x)
{
    a = a ^ x;
    for (int i = 0; i < 8; ++i)
        a = shift(a);
    return a;
}
static uint32_t unstir8(uint32_t a, uint8_t x)
{
    for (int i = 0; i < 8; ++i)
        a = unshift(a);
    return a ^ x;
}

static uint32_t stir_bytes(uint32_t a, const uint8_t * p, int len)
{
    for (int i = 0; i < len; ++i)
        a = stir8(a, p[i]);
    return a;
}
static uint32_t unstir_bytes(uint32_t a, const uint8_t * p, int len)
{
    for (int i = len - 1; i >= 0; --i)
        a = unstir8(a, p[i]);
    return a;
}


static const uint8_t frame[] = {
    0x08, 0x00, 0x20, 0x0A, 0x70, 0x66, 0x08, 0x00,
    0x20, 0x0A, 0xAC, 0x96, 0x08, 0x00, 0x45, 0x00,
    0x00, 0x28, 0xA6, 0xF5, 0x00, 0x00, 0x1A, 0x06,
    0x75, 0x94, 0xC0, 0x5D, 0x02, 0x01, 0x84, 0xE3,
    0x3D, 0x05, 0x00, 0x15, 0x0F, 0x87, 0x9C, 0xCB,
    0x7E, 0x01, 0x27, 0xE3, 0xEA, 0x01, 0x50, 0x12,
    0x10, 0x00, 0xDF, 0x3D, 0x00, 0x00, 0x20, 0x20,
    0x20, 0x20, 0x20, 0x20, 0x5a, 0x05, 0xde, 0xfa
};
//5A05DEFA

static const uint8_t preamble[] = {
    0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0xd5 };

static void repbytes(const uint8_t * p, int len)
{
    uint32_t aa = stir_bytes(0xffffffff, p, len);
    printf("%08x\n", aa ^ 0xffffffff);
}
static void prepbytes(const uint8_t * p, int len)
{
    uint32_t aa = stir_bytes(0x26b6a4c8, preamble, 8);
    aa = stir_bytes(aa, p, len);
    printf("%08x\n", aa ^ 0xffffffff);
}

int main(void)
{
    uint32_t xx = 0xffffffff;
    for (int i = 0; i < 32; ++i)
        xx = shift(xx);

    printf("%08x %08x \n", xx, xx ^ 0xffffffff);

    repbytes(frame, sizeof frame - 4);
    repbytes(frame, sizeof frame);

    uint32_t pmagic = unstir_bytes(0xffffffff, preamble, sizeof preamble);
    printf("%08x %08x\n", pmagic,
           stir_bytes(pmagic, preamble, sizeof preamble));

    prepbytes(frame, sizeof frame - 4);
    prepbytes(frame, sizeof frame);

    return 0;
}
