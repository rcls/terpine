
#include "database.h"
#include "fifo.h"
#include "packet.h"

#include <err.h>
#include <unistd.h>

int main()
{
    setlinebuf(stdout);
    open_db("log100.db");
    open_socket();

    // There are 1024 memory entries, in batches of 5.  I.e., 1020 / 5 = 204
    // complete entries.  Pick up any that have non zero counts.  They may be
    // duplicates...
    int waddr = last.waddr;
    for (int i = 4; i < 1024; i += 5) {
        int addr = (waddr + i) & 1023;
        auto r = transact(OP_READ_ADDR, addr);
        // Ignore zero counts (un-initialized rows).
        if (r.raddr != addr)
            errx(1, "read address mismatch %i %i\n", r.raddr, addr);
        if (r.count() != 0)
            insert_read_out(r);
    }

    // Check for overflow.
    if (last.oflow)
        errx(1, "overflow set %#x: restart needed", last.oflow);

    while (true) {
        while (!last.nempty) {
            sleep(1);
            status();
        }

        for (int unit = 1; unit <= 24; ++unit) {
            if (last.nempty & 1 << unit) {
                read_out_t item = fifo_read(unit);
                insert_read_out(item);
            }
        }
    }
}
