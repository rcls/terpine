
#include "database.h"

#include "packet.h"

#include <err.h>
#include <string.h>
#include <unistd.h>

static sqlite3 * the_db;


SQL::SQL(const char * sql) :
    stmt(NULL)
{
    int r = sqlite3_prepare_v2(the_db, sql, -1, &stmt, NULL);
    if (r != 0)
        errx(1, "prepare %s failed: %s", sql, sqlite3_errmsg(the_db));
}


SQL::~SQL()
{
    int e = sqlite3_finalize(stmt);
    if (e != 0)
        errx(1, "sqlite3_finalize error: %s", sqlite3_errstr(e));
}


void SQL::error(const char * what)
{
    errx(1, "%s on sql %s failed: %s",
         what, sqlite3_sql(stmt), sqlite3_errmsg(the_db));
}


void SQL::bindat(int n, int64_t v)
{
    if (sqlite3_bind_int64(stmt, n, v) != 0)
        error("bind int");
}


void SQL::bindat(int n, const char * v)
{
    if (sqlite3_bind_text(stmt, n, v, -1, SQLITE_TRANSIENT) != 0)
        error("bind text");
}


bool SQL::run()
{
    switch (sqlite3_step(stmt)) {
    case SQLITE_ROW:
        return true;
    case SQLITE_DONE:
        return false;
    default:
        error("step");
    }
}


void SQL::exists()
{
    if (sqlite3_step(stmt) != SQLITE_ROW)
        error("exists");
}


void SQL_column(sqlite3_stmt * stmt, int n, text_code_t * t)
{
    snprintf(t->text, sizeof t->text, "%s", sqlite3_column_text(stmt, n));
}


static int busy(void *, int iters)
{
    printf(" .... db busy %i\n", iters);
    sleep(iters);
    return true;
}


void open_db(const char * filename)
{
    int r = sqlite3_open(filename, &the_db);
    if (r != 0)
        errx(1, "sqlite open %s failed: %i", filename, r);

    if (sqlite3_extended_result_codes(the_db, true) != 0)
        errx(1, "sqlite3_extended_result_codes failed: %s",
             sqlite3_errmsg(the_db));

    if (sqlite3_busy_handler(the_db, busy, NULL) != 0)
        errx(1, "sqlite3_busy_handler failed: %s",
             sqlite3_errmsg(the_db));
}


int insert_read_out(const read_out_t & r)
{
    r.print();
    text_code_t t = r.text();

    uint64_t p_count = 0;
    text_code_t p_value = {};
    int p_is_inject = 0;
    int p_mult = 0;

    // Check for a duplicate...
    SQL("SELECT count,value,is_inject,mult FROM samples "
        "WHERE id = ? and count <= ? ORDER BY count DESC LIMIT 1",
        r.unit_cycle(), r.count())
        .row(&p_count, &p_value, &p_is_inject, &p_mult);

    if (p_count == r.count()
        && strcmp(p_value, t) == 0
        && p_is_inject == r.is_inject()) {
        printf(".... duplicate row, ignore\n");
        return -1;
    }

    // Check whether or not to insert the row.  We discard if this is not
    // an inject and the previous row indicates:
    // 1. start up
    // 2. hit
    // [3. restart should be included, i.e, count before count offset?]
    if (!r.is_inject()) {
        if (p_count == 0) {
            printf(".... unit not initialized, ignore\n");
            return -1;
        }
        if (p_mult > 1) {
            printf(".... unit not reinitialized since hit, ignore\n");
            return -1;
        }
    }

    // Get the last count.  Attempting to insert with a count going backwards is
    // always an error.
    if (SQL("SELECT MAX(count) FROM samples WHERE id = ?", r.unit_cycle())
        .row(&p_count)
        && p_count >= r.count())
        errx(1, "count jumps backwards, old %lu after new %lu",
             p_count, r.count());

    // Now find the multiplicity to use.
    int mult = 0;
    if (SQL("SELECT MAX(mult) FROM samples WHERE value = ?", t.text)
        .row(&mult) && mult > 0)
        printf("***** HIT (%i) *****\n", mult);

    runSQL(
        "INSERT INTO samples(id,count,value,is_inject,mult) VALUES(?,?,?,?,?)",
        r.unit_cycle(), r.count(), t.text, r.is_inject(), mult + 1);

    if (mult > 0)
        runSQL("UPDATE samples SET hit = 1 WHERE value = ?", t.text);

    return mult;
}
