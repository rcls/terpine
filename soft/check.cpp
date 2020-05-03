// Select random rows and check them...
#include "database.h"
#include "packet.h"
#include "server.h"

#include <err.h>
#include <map>
#include <set>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>

IterationServer IterationServer::it;


static void start(int id);

static void done(IterationRequest * r, int id,
                 text_code_t text1, text_code_t text2)
{
    bool good = strcmp(r->text, text2) == 0;

    printf("%s -> %s (%10li %i:%i:%i)", text1.text, r->text.text,
           r->end - r->start, id / 65536, id / 256 % 256, id %256);
    if (!good)
        printf(" FAIL %s", text2.text);
    printf("\n");

    runSQL("UPDATE samples SET verified=? WHERE id=? AND count=?",
           good, id, r->end);

    delete r;

    std::unique_lock<std::mutex> lock(IterationServer::it.mutex);
    start(id);
    IterationServer::it.condvar.notify_all();
}


static void start(int id)
{
    uint64_t count2;
    text_code_t text2;
    if (!SQL("SELECT count,value FROM samples "
             "WHERE verified IS NULL AND id = ? AND is_inject = 0 "
             "ORDER BY value DESC LIMIT 1", id).row(&count2, &text2)) {
        printf("Got nothing for id %i\n", id);
        return;
    }

    uint64_t count1;
    text_code_t text1;
    SQL("SELECT count,value FROM samples "
        "WHERE id = ? AND count < ? ORDER BY count DESC LIMIT 1", id, count2)
        .get(&count1, &text1);

    IterationServer::it.pending.push(
        new IterationRequest(
            text1, count1, count2,
            [=](IterationRequest * r) { done(r, id, text1, text2); }));
}


int main()
{
    setlinebuf(stdout);
    open_db("log100.db");

    int id;
    for (SQL units("SELECT distinct id FROM samples WHERE id > 131072");
         units.row(&id); )
        start(id);

    printf("Start...\n");
    // Start the server...
    IterationServer::it.start_threads(7);
    uint64_t last_total = 0;
    while (1) {
        sleep(10);
        uint64_t total = __atomic_load_n(&IterationServer::it.total,
                                         __ATOMIC_RELAXED);
        printf("%li in 10 seconds\n", total - last_total);
        last_total = total;
    }
    return 0;
}
