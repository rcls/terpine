
#include "database.h"

#include "packet.h"

#include <err.h>
#include <time.h>
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


bool SQL::row()
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


void SQL::get()
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
    timespec ts = { iters / 10, iters % 10 * 100000000 };
    nanosleep(&ts, NULL);
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

    runSQL("PRAGMA foreign_keys = ON");
}
