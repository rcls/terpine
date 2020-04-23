
#include "database.h"
#include "fifo.h"
#include "packet.h"

#include <err.h>
#include <string.h>
#include <sys/time.h>
#include <unistd.h>

static int id_base;

static void restart(const read_out_t & item)
{
    struct timeval tv;
    gettimeofday(&tv, NULL);
    transact(0, tv.tv_usec);
    transact(1, tv.tv_sec);
    transact(2, tv.tv_sec >> 20);
    transact(3, item.unit());
    transact(4, item.cycle());
    transact(OP_EXECUTE,
             COMMAND_INJECT | item.cycle() | COMMAND_UNIT(item.unit()));
}


static void insert_read_out(const read_out_t & r)
{
    r.print();
    text_code_t t = r.text();

    uint64_t p_count = 0;
    text_code_t p_value = {};
    int p_is_inject = 0;
    int p_mult = 0;

    Transaction transaction;

    // Check for a duplicate...
    SQL("SELECT count,value,is_inject,mult FROM samples "
        "WHERE id = ? and count <= ? ORDER BY count DESC LIMIT 1",
        id_base + r.unit_cycle(), r.count())
        .row(&p_count, &p_value, &p_is_inject, &p_mult);

    if (p_count == r.count()
        && strcmp(p_value, t) == 0
        && p_is_inject == r.is_inject()) {
        printf(".... duplicate row, ignore\n");
        return;
    }

    // Check whether or not to insert the row.  We discard if this is not
    // an inject and the previous row indicates:
    // 1. start up
    // 2. hit
    // [3. restart should be included, i.e, count before count offset?]
    if (!r.is_inject()) {
        if (p_count == 0) {
            printf(".... unit not initialized, ignore\n");
            return;
        }
        if (p_mult > 1) {
            printf(".... unit not reinitialized since hit, ignore\n");
            return;
        }
    }

    // Get the last count.  Attempting to insert with a count going backwards is
    // always an error.
    if (SQL("SELECT MAX(count) FROM samples WHERE id = ?",
            id_base + r.unit_cycle())
        .row(&p_count)
        && p_count >= r.count())
        errx(1, "count jumps backwards, old %lu after new %lu",
             p_count, r.count());

    // Now find the multiplicity to use.
    int mult = 0;
    if (SQL("SELECT MAX(mult) FROM samples WHERE value = ?", t.text)
        .row(&mult) && mult > 0) {
        printf("***** HIT (%i) *****\n", mult);
        restart(r);
    }

    runSQL(
        "INSERT INTO samples(id,count,value,is_inject,mult) VALUES(?,?,?,?,?)",
        id_base + r.unit_cycle(), r.count(), t.text, r.is_inject(), mult + 1);

    transaction.commit();
}


int main()
{
    setlinebuf(stdout);
    open_db("log100.db");

    SQL("SELECT value FROM misc WHERE KEY = 'id_base'").row(&id_base);

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
