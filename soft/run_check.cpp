#include "check.h"

#include <string.h>

int main(void)
{
    setlinebuf(stdout);
    // G Unit  1: 5  15987345174 s1 i0 m0 pbugct0t05mriv4s4ljm
    // G Unit  1: 5  15987345684 s1 i0 m0 8fmh25glvvfcu86s6987
    run("pbugct0t05mriv4s4ljm", 15987345174, 15987345684);

    // block_wrap test...
    const uint32_t bt20[] = { 0x12345, 0x6789a, 0xcdef0, 0x97531, 0xeb852 };
    text_code_t bt = b20to32(bt20);
    run(bt.text, 0, 1);

    // Inject test...
    // G Unit  1: 5    127376731 s1 i0 m0 2o6m8kbn9a9rqjujnqkv
    // G Unit  1: 5    127377141 s1 i0 m0 b3a33bojt61n8d4qefd3
    // G Unit  1: 5    127380508 s0 i1 m0 28q5cu4qpnngit9hte2i
    // G Unit  1: 5    127381058 s1 i0 m0 k5ujhifhfgh2sm1nkvj9
    run("2o6m8kbn9a9rqjujnqkv", 127376731, 127377141);
    run("28q5cu4qpnngit9hte2i", 127380508, 127381058);

    return 0;
}
