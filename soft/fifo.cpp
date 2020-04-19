
#include "fifo.h"

#include "packet.h"

#include <err.h>

const read_out_t & fifo_read(int unit)
{
    int waddr = last.waddr;
    transact(OP_READ_FIFO, unit);
    transact(OP_READ_ADDR, waddr);
    if (last.flags & READ_OUT_BUSY) {
        warnx("still reading, try again");
        transact(OP_READ_ADDR, waddr);
    }
    if (last.flags & READ_OUT_BUSY)
        err(1, "busy busy");

    if (last.unit() != unit)
        errx(1, "unexpected unit %i not %i", last.unit(), unit);
    if (last.raddr != waddr)
        errx(1, "unexpected read address %i not %i", last.raddr, waddr);
    if (last.waddr != ((waddr + 5) & 1023))
        errx(1, "unexpected write address %i not %i+5\n",
             last.waddr, waddr);
    return last;
}


std::vector<read_out_t> fifo_read_all(int unit)
{
    std::vector<read_out_t> result;
    while (last.nempty & 1 << unit)
        result.push_back(fifo_read(unit));
    return result;
}
