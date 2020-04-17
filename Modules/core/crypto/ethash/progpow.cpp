// ethash: C/C++ implementation of Ethash, the Ethereum Proof of Work algorithm.
// Copyright 2018-2019 Pawel Bylica.
// Licensed under the Apache License, Version 2.0.

#include "progpow.hpp"

#include "bit_manipulation.h"
#include "endianness.hpp"
#include "ethash-internal.hpp"
#include "kiss99.hpp"
#include "keccak.hpp"
#include "ethash.hpp"
#include "helpers.hpp"

#include <array>
#include <iostream>
#include <climits>


#ifdef __cplusplus
extern "C" {
#endif


/// A variant of Keccak hash function for ProgPoW.
///
/// This Keccak hash function uses 800-bit permutation (Keccak-f[800]) with 576 bitrate.
/// It take exactly 576 bits of input (split across 3 arguments) and adds no padding.
///
/// @param header_hash  The 256-bit header hash.
/// @param nonce        The 64-bit nonce.
/// @param mix_hash     Additional 256-bits of data.
/// @return             The 256-bit output of the hash function.
void keccak_progpow_256(uint32_t* st) noexcept
{
    ethash_keccakf800(st);
}

/// The same as keccak_progpow_256() but uses null mix
/// and returns top 64 bits of the output being a big-endian prefix of the 256-bit hash.
inline void keccak_progpow_64(uint32_t* st) noexcept
{
    keccak_progpow_256(st);
}

    static const uint32_t ravencoin_kawpow[15] = {
            0x00000072, //R
            0x00000041, //A
            0x00000056, //V
            0x00000045, //E
            0x0000004E, //N
            0x00000043, //C
            0x0000004F, //O
            0x00000049, //I
            0x0000004E, //N
            0x0000004B, //K
            0x00000041, //A
            0x00000057, //W
            0x00000050, //P
            0x0000004F, //O
            0x00000057, //W
    };

bool light_verify(const union ethash_hash256 header_hash, const union ethash_hash256 mix_hash,const uint64_t nonce, uint8_t* actual) {

    uint32_t state2[8];

    {
        // Absorb phase for initial round of keccak

        uint32_t state[25] = {0x0};     // Keccak's state

        // 1st fill with header data (8 words)
        for (int i = 0; i < 8; i++)
            state[i] = header_hash.word32s[i];
        // 2nd fill with nonce (2 words)
        state[8] = nonce;
        state[9] = nonce >> 32;

        // 3rd apply ravencoin input constraints
        for (int i = 10; i < 25; i++)
            state[i] = ravencoin_kawpow[i-10];

        keccak_progpow_64(state);

        for (int i = 0; i < 8; i++)
            state2[i] = state[i];
    }

    // Absorb phase for last round of keccak (256 bits)

    uint32_t state[25] = {0x0};     // Keccak's state

    // 1st initial 8 words of state are kept as carry-over from initial keccak
    for (int i = 0; i < 8; i++)
        state[i] = state2[i];

    // 2nd subsequent 8 words are carried from digest/mix
    for (int i = 8; i < 16; i++)
        state[i] = mix_hash.word32s[i-8];

    // 3rd apply ravencoin input constraints
    for (int i = 16; i < 25; i++)
        state[i] = ravencoin_kawpow[i - 16];

    // Run keccak loop
    keccak_progpow_256(state);

    ethash_hash256 output;
    for (int i = 0; i < 8; ++i)
        output.word32s[i] = le::uint32(state[i]);

//    if (!is_less_or_equal(output, boundary))
//        return false;

    // Copy the final_hash to the result pointer
//    strcpy(str_final,to_hex(output).c_str());
    memcpy(actual, output.bytes, 32);

    return true;
}

#ifdef __cplusplus
}
#endif
