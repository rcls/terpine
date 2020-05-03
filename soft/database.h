#ifndef DATABASE_H_
#define DATABASE_H_

#include <stdint.h>
#include <sqlite3.h>

struct text_code_t;

void open_db(const char * filename);


struct SQL {
    SQL() = delete;
    SQL(const char * sql);

    template<typename... Args>
    SQL(const char * sql, const Args&... args) : SQL(sql) {
        bind(args...);
    }

    ~SQL();

    SQL(const SQL & other) = delete;

    bool row();
    template<typename... Args>
    bool row(Args*... args) {
        bool r = row();
        if (r)
            columns(0, args...);
        return r;
    }

    void get();                         // Like row() but error if none.
    template<typename... Args>
    void get(Args*... args) {
        get();
        columns(0, args...);
    }

    template<typename... Args>
    void columns(Args*... args) {
        columns(0, args...);
    }

    template<typename... Args>
    void bind(const Args&... args) {
        sqlite3_reset(stmt);
        return bind_(1, args...);
    }

    void bindat(int n, int64_t v);
    void bindat(int n, const char * v);

    void error(const char * what) __attribute__((noreturn));

private:

    void bind_(int n) const { }

    template<typename T, typename... Args>
    void bind_(int n, T v, const Args&... args) {
        bindat(n, v);
        bind_(n + 1, args...);
    }

    void columns(int n) { }
    template<typename T, typename... Args>
    void columns(int n, T * t, Args*... args) {
        SQL_column(stmt, n, t);
        columns(n + 1, args...);
    }

    sqlite3_stmt * stmt;
};

template<typename... Args>
bool runSQL(const char * sql, const Args &... args)
{
    return SQL(sql, args...).row();
}

inline void SQL_column(sqlite3_stmt * stmt, int n, int * p) {
    *p = sqlite3_column_int64(stmt, n); }
inline void SQL_column(sqlite3_stmt * stmt, int n, uint64_t * p) {
    *p = sqlite3_column_int64(stmt, n); }
void SQL_column(sqlite3_stmt * stmt, int n, text_code_t * t);

struct Transaction {
    Transaction(const char * b = "BEGIN EXCLUSIVE") {
        runSQL(b);
    }
    ~Transaction() {
        if (pending)
            runSQL("ROLLBACK");
    }
    void commit() {
        runSQL("COMMIT");
        pending = false;
    }
private:
    bool pending = true;
};

#endif
