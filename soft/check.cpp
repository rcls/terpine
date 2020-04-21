// Select random rows and check them...
#include "database.h"
#include "packet.h"
#include "server.h"

#include <err.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>

IterationServer IterationServer::it;

static bool start(void);

static void done(IterationRequest * r,
                 text_code_t text1, text_code_t text2)
{
    if (strcmp(r->text, text2) == 0) {
        printf("%s -> %s (%li)\n",
               text1.text, r->text.text, r->end - r->start);
    }
    else {
        printf("%s -> %s (%li) FAIL %s\n",
               text1.text, r->text.text, r->end - r->start, text2.text);
    }
    delete r;

    std::unique_lock<std::mutex> lock(IterationServer::it.mutex);
    while (!start());
    IterationServer::it.condvar.notify_all();
}


static bool start(void)
{
    text_code_t key = {};
    for (int i = 0; i < 20; ++i) {
        int c = rand() % 32 + '0';
        if (c > '9')
            c += 'a' - '9' - 1;
        key.text[i] = c;
    }
    key.text[20] = 0;

    int id;
    uint64_t count2;
    text_code_t text2;
    int is_inject;
    if (!SQL("SELECT id,count,value,is_inject FROM samples "
             "WHERE value < ? ORDER BY value DESC LIMIT 1", key.text)
        .row(&id, &count2, &text2, &is_inject)) {
        printf("Got nothing, try again.\n");
        return false;
    }

    if (is_inject) {
        printf("Got inject, try again...\n");
        return false;
    }

    uint64_t count1;
    text_code_t text1;
    SQL("SELECT count,value FROM samples "
        "WHERE id = ? AND count < ? ORDER BY count DESC LIMIT 1", id, count2)
        .get(&count1, &text1);

    IterationServer::it.pending.push(
        new IterationRequest(
            text1, count1, count2,
            [text1,text2](IterationRequest * r) { done(r, text1, text2); }));

    return true;
}


int main()
{
    setlinebuf(stdout);
    srand(time(NULL));
    open_db("log100.db");
    for (int i = 0; i < 57; ++i)
        while (!start());

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
