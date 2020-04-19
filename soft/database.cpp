
#include "database.h"

#include "packet.h"

#include <err.h>
#include <stdarg.h>
#include <string.h>

static sqlite3 * the_db;


SQL::SQL(const char * sql) :
    stmt(NULL)
{
    int r = sqlite3_prepare_v2(the_db, sql, -1, &stmt, NULL);
    if (r != 0)
        errx(1, "prepare %s failed: %s", sql, sqlite3_errmsg(the_db));
}


SQL::SQL(const char * sql, const char * f, ...) : SQL(sql)
{
    va_list args;
    va_start(args, f);
    bind(f, args);
    va_end(args);
}


SQL::~SQL()
{
    int e = sqlite3_finalize(stmt);
    if (e != 0)
        errx(1, "sqlite3_finalize error: %s", sqlite3_errstr(e));
}


bool SQL::row(const char * f, ...)
{
    va_list args;
    va_start(args, f);
    bool r = row(f, args);
    va_end(args);
    return r;
}


void SQL::error(const char * what)
{
    errx(1, "%s on sql %s failed: %s",
         what, sqlite3_sql(stmt), sqlite3_errmsg(the_db));
}


void SQL::bind(const char * f, va_list ap)
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
                error("bind text");
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
            error("bind int64");
    }
}


bool SQL::row(const char * f, va_list args)
{
    int e = sqlite3_step(stmt);
    if (e == SQLITE_DONE)
        return false;

    if (e != SQLITE_ROW)
        error("step");

    int i = 0;

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

    return true;
}


bool runSQL(const char * sql, const char * f, ...)
{
    SQL s(sql);
    va_list args;
    va_start(args, f);
    s.bind(f, args);
    va_end(args);
    return s.run();
}

void open_db(const char * filename)
{
    int r = sqlite3_open(filename, &the_db);
    if (r != 0)
        errx(1, "sqlite open %s failed: %i", filename, r);

    if (sqlite3_extended_result_codes(the_db, true) != 0)
        errx(1, "sqlite3_extended_result_codes failed %s",
             sqlite3_errmsg(the_db));
}


int insert_read_out(const read_out_t & r)
{
    text_code_t t = r.text();
    r.print();

    uint64_t p_count = 0;
    const char * p_value = "";
    int p_is_inject = 0;
    int p_mult = 0;

    // Check for a duplicate...
    SQL last(
        "SELECT count,value,is_inject,mult FROM samples "
        "WHERE id = ? and count <= ? ORDER BY count DESC LIMIT 1",
        "%i %li", r.unit_cycle(), r.count());
    last.row("%li %ms %i %i", &p_count, &p_value, &p_is_inject, &p_mult);

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
    if (SQL("SELECT MAX(count) FROM samples WHERE id = ?", "%i", r.unit_cycle())
        .row("%li", &p_count)
        && p_count >= r.count())
        errx(1, "count jumps backwards, old %lu after new %lu",
             p_count, r.count());

    // Now find the multiplicity to use.
    int mult = 0;
    if (SQL("SELECT MAX(mult) FROM samples WHERE value = ?", "%s", t.text)
        .row("%i", &mult) && mult > 0)
        printf("***** HIT (%i) *****\n", mult);

    runSQL(
        "INSERT INTO samples(id,count,value,is_inject,mult) VALUES(?,?,?,?,?)",
        "%i %li %s %i %i",
        r.unit_cycle(), r.count(), t.text, r.is_inject(), mult + 1);

    if (mult > 0)
        runSQL("UPDATE samples SET hit = 1 WHERE value = ?", "%s", t.text);

    return mult;
}
