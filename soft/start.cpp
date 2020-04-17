#include "packet.h"

#include <time.h>

// Initialize every cycle...
int main(void)
{
    uint64_t t = time(NULL);
    open_socket();
    for (int unit = 1; unit <= 24; ++unit) {
        for (int cycle = CYCLE_BASE; cycle < CYCLE_LIMIT; ++cycle) {
            transact(0, t);
            transact(1, t >> 20);
            transact(2, t >> 40);
            transact(3, unit);
            transact(4, cycle);
            transact(OP_EXECUTE,
                     COMMAND_INJECT | cycle | COMMAND_UNIT(unit));
        }
    }
    return 0;
}
