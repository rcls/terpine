
#include "database.h"
#include "packet.h"

int main()
{
    open_db("temp.sql3");

    read_out_t ro = {};
    ro.set100(0x012345, 0x6789a, 0xbcdef, 0x13579, 0xbdf24);
    ro.set_count(123456 * 32 + 23);
    ro.set_meta((1 << 14) | 5);

    insert_read_out(ro);

    ro.set_count(1234567 * 32 + 32);
    ro.set_meta((1 << 14) | 6);
    ro.set100(0x012345, 0x6789a, 0xbcdef, 0x13579, 0xbdf25);
    insert_read_out(ro);

    ro.set_count(1234567 * 32 + 11);
    ro.set_meta((1 << 14) | 20);
    ro.set100(0x012345, 0x6789a, 0xbcdef, 0x13579, 0xbdf25);
    insert_read_out(ro);

    return 0;
}
