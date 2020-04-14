// See if we can reproduce...
//

#include "packet.h"

#include <openssl/sha.h>
#include <stdio.h>

text_code_t b20to32(const uint32_t by20[5])
{
    text_code_t result;
    char * r = result.text;
    for (int i = 0; i < 5; ++i) {
        for (int j = 15; j >= 0; j -= 5) {
            int bits = (by20[i] >> j) & 31;
            if (bits < 10)
                *r++ = bits + '0';
            else
                *r++ = bits - 10 + 'a';
        }
    }
    *r++ = 0;
    return result;
}

text_code_t once(const text_code_t & t)
{
    uint8_t bytes[20];
    SHA1((const uint8_t *) t.text, 20, (uint8_t *) bytes);

    // Put together the 5 uint32_t big endian words.
    uint32_t by32[5];
    const uint8_t * p = bytes;
    for (int i = 0; i < 5; ++i) {
        uint32_t w = 0;
        for (int j = 0; j < 4; ++j)
            w = (w << 8) + *p++;
        by32[i] = w;
    }

    // Take 100 bits in 5 * 20, placing backwards...
    uint32_t by20[5];
    uint64_t shifter = 0;
    // shifter = (shifter << 32) | by32[0];
    // by20[4] = shifter >> (32 - 20);
    // shifter = (shifter << 32) | by32[1];
    // by20[3] = shifter >> (2 * 32 - 2 * 20);
    // by20[2] = shifter >> (2 * 32 - 3 * 20);
    // shifter = (shifter << 32) | by32[2];
    // by20[1] = shifter >> (3 * 32 - 4 * 20);
    // shifter = (shifter << 32) | by32[3];
    // by20[0] = shifter >> (4 * 32 - 5 * 20);
    int shifter_bits = 0;
    const uint32_t * q = by32;
    for (int i = 4; i >= 0; --i) {
        shifter_bits -= 20;
        if (shifter_bits < 0) {
            shifter = (shifter << 32) | *q++;
            shifter_bits += 32;
        }
        by20[i] = shifter >> shifter_bits;
    }
#ifdef MASK80
    by20[0] = 0;
#endif
    // Now convert to base32.
    return b20to32(by20);
}

text_code_t run(const char * text, long s, long e)
{
    text_code_t result;
    snprintf(result.text, sizeof result.text, "%s", text);
    for (long i = s; i < e; ++i)
        result = once(result);

    printf("%s -> %s (%li -> %li)\n", text, result.text, s, e);
    return result;
}
