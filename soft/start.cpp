#include "database.h"
#include "fifo.h"
#include "packet.h"

#include <time.h>

// Initialize every cycle...
int main(void)
{
    open_socket();

    open_db("log100.db");
    int id_base = 0;
    SQL("BEGIN");
    SQL("SELECT value + 65536 FROM misc WHERE KEY = 'id_base'")
        .row(&id_base);
    SQL("INSERT OR REPLACE INTO misc(value) VALUES (?) WHERE KEY = 'id_base'",
        id_base).row();
    SQL("COMMIT");

    // Flush all the fifos...
    while (last.nempty) {
        for (int unit = 1; unit <= 24; ++unit) {
            if (last.nempty & (1 << unit))
                fifo_read(unit).print();
        }
    }

    uint64_t t = time(NULL);
    for (int unit = 1; unit <= 24; ++unit) {
        for (int cycle = CYCLE_BASE; cycle < CYCLE_LIMIT; ++cycle) {
            transact(0, t);
            transact(1, t >> 20);
            transact(2, t >> 40);
            transact(3, unit);
            transact(4, cycle);
            transact(OP_EXECUTE, COMMAND_INJECT | cycle | COMMAND_UNIT(unit));
        }
    }
    return 0;
}
