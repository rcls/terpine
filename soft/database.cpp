#include "packet.h"

#include <err.h>
#include <sqlite3.h>

static sqlite3 * the_db;

static sqlite3_stmt * s_begin;
static sqlite3_stmt * s_update_count;
static sqlite3_stmt * s_get_count;
static sqlite3_stmt * s_insert;
static sqlite3_stmt * s_commit;
static sqlite3_stmt * s_rollback;

static sqlite3_stmt * prep(const char * s)
{
    sqlite3_stmt * stmt;
    int r = sqlite3_prepare_v2(the_db, s, -1, &stmt, NULL);
    if (r != 0)
        errx(1, "prepare %s failed: %s", s, sqlite3_errmsg(the_db));
    return stmt;
}

static void sbind_int(sqlite3_stmt * stmt, int i, int64_t v)
{
    int r = sqlite3_bind_int64(stmt, i, v);
    if (r != 0)
        errx(1, "sqlite3_bind_int64 failed %s", sqlite3_errmsg(the_db));
}

static void sbind_str(sqlite3_stmt * stmt, int i, const char * v)
{
    int r = sqlite3_bind_text(stmt, i, v, -1, SQLITE_TRANSIENT);
    if (r != 0)
        errx(1, "sqlite3_bind_str failed %s", sqlite3_errmsg(the_db));
}

static void step0(sqlite3_stmt * stmt)
{
    int r = sqlite3_step(stmt);
    if (r != SQLITE_DONE)
        errx(1, "sqlite3_step (0) failed %s", sqlite3_errmsg(the_db));
}


void open_db(const char * filename)
{
    int r = sqlite3_open(filename, &the_db);
    if (r != 0)
        errx(1, "sqlite open %s failed: %i", filename, r);

    r = sqlite3_extended_result_codes(the_db, true);
    if (r != 0)
        errx(1, "sqlite3_extended_result_codes failed %s",
             sqlite3_errmsg(the_db));

    s_begin = prep("BEGIN;");
    s_commit = prep("COMMIT;");
    s_rollback = prep("ROLLBACK;");
    s_update_count = prep(
        "INSERT INTO multiplicity(value, count) VALUES(?, 1) ON CONFLICT(value) DO UPDATE SET count = count + 1;");
    s_insert = prep("INSERT into samples(id,count,value,is_inject) VALUES(?,?,?,?)");
    s_get_count = prep("SELECT count FROM multiplicity WHERE value = ?");
}


void insert_read_out(const read_out_t & r)
{
    r.print();

    step0(s_begin);

    text_code_t t = r.text();
    sqlite3_reset(s_insert);
    sbind_int(s_insert, 1, r.unit_cycle());
    sbind_int(s_insert, 2, r.count());
    sbind_str(s_insert, 3, t.text);
    sbind_int(s_insert, 4, r.is_inject());

    int e = sqlite3_step(s_insert);
    if (e == SQLITE_CONSTRAINT_PRIMARYKEY) {
        printf(".... duplicate row, ignore\n");
        step0(s_rollback);
        return;
    }
    else if (e != SQLITE_DONE)
        errx(1, "sqlite3_step (0) for insert failed %s",
             sqlite3_errmsg(the_db));

    sqlite3_reset(s_update_count);
    sbind_str(s_update_count, 1, t.text);
    step0(s_update_count);

    step0(s_commit);
}
