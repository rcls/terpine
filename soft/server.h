#ifndef SERVER_H_
#define SERVER_H_

#include "packet.h"

#include <condition_variable>
#include <functional>
#include <mutex>
#include <thread>
#include <queue>

typedef std::function<
    bool(const text_code_t *, uint64_t, text_code_t *)> checkpoint_fn;

template<int WIDTH>
extern uint64_t cycle(text_code_t t[WIDTH], uint64_t count,
                      checkpoint_fn cp = NULL);

struct IterationRequest {
    IterationRequest(const text_code_t & t, uint64_t s, uint64_t e) :
        text(t), start(s), end(e), done(s) { }

    text_code_t text;
    uint64_t start;
    uint64_t end;

    uint64_t done;
};

struct IterationServer {
    void request(IterationRequest * req);
    void wait(IterationRequest * req);
    void run(IterationRequest * req);
    static void bist();

    std::queue<IterationRequest *> pending;
    std::mutex mutex;
    std::condition_variable condvar;

    static IterationServer it;

    void start_threads(int num_threads);
    void thread();
};

#endif
