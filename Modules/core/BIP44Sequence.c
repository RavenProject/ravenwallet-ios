//
// Created by ROSHii on 7/25/18.
//

#include "BIP44Sequence.h"
#include "BRBIP32Sequence.h"
#include "BRCrypto.h"
#include "BRBase58.h"
#include "BRInt.h"
#include <string.h>
#include <assert.h>
#include <stdarg.h>

#define BIP32_SEED_KEY "Bitcoin seed"
#define BIP32_XPRV     "\x04\x88\xAD\xE4"
#define BIP32_XPUB     "\x04\x88\xB2\x1E"

static void _CKDpriv(UInt256 *k, UInt256 *c, uint32_t i) {
    uint8_t buf[sizeof(BRECPoint) + sizeof(i)];
    UInt512 I;

    if (i & BIP32_HARD) {
        buf[0] = 0;
        UInt256Set(&buf[1], *k);
    } else
        BRSecp256k1PointGen((BRECPoint *)buf, k);

    UInt32SetBE(&buf[sizeof(BRECPoint)], i);

    BRHMAC(&I, BRSHA512, sizeof(UInt512), c, sizeof(*c), buf, sizeof(buf)); // I = HMAC-SHA512(c, k|P(k) || i)

    BRSecp256k1ModAdd(k, (UInt256 *)&I); // k = IL + k (mod n)
    *c = *(UInt256 *)&I.u8[sizeof(UInt256)]; // c = IR

    var_clean(&I);
    mem_clean(buf, sizeof(buf));
}

static void _CKDpub(BRECPoint *K, UInt256 *c, uint32_t i) {
    uint8_t buf[sizeof(*K) + sizeof(i)];
    UInt512 I;

    if ((i & BIP32_HARD) != BIP32_HARD) { // can't derive private child key from public parent key
        *(BRECPoint *)buf = *K;
        UInt32SetBE(&buf[sizeof(*K)], i);

        BRHMAC(&I, BRSHA512, sizeof(UInt512), c, sizeof(*c), buf, sizeof(buf)); // I = HMAC-SHA512(c, P(K) || i)

        *c = *(UInt256 *)&I.u8[sizeof(UInt256)]; // c = IR
        BRSecp256k1PointAdd(K, (UInt256 *)&I); // K = P(IL) + K

        var_clean(&I);
        mem_clean(buf, sizeof(buf));
    }
}

// returns the master public key for the default BIP32 wallet layout - derivation path N(m/44'/coinType'/account')
BRMasterPubKey BIP44MasterPubKey(const void *seed, size_t seedLen, uint32_t account, uint32_t coinType) {
    BRMasterPubKey mpk = BR_MASTER_PUBKEY_NONE;
    UInt512 I;
    UInt256 secret, chain;
    BRKey key;

    assert(seed != NULL || seedLen == 0);

    if (seed || seedLen == 0) {
        BRHMAC(&I, BRSHA512, sizeof(UInt512), BIP32_SEED_KEY, strlen(BIP32_SEED_KEY), seed, seedLen);
        secret = *(UInt256 *)&I;
        chain = *(UInt256 *)&I.u8[sizeof(UInt256)];
        var_clean(&I);

        _CKDpriv(&secret, &chain, BIP44_PURPOSE | BIP32_HARD); // path m/44H
        _CKDpriv(&secret, &chain, coinType | BIP32_HARD); // path m/44H/coinType'
        _CKDpriv(&secret, &chain, account | BIP32_HARD); // path m/44H/coinType'/account'

        BRKeySetSecret(&key, &secret, 1);

        mpk.fingerPrint = BRKeyHash160(&key).u32[0];
        mpk.chainCode = chain;

        BRKeySetSecret(&key, &secret, 1);
        var_clean(&secret, &chain);
        BRKeyPubKey(&key, &mpk.pubKey, sizeof(mpk.pubKey)); // path N(m/0H)
        BRKeyClean(&key);
    }

    return mpk;
}

// writes the public key for path N(m/44H/coinType'/account') to pubKey
// returns number of bytes written, or pubKeyLen needed if pubKey is NULL
size_t BIP44PubKey(uint8_t *pubKey, size_t pubKeyLen, BRMasterPubKey mpk, uint32_t chain, uint32_t index ) {
    UInt256 chainCode = mpk.chainCode;

    assert(memcmp(&mpk, &BR_MASTER_PUBKEY_NONE, sizeof(mpk)) != 0);

    if (pubKey && sizeof(BRECPoint) <= pubKeyLen) {
        *(BRECPoint *)pubKey = *(BRECPoint *)mpk.pubKey;

        _CKDpub((BRECPoint *)pubKey, &chainCode, chain); // path N(m/44'/account'/chain)
        _CKDpub((BRECPoint *)pubKey, &chainCode, index); // index'th key in chain

        var_clean(&chainCode);
    }

    return (! pubKey || sizeof(BRECPoint) <= pubKeyLen) ? sizeof(BRECPoint) : 0;
}


// sets the private key for path m/0H/chain/index to each element in keys
void BIP44PrivKeyList(BRKey keys[], size_t keysCount, const void *seed, size_t seedLen, uint32_t coinType,
                      //uint32_t account, uint32_t chain,
                        const uint32_t indexes[]) {
    UInt512 I;
    UInt256 secret, chainCode, s, c;

    assert(keys != NULL || keysCount == 0);
    assert(seed != NULL || seedLen == 0);
    assert(indexes != NULL || keysCount == 0);

    if (keys && keysCount > 0 && (seed || seedLen == 0) && indexes) {
        BRHMAC(&I, BRSHA512, sizeof(UInt512), BIP32_SEED_KEY, strlen(BIP32_SEED_KEY), seed, seedLen);
        secret = *(UInt256 *)&I;
        chainCode = *(UInt256 *)&I.u8[sizeof(UInt256)];
        var_clean(&I);

        // _CKDpriv(&secret, &chainCode, 0 | BIP32_HARD); // path m/0H
        // _CKDpriv(&secret, &chainCode, chain); // path m/0H/chain

        _CKDpriv(&secret, &chainCode, BIP44_PURPOSE | BIP32_HARD); // path m/44H
        _CKDpriv(&secret, &chainCode, BIP44_RVN_COINTYPE | BIP32_HARD); // path m/44H/coinType'
        _CKDpriv(&secret, &chainCode, BIP44_CHANGE | BIP32_HARD); // path m/44H/coinType'/account'

        for (size_t i = 0; i < keysCount; i++) {
            s = secret;
            c = chainCode;
            _CKDpriv(&s, &c, BIP44_CHANGE); // path m/44'/coinType'/account'/chain
            _CKDpriv(&s, &c, indexes[i]); // path m/44'/coinType'/account'/chain/index

            BRKeySetSecret(&keys[i], &s, 1);
        }

        var_clean(&secret, &chainCode, &c, &s);
    }
}

// initial key used for address derivation,- path m/44'/0'/0'
void BIP44AddrKey(BRKey *key, const void *seed, size_t seedLen) {
    BRBIP32PrivKeyPath(key, seed, seedLen, 5, BIP44_PURPOSE | BIP32_HARD, BIP44_RVN_COINTYPE | BIP32_HARD,
                       BIP44_DEFAULT_ACCOUNT | BIP32_HARD);
}


