// ethash: C/C++ implementation of Ethash, the Ethereum Proof of Work algorithm.
// Copyright 2018-2019 Pawel Bylica.
// Licensed under the Apache License, Version 2.0.

/// @file
///
/// ProgPoW API
///
/// This file provides the public API for ProgPoW as the Ethash API extension.

#include "ethash.hpp"


/// The ProgPoW algorithm revision implemented as specified in the spec
/// https://github.com/ifdefelse/ProgPOW#change-history.
//constexpr auto revision = "0.9.3";

const int period_length = 10;
const uint32_t num_regs = 32;
const size_t num_lanes = 16;
const int num_cache_accesses = 11;
const int num_math_operations = 18;
const size_t l1_cache_size = 16 * 1024;
const size_t l1_cache_num_items = l1_cache_size / sizeof(uint32_t);

#ifdef __cplusplus
extern "C" {
#endif

bool light_verify(const union ethash_hash256 header_hash, const union ethash_hash256 mix_hash,const uint64_t nonce, uint8_t* actual);


#ifdef __cplusplus
}
#endif
