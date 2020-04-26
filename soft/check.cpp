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

typedef std::set<std::pair<int64_t, int>> unit_by_checked_t;
static unit_by_checked_t unit_by_checked;
static std::map<int, int64_t> checked;

static void checked_add(int unit, int64_t count)
{
    auto item = checked.emplace(unit, 0).first;
    unit_by_checked.erase(std::make_pair(item->second, item->first));
    item->second += count;
    unit_by_checked.emplace(item->second, item->first);
}


static int next_unit()
{
    auto p = unit_by_checked.begin();
    int r = p->second;
    unit_by_checked.erase(p);
    return r;
}


static bool start(void);

static void done(IterationRequest * r, int id,
                 text_code_t text1, text_code_t text2)
{
    checked_add(id, r->end - r->start);
    if (strcmp(r->text, text2) == 0) {
        printf("%s -> %s (%10li %i:%i:%i)\n", text1.text, r->text.text,
               r->end - r->start, id / 65536, id / 256 % 256, id %256);
    }
    else {
        printf("%s -> %s (%10li %i:%i:%i) FAIL %s\n",
               text1.text, r->text.text, r->end - r->start,
               id / 65536, id / 256 % 256, id %256, text2.text);
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

    int id = next_unit();
    uint64_t count2;
    text_code_t text2;
    int is_inject;
    if (!SQL("SELECT count,value,is_inject FROM samples "
             "WHERE id = ? AND value < ? ORDER BY value DESC LIMIT 1",
             id, key.text)
        .row(&count2, &text2, &is_inject)) {
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
            [=](IterationRequest * r) { done(r, id, text1, text2); }));

    return true;
}


int main()
{
    setlinebuf(stdout);
    srand(time(NULL));
    open_db("log100.db");

    SQL units("SELECT distinct id FROM samples "
              "WHERE is_inject = 0 AND id > 131072");
    int unit;
    while (units.row(&unit))
        checked_add(unit, 0);

    for (int i = 0; i < 57 && !unit_by_checked.empty(); ++i)
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
