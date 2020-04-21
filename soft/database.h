#ifndef DATABASE_H_
#define DATABASE_H_

#include <stdarg.h>
#include <stddef.h>
#include <stdint.h>
#include <sqlite3.h>
#include <utility>

struct read_out_t;

void open_db(const char * filename);
int insert_read_out(const read_out_t & r);


struct SQL {
    SQL() = delete;
    SQL(const char * sql);

    template<typename... Args>
    SQL(const char * sql, Args&&... args) : SQL(sql) {
        bind(std::forward<Args>(args)...);
    }

    ~SQL();

    SQL(const SQL & other) = delete;

    bool run() { return row(); }
    bool row(const char * f = "", ...) __attribute__((format(scanf,2,3)));

    // Like row() but error if none.
    void get(const char * f = "", ...) __attribute__((format(scanf,2,3)));

    template<typename... Args>
    void bind(Args&&... args) {
        return bind_(1, std::forward<Args>(args)...); }

    void bindat(int n, int64_t v);
    void bindat(int n, const char * v);

    void error(const char * what) __attribute__((noreturn));

private:

    void bind_(int n) const { }

    template<typename T, typename... Args>
    void bind_(int n, T v, Args&&... args) {
        bindat(n, v);
        bind_(n + 1, std::forward<Args>(args)...);
    }

    bool row(const char * f, va_list args);

    sqlite3_stmt * stmt;
};

template<typename... Args>
bool runSQL(const char * sql, Args&&... args)
{
    return SQL(sql, std::forward<Args>(args)...).run();
}

#endif
