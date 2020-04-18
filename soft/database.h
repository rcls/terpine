#ifndef DATABASE_H_
#define DATABASE_H_

#include <sqlite3.h>

struct read_out_t;

void open_db(const char * filename);
int insert_read_out(const read_out_t & r);


void sbindf(sqlite3_stmt * stmt, const char * f = "", ...)
    __attribute__((format(printf,2,3)));
int srunf(sqlite3_stmt * stmt, const char * f = "", ...)
    __attribute__((format(printf,2,3)));
bool scolumnf(sqlite3_stmt * stmt, const char * f, ...)
    __attribute__((format(scanf,2,3)));

sqlite3_stmt * sprep(const char * s);

extern sqlite3_stmt * s_begin;
extern sqlite3_stmt * s_commit;
extern sqlite3_stmt * s_rollback;

#endif
