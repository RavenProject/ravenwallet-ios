//
// Created by ROSHii on 7/25/18.
//


#ifndef BRBIP44Sequence_h
#define BRBIP44Sequence_h

#include "BRKey.h"
#include "BRInt.h"
#include <stddef.h>
#include <inttypes.h>
#include <stdarg.h>
#include "BRBIP32Sequence.h"

#ifdef __cplusplus
extern "C" {
#endif


#define BIP32_HARD                      0x80000000
#define BIP44_PURPOSE                   44
#define BIP44_RVN_COINTYPE              175
#define BIP44_DEFAULT_ACCOUNT           0
#define BIP44_CHANGE                    0

#define SEQUENCE_GAP_LIMIT_EXTERNAL     1
#define SEQUENCE_GAP_LIMIT_INTERNAL     1

BRMasterPubKey BIP44MasterPubKey(const void *seed, size_t seedLen, uint32_t account, uint32_t coinType);

// writes the public key for path N(m/0H/chain/index) to pubKey
// returns number of bytes written, or pubKeyLen needed if pubKey is NULL
size_t BIP44PubKey(uint8_t *pubKey, size_t pubKeyLen, BRMasterPubKey mpk, uint32_t chain, uint32_t index);

// sets the private key for path m/44H/chain/index to each element in keys
void BIP44PrivKeyList(BRKey keys[], size_t keysCount, const void *seed, size_t seedLen, uint32_t coinType,
//                      uint32_t account, uint32_t chain,
                      const uint32_t indexes[]);

void BIP44AddrKey(BRKey *key, const void *seed, size_t seedLen);

#ifdef __cplusplus
}
#endif

#endif // BRBIP44Sequence_h

