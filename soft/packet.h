#ifndef PACKET_H_
#define PACKET_H_

#include <stdio.h>
#include <stdint.h>

#define READ_OUT_BUSY 1

#define OP_READ_FIFO 5
#define OP_READ_ADDR 6
#define OP_EXECUTE 7

#define CYCLE_BASE 5
#define CYCLE_LIMIT 25
#define COMMAND_CYCLE_MASK 31
#define COMMAND_INJECT 32
#define COMMAND_SAMPLE 64
#define COMMAND_UNIT_SHIFT 8

#define COMMAND_UNIT(unit) ((unit) << COMMAND_UNIT_SHIFT)

struct text_code_t {
    char text[21];
};

struct __attribute__((packed)) read_out_t {
    uint8_t id;                         // 2
    uint8_t flags;
    uint8_t sequence;
    uint8_t seq_hi;
    uint16_t raddr;
    uint16_t waddr;
    uint32_t nempty;
    uint32_t oflow;
    uint16_t read[5][3];

    int unit()       const { return get16(4) & 0x1fff; }
    int cycle()      const { return get16(0) & 31; }
    // Sparse index.
    int unit_cycle() const { return unit() * 256 + cycle(); }
    uint64_t count() const {
        uint64_t r = get16(3);
        r = (r << 16) + get16(2);
        r = (r << 16) + get16(1);
        r = (r << 11) + (get16(0) >> 5);
        return r;
    }

    int print(FILE * f = stdout) const;

    bool is_match()  const { return get16(4) & (1 << 13); }
    bool is_inject() const { return get16(4) & (1 << 14); }
    bool is_sample() const { return get16(4) & (1 << 15); }

    text_code_t text() const;

private:
    uint32_t get20(int i) const {
        return read[i][0] + ((read[i][1] & 15) << 16); }
    uint16_t get16(int i) const {
        return (read[i][1] + (read[i][2] << 16)) >> 4; }
};

extern read_out_t last;

struct __attribute__((packed)) control_t {
    uint8_t id;                         // 1
    uint8_t flags;                      // unused
    uint8_t sequence;
    uint8_t seqhi;                      // unused
    uint8_t opcode;
    uint32_t command;                   // Only 20 bits used.
};

const read_out_t & open_socket();
const read_out_t & transact(control_t & req, bool seq_match = true);
const read_out_t & transact(int opcode, uint32_t command);

const read_out_t & status();

#endif
