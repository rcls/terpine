
#include "database.h"
#include "server.h"

#include <unistd.h>

IterationServer IterationServer::it;

static void start(int n);

static int count;

typedef std::tuple<int,uint64_t,text_code_t> sample_t;


static void done(IterationRequest * r, text_code_t value)
{
    char image[45];
    uint32_t im[5];
    raw(im, r->text);
    snprintf(image, sizeof image, "%08x %08x %08x %08x %08x",
             im[0], im[1], im[2], im[3], im[4]);
    printf("%s -> %s\n", r->text.text, image);

    std::unique_lock<std::mutex> lock(IterationServer::it.mutex);
    runSQL("update prior set prior = ?, image = ? where value = ?",
           r->text, image, value);

    if (++count % 64 == 0)
        start(64);
}

static void start(const sample_t & s)
{
    int id = std::get<0>(s);
    uint64_t count = std::get<1>(s);
    text_code_t value = std::get<2>(s);

    printf("Start %s\n", value.text);
    runSQL("insert into prior(value) values (?)", value);

    uint64_t pcount;
    text_code_t pvalue;
    SQL("select count,value from samples where id = ? and count < ? "
        "order by count desc limit 1", id, count).get(&pcount, &pvalue);

    IterationServer::it.pending.push(
        new IterationRequest(
            pvalue, pcount, count - 1,
            [=](IterationRequest * r) { done(r, value); }));
}

static void start(int n)
{
    std::vector<sample_t> samples;

    {
        SQL zeros("select id,count,value from samples where is_inject == 0 "
                  "and not value in (select value from prior) "
                  "order by "
                  "substr(value,17,4), substr(value,13,4), substr(value,9,4) "
                  "limit ?", n);
        int id;
        uint64_t count;
        text_code_t value;
        while (zeros.row(&id,&count,&value))
            samples.emplace_back(id, count, value);
    }

    for (const auto & s : samples)
        start(s);
}

int main()
{
    open_db("log100.db");

    runSQL("delete from prior where image is null");

    start(128 + 10);

    IterationServer::it.start_threads(8);
    while (true)
        sleep(10000);
}
