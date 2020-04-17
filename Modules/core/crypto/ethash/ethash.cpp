// ethash: C/C++ implementation of Ethash, the Ethereum Proof of Work algorithm.
// Copyright 2018-2019 Pawel Bylica.
// Licensed under the Apache License, Version 2.0.

#include "ethash-internal.hpp"

#include "attributes.h"
#include "bit_manipulation.h"
#include "endianness.hpp"
#include "primes.h"
#include "keccak.hpp"
#include "progpow.hpp"

#include <cassert>
#include <cstdlib>
#include <cstring>
#include <limits>

// Internal constants:
constexpr static int light_cache_init_size = 1 << 24;
constexpr static int light_cache_growth = 1 << 17;
constexpr static int light_cache_rounds = 3;
constexpr static int full_dataset_init_size = 1 << 30;
constexpr static int full_dataset_growth = 1 << 23;
constexpr static int full_dataset_item_parents = 256;

// Verify constants:
static_assert(sizeof(ethash_hash512) == ETHASH_LIGHT_CACHE_ITEM_SIZE, "");
static_assert(sizeof(ethash_hash1024) == ETHASH_FULL_DATASET_ITEM_SIZE, "");
static_assert(light_cache_item_size == ETHASH_LIGHT_CACHE_ITEM_SIZE, "");
static_assert(full_dataset_item_size == ETHASH_FULL_DATASET_ITEM_SIZE, "");

using ::fnv1;
inline ethash_hash512 fnv1(const ethash_hash512& u, const ethash_hash512& v) noexcept
{
    ethash_hash512 r;
    for (size_t i = 0; i < sizeof(r) / sizeof(r.word32s[0]); ++i)
        r.word32s[i] = fnv1(u.word32s[i], v.word32s[i]);
    return r;
}

inline ethash_hash512 bitwise_xor(const ethash_hash512& x, const ethash_hash512& y) noexcept
{
    ethash_hash512 z;
    for (size_t i = 0; i < sizeof(z) / sizeof(z.word64s[0]); ++i)
        z.word64s[i] = x.word64s[i] ^ y.word64s[i];
    return z;
}

