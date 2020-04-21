
#include "database.h"
#include "server.h"

#include <assert.h>
#include <err.h>
#include <string.h>

struct Part {
    int id;
    uint64_t count;
    text_code_t sample;

    uint64_t p_count;
    text_code_t p_sample;
};

typedef std::pair<Part,Part> PartPair;
typedef std::vector<PartPair> PartPairs;

static void get_mults(PartPairs & pp)
{
    SQL query("SELECT id,count,sample,is_inject,mult "
              "FROM samples WHERE mult > 1");
    Part p = {};
    int is_inject;
    int mult;
    while (query.row("%i %li %20s %i %i",
                     &p.id, &p.count, p.sample.text, &is_inject, &mult)) {
        if (is_inject)
            errx(1, "Inject set on %i %li %s\n", p.id, p.count, p.sample.text);
        if (mult != 2)
            errx(1, "Mult %i on %i %li %s\n",
                 mult, p.id, p.count, p.sample.text);
        pp.emplace_back(p, Part{});
    }
}


static void get_partners(PartPairs & pp)
{
    SQL sql("SELECT id,count,sample,is_inject FROM samples "
            "WHERE sample = ? AND mult = 1");

    for (auto & p : pp) {
        auto & f = p.second;
        auto & s = p.second;
        int is_inject;
        sql.bind("%s", f.sample.text);
        sql.get("%i %li %20s %i", &s.id, &s.count, s.sample.text, &is_inject);

        if (is_inject)
            errx(1, "Inject set on %i %li %s\n", f.id, f.count, f.sample.text);

        assert(strcmp(f.sample, s.sample) == 0);
    }
}


static void get_preceed(PartPairs & pps)
{
    SQL sql("SELECT count,sample FROM samples WHERE id = ? AND count < ? "
            "ORDER BY count DESC LIMIT 1");

    for (auto & pp : pps) {
        for (auto * p : { &pp.first, &pp.second }) {
            sql.bind("%li %20s", &p->id, &p->count);
            sql.get("%li %20s", &p->p_count, p->p_sample.text);
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


static void extract(const PartPair & pp)
{
    auto & f = pp.first;
    auto & s = pp.second;

    uint64_t delta_f = f.count - f.p_count;
    uint64_t delta_s = s.count - f.p_count;
    uint64_t delta;

    text_code_t text[4] = { f.p_sample, s.p_sample, "A", "B" };
    uint64_t counts[2] = { f.p_count, s.p_count };

    printf("Catch-up");
    if (delta_f < delta_s) {
        // Catch up s...
        cycle<1>(&text[0], delta_s - delta_f, dot);
        counts[0] += delta_s - delta_f;
        delta = delta_f;
    }
    else {
        // Catch up f...
        cycle<1>(&text[1], delta_f - delta_s, dot);
        counts[1] += delta_f - delta_s;
        delta = delta_s;
    }

    // Now iterate...
    uint64_t done = cycle<4>(text, delta, bang);

    if (done == delta)
        errx(1, "Failed on %s (got %s,%s)\n",
             f.sample.text, text[0].text, text[1].text);

    uint32_t res[2][5];
    raw(res[0], text[0]);
    raw(res[1], text[1]);

    for (int i : {0,1})
        printf("%s -> %08x %08x %08x %08x %08x\n", text[i].text,
               res[i][0], res[i][1], res[i][2], res[i][3], res[i][5]);
}


int main()
{
    open_db("log100.db");

    PartPairs pps;
    get_mults(pps);
    get_partners(pps);
    get_preceed(pps);

    for (auto & pp : pps)
        extract(pp);
}
