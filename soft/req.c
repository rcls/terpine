#include <sys/socket.h>
#include <linux/if_packet.h>
#include <net/ethernet.h> /* the L2 protocols */
#include <err.h>
#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

int main()
{
    int s = socket(AF_PACKET, SOCK_DGRAM, 0x5555);
    if (s < 0)
        err(1, "socket");

    /* struct sockaddr_ll a = {} */
    /* a.sll_family = AF_PACKET; */
    /* a.sll_protocol = 0x5555; */
    /* a.sll_interface = .....; */
    /* //a.sll_pkttype */
    /* a.sll_halen = 0; */
    if (setsockopt(s, SOL_SOCKET, SO_BINDTODEVICE, "eth0", 4) < 0)
        err(1, "bind to device");

    struct timeval tv;
    tv.tv_sec = 1;
    tv.tv_usec = 0;
    if (setsockopt(s, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof tv) < 0)
        err(1, "set rcvtimeo");

    while (1) {
        struct sockaddr_ll a = {};
        a.sll_family = AF_PACKET;
        a.sll_protocol = 0x5555;
        a.sll_ifindex = 3;
        a.sll_halen = 6;
        memset(a.sll_addr, 0xff, 6);

        const uint8_t p[64 - 14 - 4] = { 1, 0 };
        if (sendto(s, p, sizeof p, 0, (struct sockaddr *) &a, sizeof a) < 0)
            err(1, "write");

        uint8_t buf[2048];
        int l = read(s, buf, sizeof buf);
        if (l < 0 && errno == EAGAIN)
            continue;
        if (l < 0)
            err(1, "read");

        for (int i = 0; i < l; ++i) {
            printf("%02x", buf[i]);
            if (i % 2 == 1)
                printf(" ");
        }
        printf("\n");
    }
}
