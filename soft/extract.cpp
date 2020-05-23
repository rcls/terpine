
#include "database.h"
#include "server.h"

#include <assert.h>
#include <err.h>
#include <mutex>
#include <thread>
#include <string.h>

struct Part {
    int id;
    uint64_t count;
    text_code_t sample;

    uint64_t p_count;
    text_code_t p_sample;
};
typedef std::array<Part,2> PartPair;
typedef std::vector<PartPair> PartPairs;

static void get_mults(PartPairs & pp)
{
    SQL query("SELECT id,count,value,is_inject,mult FROM samples "
              "WHERE mult > 1 AND NOT EXISTS (SELECT 1 FROM hits "
              "WHERE hits.id == samples.id AND hits.count == samples.count)");
    Part p = {};
    int is_inject;
    int mult;
    while (query.row(&p.id, &p.count, &p.sample, &is_inject, &mult)) {
        if (is_inject)
            errx(1, "Inject set on %i %li %s\n", p.id, p.count, p.sample.text);
        if (mult != 2)
            errx(1, "Mult %i on %i %li %s\n",
                 mult, p.id, p.count, p.sample.text);
        pp.emplace_back(PartPair{p, Part{}});
    }
}


static void get_partners(PartPairs & pps)
{
    SQL sql("SELECT id,count,value,is_inject FROM samples "
            "WHERE value = ? AND mult = 1");

    for (auto & p : pps) {
        int is_inject;
        sql.bind(p[0].sample);
        sql.get(&p[1].id, &p[1].count, &p[1].sample, &is_inject);

        if (is_inject)
            errx(1, "Inject set on %i %li %s\n",
                 p[1].id, p[1].count, p[1].sample.text);

        assert(strcmp(p[0].sample, p[1].sample) == 0);
    }
}


static void get_preceed(PartPairs & pps)
{
    SQL sql("SELECT count,value FROM samples WHERE id = ? AND count < ? "
            "ORDER BY count DESC LIMIT 1");

    for (auto & pp : pps) {
        for (auto & p : pp) {
            sql.bind(p.id, p.count);
            sql.get(&p.p_count, &p.p_sample);
        }
    }
}


static bool dot(const text_code_t *, uint64_t, text_code_t *)
{
    printf(".");
    fflush(NULL);
    return false;
}


static bool bang(const text_code_t *, uint64_t, text_code_t * next)
{
    printf(".");
    fflush(NULL);
    return strcmp(next[0], next[1]) == 0;
}


static void extract(const PartPair & pp, std::mutex * mutex)
{
    for (auto & p : pp)
        printf("%i %lu %s %lu %s\n",
               p.id, p.count, p.sample.text,
               p.p_count, p.p_sample.text);

    auto & p0 = pp[0];
    auto & p1 = pp[1];
    uint64_t delta0 = p0.count - p0.p_count;
    uint64_t delta1 = p1.count - p1.p_count;
    printf("%lu %lu\n", delta0, delta1);
    uint64_t delta;

    text_code_t text[4] = { p0.p_sample, p1.p_sample, "A", "B" };

    if (delta0 < delta1) {
        // Catch up p1...
        uint64_t gap = delta1 - delta0;
        printf("Catch-up 1 %lu ", gap);
        cycle<1>(&text[1], gap, dot);
        delta = delta0;
    }
    else {
        // Catch up p0...
        uint64_t gap = delta0 - delta1;
        printf("Catch-up 0 %lu ", gap);
        cycle<1>(&text[0], gap, dot);
        delta = delta1;
    }

    printf("\nSearch %lu ", delta);
    // Now iterate...
    uint64_t done = cycle<4>(text, delta, bang);
    printf("\n");

    if (done == delta)
        errx(1, "Failed on %s (got %s,%s)\n",
             p0.sample.text, text[0].text, text[1].text);

    std::unique_lock<std::mutex> lock(*mutex);
    runSQL("BEGIN EXCLUSIVE");
    for (int i : {0,1}) {
        uint32_t res[5];
        raw(res, text[i]);
        char image[45];
        snprintf(image, sizeof image, "%08x %08x %08x %08x %08x",
                 res[0], res[1], res[2], res[3], res[4]);
        printf("%s -> %s\n", text[i].text, image);
        runSQL(
            "INSERT INTO hits(id,count,preceed,value,image) VALUES(?,?,?,?,?)",
            pp[i].id, pp[i].count, delta - done, text[i], image);
    }
    runSQL("COMMIT");
}


int main()
{
    open_db("log100.db");

    PartPairs pps;
    get_mults(pps);
    get_partners(pps);
    get_preceed(pps);

    std::mutex mutex;
    std::vector<std::thread> threads;
    for (auto & pp : pps)
        threads.emplace_back(&extract, pp, &mutex);
    for (auto & t : threads)
        t.join();
}
