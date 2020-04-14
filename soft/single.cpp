
#include "fifo.h"
#include "packet.h"

#include <map>
#include <set>
#include <string>
#include <unistd.h>

static std::map<int, std::map<uint64_t, read_out_t> > results;
static std::map<std::string, const read_out_t *> hashes;

static void do_one(int unit)
{
    read_out_t item = fifo_read(unit);
    auto & r = results[item.unit_cycle()];
    if (r.empty() && !item.is_inject())
        return;

    item.print();
    auto rr = r.emplace(item.count(), item);
    if (!rr.second) {
        printf("Huh?  Duplicate!\n");
        return;
    }

    auto ss = hashes.emplace(item.text().text, &rr.first->second);
    if (!ss.second)
        printf("********* COLLIDE *********\n");
}


int main()
{
    setlinebuf(stdout);
    open_socket();

    // Flush...
    while (last.nempty) {
        for (int i = 1; i <= 24; ++i) {
            if (last.nempty & 1 << i)
                transact(OP_READ_FIFO, i);
        }
    }

    // Now initiate all units & cycles.  Just inject, don't worry about reading
    // yet.
    for (int unit = 1; unit <= 24; ++unit) {
        for (int cycle = CYCLE_BASE; cycle < CYCLE_LIMIT; ++cycle) {
            // Load a starting pattern into each guy.
            transact(0, unit);
            transact(1, cycle);
            transact(2, 0);
            transact(3, 0);
            transact(4, 0);
            transact(OP_EXECUTE, COMMAND_INJECT | cycle | COMMAND_UNIT(unit));
        }
    }

    // Now do the readouts.
    while (true) {
        if (!last.nempty) {
            sleep(1);
            status();
        }

        for (int unit = 1; unit <= 24; ++unit) {
            if (last.nempty & 1 << unit)
                do_one(unit);
        }
    }
}
