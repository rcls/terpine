#ifndef MODEL_H_
#define MODEL_H_

#include "packet.h"

text_code_t b20to32(const uint32_t by20[5]);
text_code_t once(const text_code_t & t);
text_code_t run(const char * text, long s, long e);

#endif

