// ethash: C/C++ implementation of Ethash, the Ethereum Proof of Work algorithm.
// Copyright 2018-2019 Pawel Bylica.
// Licensed under the Apache License, Version 2.0.

/// @file
///
/// API design decisions:
///
/// 1. Signed integer type is used whenever the size of the type is not
///    restricted by the Ethash specification.
///    See http://www.aristeia.com/Papers/C++ReportColumns/sep95.pdf.
///    See https://stackoverflow.com/questions/10168079/why-is-size-t-unsigned/.
///    See https://github.com/Microsoft/GSL/issues/171.

#pragma once

#include "memory.h"
#include "ethash.h"
#include "hash_types.hpp"
//constexpr auto revision = ETHASH_REVISION;

static const int epoch_length = ETHASH_EPOCH_LENGTH;
static const int light_cache_item_size = ETHASH_LIGHT_CACHE_ITEM_SIZE;
static const int full_dataset_item_size = ETHASH_FULL_DATASET_ITEM_SIZE;
static const int num_dataset_accesses = ETHASH_NUM_DATASET_ACCESSES;

/// Constructs a 256-bit hash from an array of bytes.
///
/// @param bytes  A pointer to array of at least 32 bytes.
/// @return       The constructed hash.
inline union ethash_hash256 hash256_from_bytes(const uint8_t bytes[32])
{
    union ethash_hash256 h;
    memcpy(&h, bytes, sizeof(h));
    return h;
}
