//
//  BRBase58.h
//
//  Created by Aaron Voisine on 9/15/15.
//  Copyright (c) 2015 breadwallet LLC
//  Update by Roshii on 4/1/18.
//  Copyright (c) 2018 ravencoin core team
//

#ifndef BRBase58_h
#define BRBase58_h

#include <stddef.h>
#include <inttypes.h>

#ifdef __cplusplus
extern "C" {
#endif

// base58 and base58check encoding: https://en.bitcoin.it/wiki/Base58Check_encoding

// returns the number of characters written to str including NULL terminator, or total strLen needed if str is NULL
size_t BRBase58Encode(char *str, size_t strLen, const uint8_t *data, size_t dataLen);

// returns the number of bytes written to data, or total dataLen needed if data is NULL
size_t BRBase58Decode(uint8_t *data, size_t dataLen, const char *str);

// returns the number of characters written to str including NULL terminator, or total strLen needed if str is NULL
size_t BRBase58CheckEncode(char *str, size_t strLen, const uint8_t *data, size_t dataLen);

// returns the number of bytes written to data, or total dataLen needed if data is NULL
size_t BRBase58CheckDecode(uint8_t *data, size_t dataLen, const char *str);

#ifdef __cplusplus
}
#endif

#endif // BRBase58_h
