
#include "server.h"

#include "model.h"
#include "packet.h"

#undef NDEBUG
#include <assert.h>
#include <endian.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>

typedef uint32_t v1u __attribute__((vector_size(4)));
typedef uint32_t v4u __attribute__((vector_size(16)));
typedef uint32_t v8u __attribute__((vector_size(32)));
typedef uint32_t unal32_t __attribute__((aligned(1), may_alias));

template<int W> struct vu_t { };
template<> struct vu_t<1> { typedef v1u v; };
template<> struct vu_t<4> { typedef v4u v; };
template<> struct vu_t<8> { typedef v8u v; };

// Assumes (a vector of) uint32_t.
template<typename T>
static inline T leftrot(T v, int bits) {
    return (v << bits) + (v >> (32 - bits));
}

static inline v1u vrotate(v1u v)
{
    return v + 1;                       // Anything different....
}

static inline v4u vrotate(v4u v)
{
    return __builtin_shuffle(v, (v4u) {1, 2, 3, 0});
}

static inline v8u vrotate(v8u v)
{
    return __builtin_shuffle(v, (v8u) {1, 2, 3, 4, 5, 6, 7, 0});
}

static inline bool is_zero(v1u v)
{
    return (uint32_t) v == 0;
}
static bool is_zero(v4u v)
{
    typedef long long v2du __attribute__((vector_size(16)));
    auto d = reinterpret_cast<v2du>(v);
    return __builtin_ia32_ptestz128(d, d);
}
static inline bool is_zero(v8u v)
{
    typedef long long v4du __attribute__((vector_size(32)));
    auto d = reinterpret_cast<v4du>(v);
    return __builtin_ia32_ptestz256(d, d);
}

template<typename T>
static inline T expand20(T v)
{
    typedef uint8_t vb_t __attribute__ ((vector_size(sizeof v)));

    v = (v & 0x3ff) + (v & 0xffc00) * 64;
    v = v + (v & 0x03e003e0) * 7;
    vb_t b = (vb_t) v;
    vb_t bigger = (b >= 10);
    b = b + '0' + (bigger & ('a' - '0' - 10));
    return (T) b;
}


static const uint32_t K0 = 0x5a827999;
static const uint32_t K1 = 0x6ed9eba1;
static const uint32_t K2 = 0x8f1bbcdc;
static const uint32_t K3 = 0xca62c1d6;

#define F0(B,C,D) ((B & C) | (~B & D))
#define F1(B,C,D) (B ^ C ^ D)
#define F2(B,C,D) ((B & C) | (B & D) | (C & D))
#define F3(B,C,D) (B ^ C ^ D)

#define ROUND(i, F, K) do {                                     \
        if (i >= 16)                                            \
            W[i & 15] = leftrot(                                \
                W[(i-3) & 15] ^ W[(i-8) & 15]                   \
                ^ W[(i-14) & 15] ^ W[(i-16) & 15], 1);          \
        T nextA = leftrot(A, 5) + F(B,C,D) + E + K + W[i & 15]; \
        E = D;                                                  \
        D = C;                                                  \
        C = leftrot(B, 30);                                     \
        B = A;                                                  \
        A = nextA;                                              \
    } while (0)


