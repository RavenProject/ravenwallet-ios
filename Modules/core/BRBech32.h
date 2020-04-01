//
//  BRBech32.h
//
//  Created by Aaron Voisine on 1/20/18.
//  Copyright (c) 2018 breadwallet LLC
//  Update by Roshii on 4/1/18.
//  Copyright (c) 2018 ravencoin core team
//

#ifndef BRBech32_h
#define BRBech32_h

#include <stddef.h>
#include <inttypes.h>

#ifdef __cplusplus
extern "C" {
#endif

// bech32 address format: https://github.com/bitcoin/bips/blob/master/bip-0173.mediawiki

// returns the number of bytes written to data42 (maximum of 42)
size_t BRBech32Decode(char *hrp84, uint8_t *data42, const char *addr);

// data must contain a valid BIP141 witness program
// returns the number of bytes written to addr91 (maximum of 91)
size_t BRBech32Encode(char *addr91, const char *hrp, const uint8_t data[]);

#ifdef __cplusplus
}
#endif

#endif // BRBech32_h
