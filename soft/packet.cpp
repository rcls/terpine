#include <packet.h>

#include <err.h>
#include <errno.h>
#include <linux/if_packet.h>
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>

static int s;

read_out_t last;
static int next_sequence;

const read_out_t & open_socket()
{
    s = socket(AF_PACKET, SOCK_DGRAM, 0x5555);
    if (s < 0)
        err(1, "socket");

    if (setsockopt(s, SOL_SOCKET, SO_BINDTODEVICE, "eth0", 4) < 0)
        err(1, "bind to device");

    struct timeval tv;
    tv.tv_sec = 0;
    tv.tv_usec = 10000;
    if (setsockopt(s, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof tv) < 0)
        err(1, "set rcvtimeo");

    // Do a dummy transact to get a sequence number.
    control_t req = {};
    read_out_t r = transact(req, false);
    printf("Got sequence number: %i\n", r.sequence);
    // And now confirm.
    return transact(req);
}

const read_out_t & status()
{
    control_t req = {};
    return transact(req);
}


const read_out_t & transact(int opcode, uint32_t command)
{
    control_t req;
    req.opcode = opcode;
    req.command = command;
    return transact(req);
}

const read_out_t & transact(control_t & req, bool seq_match)
{
    struct sockaddr_ll a = {};
    a.sll_family = AF_PACKET;
    a.sll_protocol = 0x5555;
    a.sll_ifindex = 3;
    a.sll_halen = 6;
    memset(a.sll_addr, 0xff, 6);

    req.id = 1;
    if (seq_match)
        req.sequence = next_sequence;

    union {
        uint8_t buf[128];
        read_out_t resp;
    } r;

    // Flush any extraneous packets...
    while (recv(s, &r, sizeof r, MSG_DONTWAIT) > 0);

    for (int i = 0; i < 10; ++i) {
        if (sendto(s, &req, sizeof req,
                   0, (struct sockaddr *) &a, sizeof a) < 0)
            err(1, "sendto");

        int l = recv(s, &r, sizeof r, 0);
        if (l < 0 && errno == EAGAIN) {
            warnx("Time out");
            continue;
        }

        if (l < 0)
            err(1, "recv");

        if (l < (int) sizeof r.resp)
            errx(1, "short packet (%i < %zi)\n", l, sizeof r.resp);

        if (!seq_match || r.resp.sequence == ((next_sequence + 1) & 0xff)) {
            next_sequence = r.resp.sequence;
            last = r.resp;
            return last;
        }

        warnx("sequence %i expected %i\n", r.resp.sequence, next_sequence);

        // Do a waiting flush, just to catch up...
        while (recv(s, &r, sizeof r, 0) > 0);
    }
    errx(1, "failed to transact");
}


text_code_t read_out_t::text() const
{
    text_code_t result;
    char * p = result.text;
    for (int i = 0; i < 5; ++i) {
        int v = get20(i);
        for (int j = 15; j >= 0; j -= 5) {
            int bits = (v >> j) & 31;
            if (bits < 10)
                *p++ = bits + '0';
            else
                *p++ = bits - 10 + 'a';
        }
    }
    *p = 0;
    return result;
}


int read_out_t::print(FILE * f) const
{
    return fprintf(f, "Unit %02i:%02i %12lu s%i i%i m%i %s\n",
                   unit(), cycle(), count(),
                   is_sample(), is_inject(), is_match(), text().text);
}
