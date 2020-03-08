//
//  BRAddress.h
//
//  Created by Aaron Voisine on 9/18/15.
//  Copyright (c) 2015 breadwallet LLC
//  Update by Roshii on 4/1/18.
//  Copyright (c) 2018 ravencoin core team
//

#ifndef BRAddress_h
#define BRAddress_h

#include "BRCrypto.h"
#include "BRScript.h"
#include <string.h>
#include <stddef.h>
#include <inttypes.h>

#ifdef __cplusplus
extern "C" {
#endif

#if TESTNET
#pragma message "testnet build"
#elif REGTEST
#pragma message "regtest build"
#endif

#define MAX_SCRIPT_LENGTH       0x100 // scripts over this size will not be parsed for an address
#define NONE_ASSETS_SCRIPT      0x37

// ravencoin address prefixes
#define RAVENCOIN_PUBKEY_ADDRESS          60
#define RAVENCOIN_SCRIPT_ADDRESS          122

#define RAVENCOIN_PUBKEY_ADDRESS_TEST     111
#define RAVENCOIN_SCRIPT_ADDRESS_TEST     196

#define RAVENCOIN_PUBKEY_ADDRESS_REGTEST  111
#define RAVENCOIN_SCRIPT_ADDRESS_REGTEST  196

// reads a varint from buf and stores its length in intLen if intLen is non-NULL
// returns the varint value
uint64_t BRVarInt(const uint8_t *buf, size_t bufLen, size_t *intLen);

// writes i to buf as a varint and returns the number of bytes written, or bufLen needed if buf is NULL
size_t BRVarIntSet(uint8_t *buf, size_t bufLen, uint64_t i);

// returns the number of bytes needed to encode i as a varint
size_t BRVarIntSize(uint64_t i);

// parses script and writes an array of pointers to the script elements (opcodes and data pushes) to elems
// returns the number of elements written, or elemsCount needed if elems is NULL
size_t BRScriptElements(const uint8_t **elems, size_t elemsCount, const uint8_t *script, size_t scriptLen);

// given a data push script element, returns a pointer to the start of the data and writes its length to dataLen
const uint8_t *BRScriptData(const uint8_t *elem, size_t *dataLen);

// writes a data push script element to script
// returns the number of bytes written, or scriptLen needed if script is NULL
size_t BRScriptPushData(uint8_t *script, size_t scriptLen, const uint8_t *data, size_t dataLen);

typedef struct {
    char s[36];
} BRAddress;

#define ADDRESS_NONE ((BRAddress) { "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0" })

// writes the ravencoin address for a scriptPubKey to addr
// returns the number of bytes written, or addrLen needed if addr is NULL
size_t BRAddressFromScriptPubKey(char *addr, size_t addrLen, const uint8_t *script, size_t scriptLen);

// writes the RAVENCOIN address for a scriptSig to addr
// returns the number of bytes written, or addrLen needed if addr is NULL
size_t BRAddressFromScriptSig(char *addr, size_t addrLen, const uint8_t *script, size_t scriptLen);

// writes the scriptPubKey for addr to script
// returns the number of bytes written, or scriptLen needed if script is NULL
size_t BRAddressScriptPubKey(uint8_t *script, size_t scriptLen, const char *addr);

// returns true if addr is a valid ravencoin address
int BRAddressIsValid(const char *addr);

// writes the 20 byte hash160 of addr to md20 and returns true on success
int BRAddressHash160(void *md20, const char *addr);

// returns a hash value for addr suitable for use in a hashtable
inline static size_t BRAddressHash(const void *addr)
{
    return Murmur3_32(addr, strlen((const char *) addr), 0);
}

// true if addr and otherAddr are equal
inline static int BRAddressEq(const void *addr, const void *otherAddr)
{
    return (addr == otherAddr ||
            strncmp((const char *)addr, (const char *)otherAddr, sizeof(BRAddress)) == 0);
}

#ifdef __cplusplus
}
#endif

#endif // BRAddress_h