template<typename T>
static void sha1chunk(T __restrict__ W[16], T __restrict__ state[5])
{
    T A = state[0];
    T B = state[1];
    T C = state[2];
    T D = state[3];
    T E = state[4];

#if 0
    for (int i = 0; i < 16; ++i)
        ROUND(i, F0, K0);
    for (int i = 16; i < 20; ++i)
        ROUND(i, F0, K0);
    for (int i = 20; i < 40; ++i)
        ROUND(i, F1, K1);
    for (int i = 40; i < 60; ++i)
        ROUND(i, F2, K2);
    for (int i = 60; i < 80; ++i)
        ROUND(i, F3, K3);
#else
    ROUND( 0, F0, K0);
    ROUND( 1, F0, K0);
    ROUND( 2, F0, K0);
    ROUND( 3, F0, K0);
    ROUND( 4, F0, K0);
    ROUND( 5, F0, K0);
    ROUND( 6, F0, K0);
    ROUND( 7, F0, K0);
    ROUND( 8, F0, K0);
    ROUND( 9, F0, K0);
    ROUND(10, F0, K0);
    ROUND(11, F0, K0);
    ROUND(12, F0, K0);
    ROUND(13, F0, K0);
    ROUND(14, F0, K0);
    ROUND(15, F0, K0);
    ROUND(16, F0, K0);
    ROUND(17, F0, K0);
    ROUND(18, F0, K0);
    ROUND(19, F0, K0);

    ROUND(20, F1, K1);
    ROUND(21, F1, K1);
    ROUND(22, F1, K1);
    ROUND(23, F1, K1);
    ROUND(24, F1, K1);
    ROUND(25, F1, K1);
    ROUND(26, F1, K1);
    ROUND(27, F1, K1);
    ROUND(28, F1, K1);
    ROUND(29, F1, K1);
    ROUND(30, F1, K1);
    ROUND(31, F1, K1);
    ROUND(32, F1, K1);
    ROUND(33, F1, K1);
    ROUND(34, F1, K1);
    ROUND(35, F1, K1);
    ROUND(36, F1, K1);
    ROUND(37, F1, K1);
    ROUND(38, F1, K1);
    ROUND(39, F1, K1);

    ROUND(40, F2, K2);
    ROUND(41, F2, K2);
    ROUND(42, F2, K2);
    ROUND(43, F2, K2);
    ROUND(44, F2, K2);
    ROUND(45, F2, K2);
    ROUND(46, F2, K2);
    ROUND(47, F2, K2);
    ROUND(48, F2, K2);
    ROUND(49, F2, K2);
    ROUND(50, F2, K2);
    ROUND(51, F2, K2);
    ROUND(52, F2, K2);
    ROUND(53, F2, K2);
    ROUND(54, F2, K2);
    ROUND(55, F2, K2);
    ROUND(56, F2, K2);
    ROUND(57, F2, K2);
    ROUND(58, F2, K2);
    ROUND(59, F2, K2);

    ROUND(60, F3, K3);
    ROUND(61, F3, K3);
    ROUND(62, F3, K3);
    ROUND(63, F3, K3);
    ROUND(64, F3, K3);
    ROUND(65, F3, K3);
    ROUND(66, F3, K3);
    ROUND(67, F3, K3);
    ROUND(68, F3, K3);
    ROUND(69, F3, K3);
    ROUND(70, F3, K3);
    ROUND(71, F3, K3);
    ROUND(72, F3, K3);
    ROUND(73, F3, K3);
    ROUND(74, F3, K3);
    ROUND(75, F3, K3);
    ROUND(76, F3, K3);
    ROUND(77, F3, K3);
    ROUND(78, F3, K3);
    ROUND(79, F3, K3);
#endif

    state[0] += A;
    state[1] += B;
    state[2] += C;
    state[3] += D;
    state[4] += E;
}


template<typename T>
static void cycle(T out[16], T in [5])
{
    T state[5] = { T() + 0x67452301, T() + 0xefcdab89, T() + 0x98badcfe,
                   T() + 0x10325476, T() + 0xc3d2e1f0 };

    for (int i = 0; i < 5; ++i)
        out[i] = in[i];
    out[5] = T() + 0x80000000;
    for (int i = 6; i < 15; ++i)
        out[i] = T();
    out[15] = T() + 160;

    sha1chunk<T>(out, state);

    out[4] = expand20( state[0] >> 12);
    out[3] = expand20((state[0] <<  8) + (state[1] >> 24));
    out[2] = expand20( state[1] >>  4);
    out[1] = expand20((state[1] << 16) + (state[2] >> 16));
    out[0] = expand20((state[2] <<  4) + (state[3] >> 28));
#ifdef MASK80
    out[0] = expand20(T());
#endif
}

template<typename T, int WIDTH>
void pack(T W[5], const text_code_t t[WIDTH])
{
    for (int i = 0; i < 5; ++i) {
        for (int j = 0; j < WIDTH; ++j)
            W[i][j] = be32toh(((unal32_t *) t[j].text)[i]);
    }
}

template<typename T, int WIDTH>
void unpack(text_code_t t[WIDTH], const T W[5])
{
    for (int i = 0; i < 5; ++i) {
        for (int j = 0; j < WIDTH; ++j)
            ((unal32_t *) t[j].text)[i] = htobe32(W[i][j]);
    }
    for (int j = 0; j < WIDTH; ++j)
        t[j].text[20] = 0;
}


