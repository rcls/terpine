
#include "database.h"

#include "packet.h"

#include <err.h>
#include <stdarg.h>
#include <string.h>

static sqlite3 * the_db;

sqlite3_stmt * s_begin;
sqlite3_stmt * s_commit;
sqlite3_stmt * s_rollback;

static sqlite3_stmt * s_insert;
static sqlite3_stmt * s_last;
static sqlite3_stmt * s_last_count;
static sqlite3_stmt * s_mult;

static void serror(sqlite3_stmt * stmt, const char * what)
    __attribute__((noreturn));
static void serror(sqlite3_stmt * stmt, const char * what)
{
    errx(1, "%s on sql %s failed: %s",
         what, sqlite3_sql(stmt), sqlite3_errmsg(the_db));
}


static void svbindf(sqlite3_stmt * stmt, const char * f, va_list ap)
{
    sqlite3_reset(stmt);

    int i = 0;
    for (const char * p = f; *p; ++p) {
        if (*p != '%')
            continue;

        if (p[1] == 's') {
            ++p;
            const char * v = va_arg(ap, const char *);
            if (sqlite3_bind_text(stmt, ++i, v, -1, SQLITE_TRANSIENT) != 0)
                serror(stmt, "bind text");
            continue;
        }

        int longs = 0;
        while (*++p == 'l')
            ++longs;
        if (*p != 'i')
            errx(1, "unsupported format %s", f);

        int64_t v;
        if (longs == 0)
            v = va_arg(ap, int);
        else if (longs == 1)
            v = va_arg(ap, long);
        else
            v = va_arg(ap, long long);

        if (sqlite3_bind_int64(stmt, ++i, v) != 0)
            serror(stmt, "bind int64");
    }
}

void sbindf(sqlite3_stmt * stmt, const char * f, ...)
{
    va_list ap;
    va_start(ap, f);
    svbindf(stmt, f, ap);
    va_end(ap);
}


int srunf(sqlite3_stmt * stmt, const char * f, ...)
{
    va_list ap;
    va_start(ap, f);
    svbindf(stmt, f, ap);
    va_end(ap);

    int e = sqlite3_step(stmt);
    if (e != SQLITE_DONE && e != SQLITE_ROW)
        serror(stmt, "step");

    return e;
}


bool scolumnf(sqlite3_stmt * stmt, const char * f, ...)
{
    int e = sqlite3_step(stmt);
    if (e == SQLITE_DONE)
        return false;

    if (e != SQLITE_ROW)
        serror(stmt, "step");

    int i = 0;

    va_list args;
    va_start(args, f);

    for (const char * p = f; *p; ++p) {
        if (*p != '%')
            continue;

        int longs = 0;
        while (*++p == 'l')
            ++longs;

        if (p[0] == 'm' && p[1] == 's') {
            const char ** v = va_arg(args, const char **);
            *v = (const char *) sqlite3_column_text(stmt, i++);
            continue;
        }

        if (*p != 'i')
            errx(1, "unknown format character in %s", f);

        switch (longs) {
        case 0: {
            int * v = va_arg(args, int *);
            *v = sqlite3_column_int64(stmt, i++);
            break;
        }
        case 2: {
            long * v = va_arg(args, long *);
            *v = sqlite3_column_int64(stmt, i++);
            break;
        }
        default:
            long long * v = va_arg(args, long long *);
            *v = sqlite3_column_int64(stmt, i++);
            break;
        }
    }

    va_end(args);
    return true;
}


sqlite3_stmt * sprep(const char * s)
{
    sqlite3_stmt * stmt;
    int r = sqlite3_prepare_v2(the_db, s, -1, &stmt, NULL);
    if (r != 0)
        errx(1, "prepare %s failed: %s", s, sqlite3_errmsg(the_db));
    return stmt;
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

    s_begin = sprep("BEGIN");
    s_commit = sprep("COMMIT");
    s_rollback = sprep("ROLLBACK");
    s_insert = sprep(
        "INSERT INTO samples(id,count,value,is_inject,mult) VALUES(?,?,?,?,?)");
    s_last_count = sprep(
        "SELECT MAX(count) FROM samples WHERE id = ?");
    s_mult = sprep("SELECT MAX(mult) FROM samples WHERE value = ?");

    s_last = sprep(
        "SELECT count,value,is_inject,mult FROM samples "
        "WHERE id = ? and count <= ? ORDER BY count DESC LIMIT 1");
}


int insert_read_out(const read_out_t & r)
{
    text_code_t t = r.text();
    r.print();

    // Get the most recent row not after this one, for this unit.
    sbindf(s_last, "%i %li", r.unit_cycle(), r.count());
    uint64_t p_count = 0;
    const char * p_value = "";
    int p_is_inject = 0;
    int p_mult = 0;
    scolumnf(s_last, "%li %ms %i %i",
             &p_count, &p_value, &p_is_inject, &p_mult);

    // Check for a duplicate...
    if (p_count == r.count() && strcmp(p_value, t) == 0
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
    p_count = 0;
    sbindf(s_last_count, "%i", r.unit_cycle());
    scolumnf(s_last_count, "%li", &p_count);
    if (p_count >= r.count())
        errx(1, "count jumps backwards, old %lu after new %lu",
             p_count, r.count());

    // Now find the multiplicity to use.
    int mult = 0;
    sbindf(s_mult, "%s", t.text);
    scolumnf(s_mult, "%i", &mult);
    if (mult > 0)
        printf("***** HIT (%i) *****\n", mult);

    srunf(s_insert, "%i %li %s %i %i",
          r.unit_cycle(), r.count(), t.text, r.is_inject(), mult + 1);

    return mult;
}
