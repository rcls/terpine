#ifndef DATABASE_H_
#define DATABASE_H_

#include <stdarg.h>
#include <stddef.h>
#include <sqlite3.h>

struct read_out_t;

void open_db(const char * filename);
int insert_read_out(const read_out_t & r);


struct SQL {
    SQL() = delete;
    SQL(const char * sql);
    SQL(const char * sql, const char * f, ...)
        __attribute((format(printf,3,4)));
    ~SQL();

    SQL(const SQL & other) = delete;

    bool run() { return row(); }
    bool row(const char * f = "", ...) __attribute__((format(scanf,2,3)));

    // Like row() but error if none.
    void get(const char * f = "", ...) __attribute__((format(scanf,2,3)));

    // Reset and rebind.
    void bind(const char * f, ...);
    void bind(const char * f, va_list args);

    void error(const char * what) __attribute__((noreturn));

private:
    bool row(const char * f, va_list args);

    sqlite3_stmt * stmt;
};

bool runSQL(const char * sql, const char * f = "", ...)
    __attribute((format(printf,2,3)));

#endif