void raw(uint32_t out[5], const text_code_t & in)
{
    v1u state[5] = {
        {0x67452301}, {0xefcdab89}, {0x98badcfe}, {0x10325476}, {0xc3d2e1f0} };

    v1u W[16];
    pack<v1u, 1>(W, &in);
    W[5] = v1u() + 0x80000000;
    for (int i = 6; i < 15; ++i)
        W[i] = v1u();
    W[15] = v1u() + 160;

    sha1chunk<v1u>(W, state);
    memcpy(out, state, sizeof state);
}


// Note return value; if something interesting happens after N iterations, we
// actually return N-1.
template<int WIDTH>
uint64_t cycle(text_code_t t[WIDTH], uint64_t count, checkpoint_fn cp)
{
    typedef typename vu_t<WIDTH>::v T;
    T U[16] = {};
    T V[16] = {};
    pack<T, WIDTH>(U, t);

    T * in = U;
    T * out = V;

    uint64_t done;
    for (done = 0; done < count; ++done, std::swap(in, out)) {
        cycle<T>(out, in);
        if (!cp)
            continue;

        // See if we want to notify.
        bool regular = (done & 0xffffff) == 0;
        bool collide = !is_zero(
            (vrotate(out[1]) == out[1]) & (vrotate(out[2]) == out[2]));
        if (!regular && !collide)
            continue;

        unpack<T, WIDTH>(t, in);
        text_code_t u[WIDTH];
        unpack<T, WIDTH>(u, out);

        if (cp(t, done, u))
            return done;

        pack<T, WIDTH>(out, u);
    }
    unpack<T, WIDTH>(t, in);
    return done;
}

template uint64_t cycle<1>(text_code_t t[1], uint64_t count, checkpoint_fn cp);
template uint64_t cycle<4>(text_code_t t[4], uint64_t count, checkpoint_fn cp);
template uint64_t cycle<8>(text_code_t t[8], uint64_t count, checkpoint_fn cp);

template<int WIDTH>
static void bist(text_code_t & start)
{
    typedef typename vu_t<WIDTH>::v T;
    text_code_t TT[WIDTH];
    text_code_t RR[WIDTH];
    for (int i = 0; i < WIDTH; ++i) {
        start = m_once(start);
        TT[i] = start;
        RR[i] = m_once(m_once(start));
    }
    cycle<WIDTH>(TT, 2);
    for (int i = 0; i < WIDTH; ++i)
        assert(strcmp(TT[i], RR[i]) == 0);

    for (int i = 0; i < WIDTH; ++i) {
        T v = {};
        v[i] = 1;
        assert(!is_zero(v));
    }

    T v = {};
    assert(is_zero(v));
}


void IterationServer::thread()
{
    std::vector<IterationRequest *> processing;
    while (true) {
        // Wait until there is at least one item...
        if (processing.size() < 8) {
            std::unique_lock<std::mutex> lock(mutex);
            if (processing.empty())
                condvar.wait(lock, [this]() { return !pending.empty(); });
            while (!pending.empty()) {
                processing.push_back(pending.front());
                pending.pop();
                if (processing.size() >= 8)
                    break;
            }
        }
        // Now run them.
        text_code_t texts[8];
        int i = 0;
        uint64_t iterations = 1000000;
        for (auto p : processing) {
            texts[i++] = p->text;
            if (p->end - p->done < iterations)
                iterations = p->end - p->done;
        }
        for (; i < 8; ++i) {
            texts[i] = {};
            texts[i].text[0] = 'A' + i;
        }

        if (processing.size() == 1)
            cycle<1>(texts, iterations);
        else if (processing.size() <= 4)
            cycle<4>(texts, iterations);
        else
            cycle<8>(texts, iterations);

        __atomic_fetch_add(&total, iterations * processing.size(),
                           __ATOMIC_RELAXED);

        i = 0;
        std::vector<IterationRequest *> next;
        for (auto p : processing) {
            p->done += iterations;
            p->text = texts[i++];
            if (p->done != p->end)
                next.push_back(p);
            else if (p->callback)
                p->callback(p);
            else
                condvar.notify_all();
        }
        processing = std::move(next);
    }
}


void IterationServer::start_threads(int n)
{
    bist();

    for (int i = 0; i < n; ++i)
        std::thread([this]() { thread(); }).detach();
}


void IterationServer::bist()
{
    text_code_t start = { "abcdefghij0123456789" };
    ::bist<1>(start);
    ::bist<4>(start);
    ::bist<8>(start);
}
