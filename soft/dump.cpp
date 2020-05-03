#include "fifo.h"
#include "packet.h"
#include "server.h"

#include <err.h>
#include <stdio.h>

static void run(text_code_t text, int64_t c0, int64_t c1)
{
    cycle<1>(&text, c1 - c0);
    printf("Recompute: %s\n", text.text);
}


static void transaction_check()
{
    // Do a double sample of unit 1 cycle 5.
    transact(OP_EXECUTE, COMMAND_SAMPLE | 5 | (1 << COMMAND_UNIT_SHIFT));
    transact(OP_EXECUTE, COMMAND_SAMPLE | 5 | (1 << COMMAND_UNIT_SHIFT));

    // Now read out two items from unit 1, check both on cycle 5.
    auto unit1 = fifo_read_all(1);
    if (unit1.size() != 2)
        errx(1, "unit1.size() is %zi not 2\n", unit1.size());
    unit1[0].print();
    unit1[1].print();

    run(unit1[0].text(), unit1[0].count(), unit1[1].count());

    // Inject on unit 2 cycle 6.
    static const uint32_t bt20[] = {
        0x12345, 0x6789a, 0xcdef0, 0x97531, 0xeb852 };
    for (int i = 0; i < 5; ++i)
        transact(i, bt20[i]);

    // Now do an inject and dump on unit2.
    transact(OP_EXECUTE, COMMAND_INJECT | COMMAND_SAMPLE | 6 | COMMAND_UNIT(2));
    transact(OP_EXECUTE, COMMAND_SAMPLE | 6 | COMMAND_UNIT(2));

    auto unit2 = fifo_read_all(2);
    if (unit2.size() != 3)
        errx(1, "unit2.size() is %zi not 3\n", unit2.size());

    unit2[0].print();
    unit2[1].print();
    unit2[2].print();
    run(unit2[0].text(), unit2[0].count(), unit2[1].count());
    run(unit2[0].text(), unit2[1].count(), unit2[2].count());
}


int main()
{
    open_socket();

    status();
    if (last.flags & READ_OUT_BUSY)
        errx(1, "Read out busy at start-up!\n");

    printf("Fifo bits: %#x\n", last.nempty);
    printf("Overflow : %#x\n", last.oflow);
    printf("Raddr = %i, waddr = %i\n", last.raddr, last.waddr);

    if (last.nempty == 0)
        transaction_check();

    while (last.nempty) {
        for (int unit = 1; unit <= 24; ++unit) {
            if (last.nempty & (1 << unit))
                fifo_read(unit).print();
        }
    }

    return 0;
}
