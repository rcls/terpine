
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
typedef std::array<Part,2> PartPair;
typedef std::vector<PartPair> PartPairs;

static void get_mults(PartPairs & pp)
{
    SQL query("SELECT id,count,value,is_inject,mult "
              "FROM samples WHERE mult > 1");
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


static void extract(const PartPair & pp)
{
    auto & f = pp[0];
    auto & s = pp[1];

    uint64_t delta_f = f.count - f.p_count;
    uint64_t delta_s = s.count - f.p_count;
    uint64_t delta;

    text_code_t text[4] = { f.p_sample, s.p_sample, "A", "B" };
    uint64_t counts[2]  = { f.p_count, s.p_count };

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

    runSQL("BEGIN EXCLUSIVE");
    for (int i : {0,1}) {
        uint32_t res[5];
        raw(res, text[i]);
        printf("%s -> %08x %08x %08x %08x %08x\n", text[i].text,
               res[0], res[1], res[2], res[3], res[5]);
        char image[41];
        snprintf(image, sizeof image, "%08x%08x%08x%08x%08x",
                 res[0], res[1], res[2], res[3], res[5]);
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

    for (auto & pp : pps)
        extract(pp);
}
