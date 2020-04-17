#ifndef DATABASE_H_
#define DATABASE_H_

struct read_out_t;

void open_db(const char * filename);
void insert_read_out(const read_out_t & r);

#endif

