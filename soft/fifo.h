#ifndef FIFO_H_
#define FIFO_H_

#include "packet.h"

#include <vector>

const read_out_t & fifo_read(int unit);
std::vector<read_out_t> fifo_read_all(int unit);

#endif
