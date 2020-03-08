#include "BRCrypto.h"
#include "BRBloomFilter.h"
#include "BRMerkleBlock.h"
#include "BRWallet.h"
#include "BRKey.h"
#include "BRBIP38Key.h"
#include "BRAddress.h"
#include "BRBase58.h"
#include "BRBIP39Mnemonic.h"
#include "BRBIP39WordsEn.h"
#include "BRBIP44Sequence.h"
#include "BRPeer.h"
#include "BRPeerManager.h"
#include "BRChainParams.h"
#include "BRInt.h"
#include "BRArray.h"
#include "BRSet.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>
#include <errno.h>
#include <time.h>
#include <unistd.h>
#include <arpa/inet.h>
#include "BRAssets.h"
#include "BRScript.h"

#define SKIP_BIP38 1

#ifdef __ANDROID__
#include <android/log.h>
#define fprintf(...) __android_log_print(ANDROID_LOG_ERROR, "rvn", _va_rest(__VA_ARGS__, NULL))
#define printf(...) __android_log_print(ANDROID_LOG_INFO, "rvn", __VA_ARGS__)
#define _va_first(first, ...) first
#define _va_rest(first, ...) __VA_ARGS__
#endif

#if TESTNET
#define BR_CHAIN_PARAMS BRTestNetParams
//#elif REGTEST
//#define BR_CHAIN_PARAMS BRRegNetParams
#else
#define BR_CHAIN_PARAMS BRMainNetParams
#endif

int IntsTests() {
    // test endianess
    
    int r = 1;
    union {
        uint8_t u8[8];
        uint16_t u16;
        uint32_t u32;
        uint64_t u64;
    } x = { 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08 };
    
    if (UInt16GetBE(&x) != 0x0102) r = 0, fprintf(stderr, "***FAILED*** %s: UInt16GetBE() test\n", __func__);
    if (UInt16GetLE(&x) != 0x0201) r = 0, fprintf(stderr, "***FAILED*** %s: UInt16GetLE() test\n", __func__);
    if (UInt32GetBE(&x) != 0x01020304) r = 0, fprintf(stderr, "***FAILED*** %s: UInt32GetBE() test\n", __func__);
    if (UInt32GetLE(&x) != 0x04030201) r = 0, fprintf(stderr, "***FAILED*** %s: UInt32GetLE() test\n", __func__);
    if (UInt64GetBE(&x) != 0x0102030405060708)
        r = 0, fprintf(stderr, "***FAILED*** %s: UInt64GetBE() test\n", __func__);
    if (UInt64GetLE(&x) != 0x0807060504030201)
        r = 0, fprintf(stderr, "***FAILED*** %s: UInt64GetLE() test\n", __func__);

    UInt16SetBE(&x, 0x0201);
    if (x.u8[0] != 0x02 || x.u8[1] != 0x01) r = 0, fprintf(stderr, "***FAILED*** %s: UInt16SetBE() test\n", __func__);

    UInt16SetLE(&x, 0x0201);
    if (x.u8[0] != 0x01 || x.u8[1] != 0x02) r = 0, fprintf(stderr, "***FAILED*** %s: UInt16SetLE() test\n", __func__);

    UInt32SetBE(&x, 0x04030201);
    if (x.u8[0] != 0x04 || x.u8[1] != 0x03 || x.u8[2] != 0x02 || x.u8[3] != 0x01)
        r = 0, fprintf(stderr, "***FAILED*** %s: UInt32SetBE() test\n", __func__);

    UInt32SetLE(&x, 0x04030201);
    if (x.u8[0] != 0x01 || x.u8[1] != 0x02 || x.u8[2] != 0x03 || x.u8[3] != 0x04)
        r = 0, fprintf(stderr, "***FAILED*** %s: UInt32SetLE() test\n", __func__);

    UInt64SetBE(&x, 0x0807060504030201);
    if (x.u8[0] != 0x08 || x.u8[1] != 0x07 || x.u8[2] != 0x06 || x.u8[3] != 0x05 ||
        x.u8[4] != 0x04 || x.u8[5] != 0x03 || x.u8[6] != 0x02 || x.u8[7] != 0x01)
        r = 0, fprintf(stderr, "***FAILED*** %s: UInt64SetBE() test\n", __func__);

    UInt64SetLE(&x, 0x0807060504030201);
    if (x.u8[0] != 0x01 || x.u8[1] != 0x02 || x.u8[2] != 0x03 || x.u8[3] != 0x04 ||
        x.u8[4] != 0x05 || x.u8[5] != 0x06 || x.u8[6] != 0x07 || x.u8[7] != 0x08)
        r = 0, fprintf(stderr, "***FAILED*** %s: UInt64SetLE() test\n", __func__);
    
    return r;
}

int ArrayTests() {
    int r = 1;
    int *a = NULL, b[] = { 1, 2, 3 }, c[] = { 3, 2 };
    
    array_new(a, 0);                // [ ]
    if (array_count(a) != 0) r = 0, fprintf(stderr, "***FAILED*** %s: array_new() test\n", __func__);

    array_add(a, 0);                // [ 0 ]
    if (array_count(a) != 1 || a[0] != 0) r = 0, fprintf(stderr, "***FAILED*** %s: array_add() test\n", __func__);

    array_add_array(a, b, 3);       // [ 0, 1, 2, 3 ]
    if (array_count(a) != 4 || a[3] != 3) r = 0, fprintf(stderr, "***FAILED*** %s: array_add_array() test\n", __func__);

    array_insert(a, 0, 1);          // [ 1, 0, 1, 2, 3 ]
    if (array_count(a) != 5 || a[0] != 1) r = 0, fprintf(stderr, "***FAILED*** %s: array_insert() test\n", __func__);

    array_insert_array(a, 0, c, 2); // [ 3, 2, 1, 0, 1, 2, 3 ]
    if (array_count(a) != 7 || a[0] != 3)
        r = 0, fprintf(stderr, "***FAILED*** %s: array_insert_array() test\n", __func__);

    array_rm_range(a, 0, 4);        // [ 1, 2, 3 ]
    if (array_count(a) != 3 || a[0] != 1) r = 0, fprintf(stderr, "***FAILED*** %s: array_rm_range() test\n", __func__);
    printf("\n");

    for (size_t i = 0; i < array_count(a); i++) {
        printf("%i, ", a[i]);       // 1, 2, 3,
    }
    
    printf("\n");
    array_insert_array(a, 3, c, 2); // [ 1, 2, 3, 3, 2 ]
    if (array_count(a) != 5 || a[4] != 2)
        r = 0, fprintf(stderr, "***FAILED*** %s: array_insert_array() test 2\n", __func__);
    
    array_insert(a, 5, 1);          // [ 1, 2, 3, 3, 2, 1 ]
    if (array_count(a) != 6 || a[5] != 1) r = 0, fprintf(stderr, "***FAILED*** %s: array_insert() test 2\n", __func__);
    
    array_rm(a, 0);                 // [ 2, 3, 3, 2, 1 ]
    if (array_count(a) != 5 || a[0] != 2) r = 0, fprintf(stderr, "***FAILED*** %s: array_rm() test\n", __func__);

    array_rm_last(a);               // [ 2, 3, 3, 2 ]
    if (array_count(a) != 4 || a[0] != 2) r = 0, fprintf(stderr, "***FAILED*** %s: array_rm_last() test\n", __func__);
    
    array_clear(a);                 // [ ]
    if (array_count(a) != 0) r = 0, fprintf(stderr, "***FAILED*** %s: array_clear() test\n", __func__);
    
    array_free(a);
    printf("                                    ");
    return r;
}

inline static size_t hash_int(const void *i) {
    return (size_t)((0x811C9dc5 ^ *(const unsigned *)i)*0x01000193); // (FNV_OFFSET xor i)*FNV_PRIME
}

inline static int eq_int(const void *a, const void *b) {
    return (*(const int *)a == *(const int *)b);
}

int SetTests() {
    int r = 1;
    int i, x[1000];
    BRSet *s = BRSetNew(hash_int, eq_int, 0);
    
    for (i = 0; i < 1000; i++) {
        x[i] = i;
        BRSetAdd(s, &x[i]);
    }
    
    if (BRSetCount(s) != 1000) r = 0, fprintf(stderr, "***FAILED*** %s: SetAdd() test\n", __func__);
    
    for (i = 999; i >= 0; i--) {
        if (*(int *) BRSetGet(s, &i) != i) r = 0, fprintf(stderr, "***FAILED*** %s: SetGet() test %d\n", __func__, i);
    }
    
    for (i = 0; i < 500; i++) {
        if (*(int *) BRSetRemove(s, &i) != i)
            r = 0, fprintf(stderr, "***FAILED*** %s: SetRemove() test %d\n", __func__, i);
    }

    if (BRSetCount(s) != 500) r = 0, fprintf(stderr, "***FAILED*** %s: SetCount() test 1\n", __func__);

    for (i = 999; i >= 500; i--) {
        if (*(int *) BRSetRemove(s, &i) != i)
            r = 0, fprintf(stderr, "***FAILED*** %s: SetRemove() test %d\n", __func__, i);
    }

    if (BRSetCount(s) != 0) r = 0, fprintf(stderr, "***FAILED*** %s: SetCount() test 2\n", __func__);
    
    return r;
}

int Base58Tests() {
    int r = 1;
    char *s;
    
    s = "#&$@*^(*#!^"; // test bad input
    
    uint8_t buf1[BRBase58Decode(NULL, 0, s)];
    size_t len1 = BRBase58Decode(buf1, sizeof(buf1), s);

    if (len1 != 0) r = 0, fprintf(stderr, "***FAILED*** %s: Base58Decode() test 1\n", __func__);

    uint8_t buf2[BRBase58Decode(NULL, 0, "")];
    size_t len2 = BRBase58Decode(buf2, sizeof(buf2), "");
    
    if (len2 != 0) r = 0, fprintf(stderr, "***FAILED*** %s: Base58Decode() test 2\n", __func__);
    
    s = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
    
    uint8_t buf3[BRBase58Decode(NULL, 0, s)];
    size_t len3 = BRBase58Decode(buf3, sizeof(buf3), s);
    char str3[BRBase58Encode(NULL, 0, buf3, len3)];

    BRBase58Encode(str3, sizeof(str3), buf3, len3);
    if (strcmp(str3, s) != 0) r = 0, fprintf(stderr, "***FAILED*** %s: Base58Decode() test 3\n", __func__);

    s = "1111111111111111111111111111111111111111111111111111111111111111111";

    uint8_t buf4[BRBase58Decode(NULL, 0, s)];
    size_t len4 = BRBase58Decode(buf4, sizeof(buf4), s);
    char str4[BRBase58Encode(NULL, 0, buf4, len4)];

    BRBase58Encode(str4, sizeof(str4), buf4, len4);
    if (strcmp(str4, s) != 0) r = 0, fprintf(stderr, "***FAILED*** %s: Base58Decode() test 4\n", __func__);

    s = "111111111111111111111111111111111111111111111111111111111111111111z";

    uint8_t buf5[BRBase58Decode(NULL, 0, s)];
    size_t len5 = BRBase58Decode(buf5, sizeof(buf5), s);
    char str5[BRBase58Encode(NULL, 0, buf5, len5)];

    BRBase58Encode(str5, sizeof(str5), buf5, len5);
    if (strcmp(str5, s) != 0) r = 0, fprintf(stderr, "***FAILED*** %s: Base58Decode() test 5\n", __func__);

    s = "z";
    
    uint8_t buf6[BRBase58Decode(NULL, 0, s)];
    size_t len6 = BRBase58Decode(buf6, sizeof(buf6), s);
    char str6[BRBase58Encode(NULL, 0, buf6, len6)];

    BRBase58Encode(str6, sizeof(str6), buf6, len6);
    if (strcmp(str6, s) != 0) r = 0, fprintf(stderr, "***FAILED*** %s: Base58Decode() test 6\n", __func__);

    s = NULL;
    
    char s1[BRBase58CheckEncode(NULL, 0, (uint8_t *) s, 0)];
    size_t l1 = BRBase58CheckEncode(s1, sizeof(s1), (uint8_t *) s, 0);
    uint8_t b1[BRBase58CheckDecode(NULL, 0, s1)];
    
    l1 = BRBase58CheckDecode(b1, sizeof(b1), s1);
    if (l1 != 0) r = 0, fprintf(stderr, "***FAILED*** %s: Base58CheckDecode() test 1\n", __func__);

    s = "";

    char s2[BRBase58CheckEncode(NULL, 0, (uint8_t *) s, 0)];
    size_t l2 = BRBase58CheckEncode(s2, sizeof(s2), (uint8_t *) s, 0);
    uint8_t b2[BRBase58CheckDecode(NULL, 0, s2)];
    
    l2 = BRBase58CheckDecode(b2, sizeof(b2), s2);
    if (l2 != 0) r = 0, fprintf(stderr, "***FAILED*** %s: Base58CheckDecode() test 2\n", __func__);
    
    s = "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00";
    
    char s3[BRBase58CheckEncode(NULL, 0, (uint8_t *) s, 21)];
    size_t l3 = BRBase58CheckEncode(s3, sizeof(s3), (uint8_t *) s, 21);
    uint8_t b3[BRBase58CheckDecode(NULL, 0, s3)];
    
    l3 = BRBase58CheckDecode(b3, sizeof(b3), s3);
    if (l3 != 21 || memcmp(s, b3, l3) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: Base58CheckDecode() test 3\n", __func__);

    s = "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01";
    
    char s4[BRBase58CheckEncode(NULL, 0, (uint8_t *) s, 21)];
    size_t l4 = BRBase58CheckEncode(s4, sizeof(s4), (uint8_t *) s, 21);
    uint8_t b4[BRBase58CheckDecode(NULL, 0, s4)];
    
    l4 = BRBase58CheckDecode(b4, sizeof(b4), s4);
    if (l4 != 21 || memcmp(s, b4, l4) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: Base58CheckDecode() test 4\n", __func__);

    s = "\x05\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF";
    
    char s5[BRBase58CheckEncode(NULL, 0, (uint8_t *) s, 21)];
    size_t l5 = BRBase58CheckEncode(s5, sizeof(s5), (uint8_t *) s, 21);
    uint8_t b5[BRBase58CheckDecode(NULL, 0, s5)];
    
    l5 = BRBase58CheckDecode(b5, sizeof(b5), s5);
    if (l5 != 21 || memcmp(s, b5, l5) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: Base58CheckDecode() test 5\n", __func__);

    return r;
}

int HashTests() {
    // test sha1
    
    int r = 1;
    uint8_t md[64];
    char *s;
    
    s = "Free online SHA1 Calculator, type address here...";
    SHA1(md, s, strlen(s));
//    if (! UInt160Eq(*(UInt160 *)"\x6f\xc2\xe2\x51\x72\xcb\x15\x19\x3c\xb1\xc6\xd4\x8f\x60\x7d\x42\xc1\xd2\xa2\x15",
    if (! UInt160Eq(*(UInt160 *)"\xaf\xcd\xcb\x8c\xdc\x53\xd0\x04\xaf\xcf\x3a\x36\x40\x6d\x87\xfa\x83\x3e\xec\xb6",
                    *(UInt160 *)md)) r = 0, fprintf(stderr, "***FAILED*** %s: SHA1() test 1\n", __func__);

    s = "this is some address to test the sha1 implementation with more than 64bytes of data since it's internal digest "
        "buffer is 64bytes in size";
    SHA1(md, s, strlen(s));
//    if (! UInt160Eq(*(UInt160 *)"\x08\x51\x94\x65\x8a\x92\x35\xb2\x95\x1a\x83\xd1\xb8\x26\xb9\x87\xe9\x38\x5a\xa3",
    if (! UInt160Eq(*(UInt160 *)"\x91\x96\x27\xab\xad\x9c\x66\xc4\xdc\xca\x47\x8d\xe4\x4c\xe0\x9e\x67\xea\x0f\x5b",
                    *(UInt160 *)md)) r = 0, fprintf(stderr, "***FAILED*** %s: SHA1() test 2\n", __func__);
        
    s = "123456789012345678901234567890123456789012345678901234567890";
    SHA1(md, s, strlen(s));
    if (! UInt160Eq(*(UInt160 *)"\x24\x5b\xe3\x00\x91\xfd\x39\x2f\xe1\x91\xf4\xbf\xce\xc2\x2d\xcb\x30\xa0\x3a\xe6",
                    *(UInt160 *)md)) r = 0, fprintf(stderr, "***FAILED*** %s: SHA1() test 3\n", __func__);
    
    // a message exactly 64bytes long (internal buffer size)
    s = "1234567890123456789012345678901234567890123456789012345678901234";
    SHA1(md, s, strlen(s));
    if (! UInt160Eq(*(UInt160 *)"\xc7\x14\x90\xfc\x24\xaa\x3d\x19\xe1\x12\x82\xda\x77\x03\x2d\xd9\xcd\xb3\x31\x03",
                    *(UInt160 *)md)) r = 0, fprintf(stderr, "***FAILED*** %s: SHA1() test 4\n", __func__);
    
    s = ""; // empty
    SHA1(md, s, strlen(s));
    if (! UInt160Eq(*(UInt160 *)"\xda\x39\xa3\xee\x5e\x6b\x4b\x0d\x32\x55\xbf\xef\x95\x60\x18\x90\xaf\xd8\x07\x09",
                    *(UInt160 *)md)) r = 0, fprintf(stderr, "***FAILED*** %s: SHA1() test 5\n", __func__);
    
    s = "a";
    SHA1(md, s, strlen(s));
    if (! UInt160Eq(*(UInt160 *)"\x86\xf7\xe4\x37\xfa\xa5\xa7\xfc\xe1\x5d\x1d\xdc\xb9\xea\xea\xea\x37\x76\x67\xb8",
                    *(UInt160 *)md)) r = 0, fprintf(stderr, "***FAILED*** %s: SHA1() test 6\n", __func__);

    // test sha256
    
    s = "Free online SHA256 Calculator, type address here...";
    SHA256(md, s, strlen(s));
    if (! UInt256Eq(*(UInt256 *)"\x43\xfd\x9d\xeb\x93\xf6\xe1\x4d\x41\x82\x66\x04\x51\x4e\x3d\x78\x73\xa5\x49\xac"
                    "\x87\xae\xbe\xbf\x3d\x1c\x10\xad\x6e\xb0\x57\xd0", *(UInt256 *)md))
        r = 0, fprintf(stderr, "***FAILED*** %s: SHA256() test 1\n", __func__);
        
    s = "this is some address to test the sha256 implementation with more than 64bytes of data since it's internal "
        "digest buffer is 64bytes in size";
    SHA256(md, s, strlen(s));
    if (! UInt256Eq(*(UInt256 *)"\x40\xfd\x09\x33\xdf\x2e\x77\x47\xf1\x9f\x7d\x39\xcd\x30\xe1\xcb\x89\x81\x0a\x7e"
                    "\x47\x06\x38\xa5\xf6\x23\x66\x9f\x3d\xe9\xed\xd4", *(UInt256 *)md))
        r = 0, fprintf(stderr, "***FAILED*** %s: SHA256() test 2\n", __func__);
    
    s = "123456789012345678901234567890123456789012345678901234567890";
    SHA256(md, s, strlen(s));
    if (! UInt256Eq(*(UInt256 *)"\xde\xcc\x53\x8c\x07\x77\x86\x96\x6a\xc8\x63\xb5\x53\x2c\x40\x27\xb8\x58\x7f\xf4"
                    "\x0f\x6e\x31\x03\x37\x9a\xf6\x2b\x44\xea\xe4\x4d", *(UInt256 *)md))
        r = 0, fprintf(stderr, "***FAILED*** %s: SHA256() test 3\n", __func__);
    
    // a message exactly 64bytes long (internal buffer size)
    s = "1234567890123456789012345678901234567890123456789012345678901234";
    SHA256(md, s, strlen(s));
    if (! UInt256Eq(*(UInt256 *)"\x67\x64\x91\x96\x5e\xd3\xec\x50\xcb\x7a\x63\xee\x96\x31\x54\x80\xa9\x5c\x54\x42"
                    "\x6b\x0b\x72\xbc\xa8\xa0\xd4\xad\x12\x85\xad\x55", *(UInt256 *)md))
        r = 0, fprintf(stderr, "***FAILED*** %s: SHA256() test 4\n", __func__);
    
    s = ""; // empty
    SHA256(md, s, strlen(s));
    if (! UInt256Eq(*(UInt256 *)"\xe3\xb0\xc4\x42\x98\xfc\x1c\x14\x9a\xfb\xf4\xc8\x99\x6f\xb9\x24\x27\xae\x41\xe4"
                    "\x64\x9b\x93\x4c\xa4\x95\x99\x1b\x78\x52\xb8\x55", *(UInt256 *)md))
        r = 0, fprintf(stderr, "***FAILED*** %s: SHA256() test 5\n", __func__);
    
    s = "a";
    SHA256(md, s, strlen(s));
    if (! UInt256Eq(*(UInt256 *)"\xca\x97\x81\x12\xca\x1b\xbd\xca\xfa\xc2\x31\xb3\x9a\x23\xdc\x4d\xa7\x86\xef\xf8"
                    "\x14\x7c\x4e\x72\xb9\x80\x77\x85\xaf\xee\x48\xbb", *(UInt256 *)md))
        r = 0, fprintf(stderr, "***FAILED*** %s: SHA256() test 6\n", __func__);

    // test sha512
    
    s = "Free online SHA512 Calculator, type address here...";
    SHA512(md, s, strlen(s));
    if (! UInt512Eq(*(UInt512 *)"\x04\xf1\x15\x41\x35\xee\xcb\xe4\x2e\x9a\xdc\x8e\x1d\x53\x2f\x9c\x60\x7a\x84\x47"
                    "\xb7\x86\x37\x7d\xb8\x44\x7d\x11\xa5\xb2\x23\x2c\xdd\x41\x9b\x86\x39\x22\x4f\x78\x7a\x51"
                    "\xd1\x10\xf7\x25\x91\xf9\x64\x51\xa1\xbb\x51\x1c\x4a\x82\x9e\xd0\xa2\xec\x89\x13\x21\xf3",
                    *(UInt512 *)md)) r = 0, fprintf(stderr, "***FAILED*** %s: SHA512() test 1\n", __func__);
    
    s = "this is some address to test the sha512 implementation with more than 128bytes of data since it's internal "
        "digest buffer is 128bytes in size";
    SHA512(md, s, strlen(s));
    if (! UInt512Eq(*(UInt512 *)"\x9b\xd2\xdc\x7b\x05\xfb\xbe\x99\x34\xcb\x32\x89\xb6\xe0\x6b\x8c\xa9\xfd\x7a\x55"
                    "\xe6\xde\x5d\xb7\xe1\xe4\xee\xdd\xc6\x62\x9b\x57\x53\x07\x36\x7c\xd0\x18\x3a\x44\x61\xd7"
                    "\xeb\x2d\xfc\x6a\x27\xe4\x1e\x8b\x70\xf6\x59\x8e\xbc\xc7\x71\x09\x11\xd4\xfb\x16\xa3\x90",
                    *(UInt512 *)md)) r = 0, fprintf(stderr, "***FAILED*** %s: SHA512() test 2\n", __func__);
    
    s = "12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567"
        "8901234567890";
    SHA512(md, s, strlen(s));
    if (! UInt512Eq(*(UInt512 *)"\x0d\x9a\x7d\xf5\xb6\xa6\xad\x20\xda\x51\x9e\xff\xda\x88\x8a\x73\x44\xb6\xc0\xc7"
                    "\xad\xcc\x8e\x2d\x50\x4b\x4a\xf2\x7a\xaa\xac\xd4\xe7\x11\x1c\x71\x3f\x71\x76\x95\x39\x62"
                    "\x94\x63\xcb\x58\xc8\x61\x36\xc5\x21\xb0\x41\x4a\x3c\x0e\xdf\x7d\xc6\x34\x9c\x6e\xda\xf3",
                    *(UInt512 *)md)) r = 0, fprintf(stderr, "***FAILED*** %s: SHA512() test 3\n", __func__);
    
    //exactly 128bytes (internal buf size)
    s = "12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567"
        "890123456789012345678";
    SHA512(md, s, strlen(s));
    if (! UInt512Eq(*(UInt512 *)"\x22\x2b\x2f\x64\xc2\x85\xe6\x69\x96\x76\x9b\x5a\x03\xef\x86\x3c\xfd\x3b\x63\xdd"
                    "\xb0\x72\x77\x88\x29\x16\x95\xe8\xfb\x84\x57\x2e\x4b\xfe\x5a\x80\x67\x4a\x41\xfd\x72\xee"
                    "\xb4\x85\x92\xc9\xc7\x9f\x44\xae\x99\x2c\x76\xed\x1b\x0d\x55\xa6\x70\xa8\x3f\xc9\x9e\xc6",
                    *(UInt512 *)md)) r = 0, fprintf(stderr, "***FAILED*** %s: SHA512() test 4\n", __func__);
    
    s = ""; // empty
    SHA512(md, s, strlen(s));
    if (! UInt512Eq(*(UInt512 *)"\xcf\x83\xe1\x35\x7e\xef\xb8\xbd\xf1\x54\x28\x50\xd6\x6d\x80\x07\xd6\x20\xe4\x05"
                    "\x0b\x57\x15\xdc\x83\xf4\xa9\x21\xd3\x6c\xe9\xce\x47\xd0\xd1\x3c\x5d\x85\xf2\xb0\xff\x83"
                    "\x18\xd2\x87\x7e\xec\x2f\x63\xb9\x31\xbd\x47\x41\x7a\x81\xa5\x38\x32\x7a\xf9\x27\xda\x3e",
                    *(UInt512 *)md)) r = 0, fprintf(stderr, "***FAILED*** %s: SHA512() test 5\n", __func__);
    
    s = "a";
    SHA512(md, s, strlen(s));
    if (! UInt512Eq(*(UInt512 *)"\x1f\x40\xfc\x92\xda\x24\x16\x94\x75\x09\x79\xee\x6c\xf5\x82\xf2\xd5\xd7\xd2\x8e"
                    "\x18\x33\x5d\xe0\x5a\xbc\x54\xd0\x56\x0e\x0f\x53\x02\x86\x0c\x65\x2b\xf0\x8d\x56\x02\x52"
                    "\xaa\x5e\x74\x21\x05\x46\xf3\x69\xfb\xbb\xce\x8c\x12\xcf\xc7\x95\x7b\x26\x52\xfe\x9a\x75",
                    *(UInt512 *)md)) r = 0, fprintf(stderr, "***FAILED*** %s: SHA512() test 6\n", __func__);
    
    // test ripemd160
    
    s = "Free online RIPEMD160 Calculator, type address here...";
    RMD160(md, s, strlen(s));
    if (! UInt160Eq(*(UInt160 *)"\x95\x01\xa5\x6f\xb8\x29\x13\x2b\x87\x48\xf0\xcc\xc4\x91\xf0\xec\xbc\x7f\x94\x5b",
                    *(UInt160 *)md)) r = 0, fprintf(stderr, "***FAILED*** %s: RMD160() test 1\n", __func__);
    
    s = "this is some address to test the ripemd160 implementation with more than 64bytes of data since it's internal "
        "digest buffer is 64bytes in size";
    RMD160(md, s, strlen(s));
    if (! UInt160Eq(*(UInt160 *)"\x44\x02\xef\xf4\x21\x57\x10\x6a\x5d\x92\xe4\xd9\x46\x18\x58\x56\xfb\xc5\x0e\x09",
                    *(UInt160 *)md)) r = 0, fprintf(stderr, "***FAILED*** %s: RMD160() test 2\n", __func__);
    
    s = "123456789012345678901234567890123456789012345678901234567890";
    RMD160(md, s, strlen(s));
    if (! UInt160Eq(*(UInt160 *)"\x00\x26\x3b\x99\x97\x14\xe7\x56\xfa\x5d\x02\x81\x4b\x84\x2a\x26\x34\xdd\x31\xac",
                    *(UInt160 *)md)) r = 0, fprintf(stderr, "***FAILED*** %s: RMD160() test 3\n", __func__);
    
    // a message exactly 64bytes long (internal buffer size)
    s = "1234567890123456789012345678901234567890123456789012345678901234";
    RMD160(md, s, strlen(s));
    if (! UInt160Eq(*(UInt160 *)"\xfa\x8c\x1a\x78\xeb\x76\x3b\xb9\x7d\x5e\xa1\x4c\xe9\x30\x3d\x1c\xe2\xf3\x34\x54",
                    *(UInt160 *)md)) r = 0, fprintf(stderr, "***FAILED*** %s: RMD160() test 4\n", __func__);
    
    s = ""; // empty
    RMD160(md, s, strlen(s));
    if (! UInt160Eq(*(UInt160 *)"\x9c\x11\x85\xa5\xc5\xe9\xfc\x54\x61\x28\x08\x97\x7e\xe8\xf5\x48\xb2\x25\x8d\x31",
                    *(UInt160 *)md)) r = 0, fprintf(stderr, "***FAILED*** %s: RMD160() test 5\n", __func__);
    
    s = "a";
    RMD160(md, s, strlen(s));
    if (! UInt160Eq(*(UInt160 *)"\x0b\xdc\x9d\x2d\x25\x6b\x3e\xe9\xda\xae\x34\x7b\xe6\xf4\xdc\x83\x5a\x46\x7f\xfe",
                    *(UInt160 *)md)) r = 0, fprintf(stderr, "***FAILED*** %s: RMD160() test 6\n", __func__);

    // test md5
    
    s = "Free online MD5 Calculator, type address here...";
    MD5(md, s, strlen(s));
    if (! UInt128Eq(*(UInt128 *)"\x5d\xa7\x2e\xd7\x6f\x8a\x0c\x36\xbb\x5e\x20\x05\x66\x9a\x82\xd2",
                    *(UInt128 *)md)) r = 0, fprintf(stderr, "***FAILED*** %s: MD5() test 1\n", __func__);
    
    s = "this is some address to test the md5 implementation with more than 64bytes of data since it's internal digest buffer is 64bytes in size";
    MD5(md, s, strlen(s));
    if (! UInt128Eq(*(UInt128 *)"\x6a\xb3\xb2\x98\x47\x63\x8f\x83\xdf\xe3\xd0\x94\x30\x07\x79\x43",
                    *(UInt128 *)md)) r = 0, fprintf(stderr, "***FAILED*** %s: MD5() test 2\n", __func__);
    
    s = "123456789012345678901234567890123456789012345678901234567890";
    MD5(md, s, strlen(s));
    if (! UInt128Eq(*(UInt128 *)"\xc5\xb5\x49\x37\x7c\x82\x6c\xc3\x71\x24\x18\xb0\x64\xfc\x41\x7e",
                    *(UInt128 *)md)) r = 0, fprintf(stderr, "***FAILED*** %s: MD5() test 3\n", __func__);
    
    // a message exactly 64bytes long (internal buffer size)
    s = "1234567890123456789012345678901234567890123456789012345678901234";
    MD5(md, s, strlen(s));
    if (! UInt128Eq(*(UInt128 *)"\xeb\x6c\x41\x79\xc0\xa7\xc8\x2c\xc2\x82\x8c\x1e\x63\x38\xe1\x65",
                    *(UInt128 *)md)) r = 0, fprintf(stderr, "***FAILED*** %s: MD5() test 4\n", __func__);
    
    s = ""; // empty
    MD5(md, s, strlen(s));
    if (! UInt128Eq(*(UInt128 *)"\xd4\x1d\x8c\xd9\x8f\x00\xb2\x04\xe9\x80\x09\x98\xec\xf8\x42\x7e",
                    *(UInt128 *)md)) r = 0, fprintf(stderr, "***FAILED*** %s: MD5() test 5\n", __func__);
    
    s = "a";
    MD5(md, s, strlen(s));
    if (! UInt128Eq(*(UInt128 *)"\x0c\xc1\x75\xb9\xc0\xf1\xb6\xa8\x31\xc3\x99\xe2\x69\x77\x26\x61",
                    *(UInt128 *)md)) r = 0, fprintf(stderr, "***FAILED*** %s: MD5() test 6\n", __func__);
    
    return r;
}

int MacTests() {
    int r = 1;

    // test hmac
    
    const char k1[] = "\x0b\x0b\x0b\x0b\x0b\x0b\x0b\x0b\x0b\x0b\x0b\x0b\x0b\x0b\x0b\x0b\x0b\x0b\x0b\x0b",
    d1[] = "Hi There";
    uint8_t mac[64];

    HMAC(mac, SHA224, 224 / 8, k1, sizeof(k1) - 1, d1, sizeof(d1) - 1);
    if (memcmp("\x89\x6f\xb1\x12\x8a\xbb\xdf\x19\x68\x32\x10\x7c\xd4\x9d\xf3\x3f\x47\xb4\xb1\x16\x99\x12\xba\x4f\x53"
               "\x68\x4b\x22", mac, 28) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: HMAC() sha224 test 1\n", __func__);

    HMAC(mac, SHA256, 256 / 8, k1, sizeof(k1) - 1, d1, sizeof(d1) - 1);
    if (memcmp("\xb0\x34\x4c\x61\xd8\xdb\x38\x53\x5c\xa8\xaf\xce\xaf\x0b\xf1\x2b\x88\x1d\xc2\x00\xc9\x83\x3d\xa7\x26"
               "\xe9\x37\x6c\x2e\x32\xcf\xf7", mac, 32) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: HMAC() sha256 test 1\n", __func__);

    HMAC(mac, SHA384, 384 / 8, k1, sizeof(k1) - 1, d1, sizeof(d1) - 1);
    if (memcmp("\xaf\xd0\x39\x44\xd8\x48\x95\x62\x6b\x08\x25\xf4\xab\x46\x90\x7f\x15\xf9\xda\xdb\xe4\x10\x1e\xc6\x82"
               "\xaa\x03\x4c\x7c\xeb\xc5\x9c\xfa\xea\x9e\xa9\x07\x6e\xde\x7f\x4a\xf1\x52\xe8\xb2\xfa\x9c\xb6", mac, 48)
        != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: HMAC() sha384 test 1\n", __func__);

    HMAC(mac, SHA512, 512 / 8, k1, sizeof(k1) - 1, d1, sizeof(d1) - 1);
    if (memcmp("\x87\xaa\x7c\xde\xa5\xef\x61\x9d\x4f\xf0\xb4\x24\x1a\x1d\x6c\xb0\x23\x79\xf4\xe2\xce\x4e\xc2\x78\x7a"
               "\xd0\xb3\x05\x45\xe1\x7c\xde\xda\xa8\x33\xb7\xd6\xb8\xa7\x02\x03\x8b\x27\x4e\xae\xa3\xf4\xe4\xbe\x9d"
               "\x91\x4e\xeb\x61\xf1\x70\x2e\x69\x6c\x20\x3a\x12\x68\x54", mac, 64) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: HMAC() sha512 test 1\n", __func__);

    const char k2[] = "Jefe",
    d2[] = "what do ya want for nothing?";

    HMAC(mac, SHA224, 224 / 8, k2, sizeof(k2) - 1, d2, sizeof(d2) - 1);
    if (memcmp("\xa3\x0e\x01\x09\x8b\xc6\xdb\xbf\x45\x69\x0f\x3a\x7e\x9e\x6d\x0f\x8b\xbe\xa2\xa3\x9e\x61\x48\x00\x8f"
               "\xd0\x5e\x44", mac, 28) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: HMAC() sha224 test 2\n", __func__);

    HMAC(mac, SHA256, 256 / 8, k2, sizeof(k2) - 1, d2, sizeof(d2) - 1);
    if (memcmp("\x5b\xdc\xc1\x46\xbf\x60\x75\x4e\x6a\x04\x24\x26\x08\x95\x75\xc7\x5a\x00\x3f\x08\x9d\x27\x39\x83\x9d"
               "\xec\x58\xb9\x64\xec\x38\x43", mac, 32) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: HMAC() sha256 test 2\n", __func__);

    HMAC(mac, SHA384, 384 / 8, k2, sizeof(k2) - 1, d2, sizeof(d2) - 1);
    if (memcmp("\xaf\x45\xd2\xe3\x76\x48\x40\x31\x61\x7f\x78\xd2\xb5\x8a\x6b\x1b\x9c\x7e\xf4\x64\xf5\xa0\x1b\x47\xe4"
               "\x2e\xc3\x73\x63\x22\x44\x5e\x8e\x22\x40\xca\x5e\x69\xe2\xc7\x8b\x32\x39\xec\xfa\xb2\x16\x49", mac, 48)
        != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: HMAC() sha384 test 2\n", __func__);

    HMAC(mac, SHA512, 512 / 8, k2, sizeof(k2) - 1, d2, sizeof(d2) - 1);
    if (memcmp("\x16\x4b\x7a\x7b\xfc\xf8\x19\xe2\xe3\x95\xfb\xe7\x3b\x56\xe0\xa3\x87\xbd\x64\x22\x2e\x83\x1f\xd6\x10"
               "\x27\x0c\xd7\xea\x25\x05\x54\x97\x58\xbf\x75\xc0\x5a\x99\x4a\x6d\x03\x4f\x65\xf8\xf0\xe6\xfd\xca\xea"
               "\xb1\xa3\x4d\x4a\x6b\x4b\x63\x6e\x07\x0a\x38\xbc\xe7\x37", mac, 64) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: HMAC() sha512 test 2\n", __func__);
    
    // test poly1305

    const char key1[] = "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0",
    msg1[] = "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0"
    "\0\0\0\0\0\0\0\0\0\0\0";

    Poly1305(mac, key1, msg1, sizeof(msg1) - 1);
    if (memcmp("\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0", mac, 16) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: Poly1305() test 1\n", __func__);

    const char key2[] = "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\x36\xe5\xf6\xb5\xc5\xe0\x60\x70\xf0\xef\xca\x96\x22\x7a\x86"
    "\x3e",
    msg2[] = "Any submission to the IETF intended by the Contributor for publication as all or part of an IETF "
    "Internet-Draft or RFC and any statement made within the context of an IETF activity is considered an \"IETF "
    "Contribution\". Such statements include oral statements in IETF sessions, as well as written and electronic "
    "communications made at any time or place, which are addressed to";

    Poly1305(mac, key2, msg2, sizeof(msg2) - 1);
    if (memcmp("\x36\xe5\xf6\xb5\xc5\xe0\x60\x70\xf0\xef\xca\x96\x22\x7a\x86\x3e", mac, 16) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: Poly1305() test 2\n", __func__);

    const char key3[] = "\x36\xe5\xf6\xb5\xc5\xe0\x60\x70\xf0\xef\xca\x96\x22\x7a\x86\x3e\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0"
    "\0",
    msg3[] = "Any submission to the IETF intended by the Contributor for publication as all or part of an IETF "
    "Internet-Draft or RFC and any statement made within the context of an IETF activity is considered an \"IETF "
    "Contribution\". Such statements include oral statements in IETF sessions, as well as written and electronic "
    "communications made at any time or place, which are addressed to";

    Poly1305(mac, key3, msg3, sizeof(msg3) - 1);
    if (memcmp("\xf3\x47\x7e\x7c\xd9\x54\x17\xaf\x89\xa6\xb8\x79\x4c\x31\x0c\xf0", mac, 16) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: Poly1305() test 3\n", __func__);
    
    const char key4[] = "\x1c\x92\x40\xa5\xeb\x55\xd3\x8a\xf3\x33\x88\x86\x04\xf6\xb5\xf0\x47\x39\x17\xc1\x40\x2b\x80"
    "\x09\x9d\xca\x5c\xbc\x20\x70\x75\xc0",
    msg4[] = "'Twas brillig, and the slithy toves\nDid gyre and gimble in the wabe:\nAll mimsy were the borogoves,\n"
    "And the mome raths outgrabe.";

    Poly1305(mac, key4, msg4, sizeof(msg4) - 1);
    if (memcmp("\x45\x41\x66\x9a\x7e\xaa\xee\x61\xe7\x08\xdc\x7c\xbc\xc5\xeb\x62", mac, 16) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: Poly1305() test 4\n", __func__);

    const char key5[] = "\x02\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0",
    msg5[] = "\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF";

    Poly1305(mac, key5, msg5, sizeof(msg5) - 1);
    if (memcmp("\x03\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0", mac, 16) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: Poly1305() test 5\n", __func__);

    const char key6[] = "\x02\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF"
    "\xFF",
    msg6[] = "\x02\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0";

    Poly1305(mac, key6, msg6, sizeof(msg6) - 1);
    if (memcmp("\x03\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0", mac, 16) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: Poly1305() test 6\n", __func__);

    const char key7[] = "\x01\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0",
    msg7[] = "\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xF0\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF"
    "\xFF\xFF\xFF\xFF\xFF\xFF\x11\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0";

    Poly1305(mac, key7, msg7, sizeof(msg7) - 1);
    if (memcmp("\x05\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0", mac, 16) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: Poly1305() test 7\n", __func__);

    const char key8[] = "\x01\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0",
    msg8[] = "\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFB\xFE\xFE\xFE\xFE\xFE\xFE\xFE\xFE\xFE"
    "\xFE\xFE\xFE\xFE\xFE\xFE\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01";

    Poly1305(mac, key8, msg8, sizeof(msg8) - 1);
    if (memcmp("\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0", mac, 16) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: Poly1305() test 8\n", __func__);

    const char key9[] = "\x02\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0",
    msg9[] = "\xFD\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF";

    Poly1305(mac, key9, msg9, sizeof(msg9) - 1);
    if (memcmp("\xFA\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF", mac, 16) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: Poly1305() test 9\n", __func__);

    const char key10[] = "\x01\0\0\0\0\0\0\0\x04\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0",
    msg10[] = "\xE3\x35\x94\xD7\x50\x5E\x43\xB9\0\0\0\0\0\0\0\0\x33\x94\xD7\x50\x5E\x43\x79\xCD\x01\0\0\0\0\0\0\0\0\0\0"
    "\0\0\0\0\0\0\0\0\0\0\0\0\0\x01\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0";

    Poly1305(mac, key10, msg10, sizeof(msg10) - 1);
    if (memcmp("\x14\0\0\0\0\0\0\0\x55\0\0\0\0\0\0\0", mac, 16) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: Poly1305() test 10\n", __func__);

    const char key11[] = "\x01\0\0\0\0\0\0\0\x04\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0",
    msg11[] = "\xE3\x35\x94\xD7\x50\x5E\x43\xB9\0\0\0\0\0\0\0\0\x33\x94\xD7\x50\x5E\x43\x79\xCD\x01\0\0\0\0\0\0\0\0\0\0"
    "\0\0\0\0\0\0\0\0\0\0\0\0\0";

    Poly1305(mac, key11, msg11, sizeof(msg11) - 1);
    if (memcmp("\x13\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0", mac, 16) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: Poly1305() test 11\n", __func__);
    
    return r;
}

int DrbgTests() {
    int r = 1;
    const char seed1[] = "\xa7\x6e\x77\xa9\x69\xab\x92\x64\x51\x81\xf0\x15\x78\x02\x52\x37\x46\xc3\x4b\xf3\x21\x86\x76"
    "\x41", nonce1[] = "\x05\x1e\xd6\xba\x39\x36\x80\x33\xad\xc9\x3d\x4e";
    uint8_t out[2048/8], K[512/8], V[512/8];

    HMACDRBG(out, 896 / 8, K, V, SHA224, 224 / 8, seed1, sizeof(seed1) - 1, nonce1, sizeof(nonce1) - 1, NULL, 0);
    HMACDRBG(out, 896 / 8, K, V, SHA224, 224 / 8, NULL, 0, NULL, 0, NULL, 0);
    if (memcmp("\x89\x25\x98\x7d\xb5\x56\x6e\x60\x52\x0f\x09\xbd\xdd\xab\x48\x82\x92\xbe\xd9\x2c\xd3\x85\xe5\xb6\xfc"
               "\x22\x3e\x19\x19\x64\x0b\x4e\x34\xe3\x45\x75\x03\x3e\x56\xc0\xa8\xf6\x08\xbe\x21\xd3\xd2\x21\xc6\x7d"
               "\x39\xab\xec\x98\xd8\x13\x12\xf3\xa2\x65\x3d\x55\xff\xbf\x44\xc3\x37\xc8\x2b\xed\x31\x4c\x21\x1b\xe2"
               "\x3e\xc3\x94\x39\x9b\xa3\x51\xc4\x68\x7d\xce\x64\x9e\x7c\x2a\x1b\xa7\xb0\xb5\xda\xb1\x25\x67\x1b\x1b"
               "\xcf\x90\x08\xda\x65\xca\xd6\x12\xd9\x5d\xdc\x92", out, 896/8) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: HMACDRBG() test 1\n", __func__);

    const char seed2[] = "\xf6\xe6\x8b\xb0\x58\x5c\x84\xd7\xb9\xf1\x75\x79\xad\x9b\x9a\x8a\xa2\x66\x6a\xbf\x4e\x8b\x44"
    "\xa3", nonce2[] = "\xa4\x33\x11\xd5\x78\x42\xef\x09\x6b\x66\xfa\x5e",
    ps2[] = "\x2f\x50\x7e\x12\xd6\x8a\x88\x0f\xa7\x0d\x6e\x5e\x54\x39\x15\x38\x17\x32\x97\x81\x4e\x06\xd7\xfd";

    HMACDRBG(out, 896 / 8, K, V, SHA224, 224 / 8, seed2, sizeof(seed2) - 1, nonce2, sizeof(nonce2) - 1,
             ps2, sizeof(ps2) - 1);
    HMACDRBG(out, 896 / 8, K, V, SHA224, 224 / 8, NULL, 0, NULL, 0, NULL, 0);
    if (memcmp("\x10\xc2\xf9\x3c\xa9\x9a\x8e\x8e\xcf\x22\x54\x00\xc8\x04\xa7\xb3\x68\xd9\x3c\xee\x3b\xfa\x6f\x44\x59"
               "\x20\xa6\xa9\x12\xd2\x68\xd6\x91\xf1\x78\x8b\xaf\x01\x3f\xb1\x68\x50\x1c\xa1\x56\xb5\x71\xba\x04\x7d"
               "\x8d\x02\x9d\xc1\xc1\xee\x07\xfc\xa5\x0a\xf6\x99\xc5\xbc\x2f\x79\x0a\xcf\x27\x80\x41\x51\x81\x41\xe7"
               "\xdc\x91\x64\xc3\xe5\x71\xb2\x65\xfb\x89\x54\x26\x1d\x92\xdb\xf2\x0a\xe0\x2f\xc2\xb7\x80\xc0\x18\xb6"
               "\xb5\x4b\x43\x20\xf2\xb8\x9d\x34\x33\x07\xfb\xb2", out, 896/8) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: HMACDRBG() test 2\n", __func__);

    const char seed3[] = "\xca\x85\x19\x11\x34\x93\x84\xbf\xfe\x89\xde\x1c\xbd\xc4\x6e\x68\x31\xe4\x4d\x34\xa4\xfb\x93"
    "\x5e\xe2\x85\xdd\x14\xb7\x1a\x74\x88",
    nonce3[] = "\x65\x9b\xa9\x6c\x60\x1d\xc6\x9f\xc9\x02\x94\x08\x05\xec\x0c\xa8";

    HMACDRBG(out, 1024 / 8, K, V, SHA256, 256 / 8, seed3, sizeof(seed3) - 1, nonce3, sizeof(nonce3) - 1, NULL, 0);
    HMACDRBG(out, 1024 / 8, K, V, SHA256, 256 / 8, NULL, 0, NULL, 0, NULL, 0);
    if (memcmp("\xe5\x28\xe9\xab\xf2\xde\xce\x54\xd4\x7c\x7e\x75\xe5\xfe\x30\x21\x49\xf8\x17\xea\x9f\xb4\xbe\xe6\xf4"
               "\x19\x96\x97\xd0\x4d\x5b\x89\xd5\x4f\xbb\x97\x8a\x15\xb5\xc4\x43\xc9\xec\x21\x03\x6d\x24\x60\xb6\xf7"
               "\x3e\xba\xd0\xdc\x2a\xba\x6e\x62\x4a\xbf\x07\x74\x5b\xc1\x07\x69\x4b\xb7\x54\x7b\xb0\x99\x5f\x70\xde"
               "\x25\xd6\xb2\x9e\x2d\x30\x11\xbb\x19\xd2\x76\x76\xc0\x71\x62\xc8\xb5\xcc\xde\x06\x68\x96\x1d\xf8\x68"
               "\x03\x48\x2c\xb3\x7e\xd6\xd5\xc0\xbb\x8d\x50\xcf\x1f\x50\xd4\x76\xaa\x04\x58\xbd\xab\xa8\x06\xf4\x8b"
               "\xe9\xdc\xb8", out, 1024/8) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: HMACDRBG() test 3\n", __func__);

    const char seed4[] = "\x5c\xac\xc6\x81\x65\xa2\xe2\xee\x20\x81\x2f\x35\xec\x73\xa7\x9d\xbf\x30\xfd\x47\x54\x76\xac"
    "\x0c\x44\xfc\x61\x74\xcd\xac\x2b\x55",
    nonce4[] = "\x6f\x88\x54\x96\xc1\xe6\x3a\xf6\x20\xbe\xcd\x9e\x71\xec\xb8\x24",
    ps4[] = "\xe7\x2d\xd8\x59\x0d\x4e\xd5\x29\x55\x15\xc3\x5e\xd6\x19\x9e\x9d\x21\x1b\x8f\x06\x9b\x30\x58\xca\xa6\x67"
    "\x0b\x96\xef\x12\x08\xd0";

    HMACDRBG(out, 1024 / 8, K, V, SHA256, 256 / 8, seed4, sizeof(seed4) - 1, nonce4, sizeof(nonce4) - 1,
             ps4, sizeof(ps4) - 1);
    HMACDRBG(out, 1024 / 8, K, V, SHA256, 256 / 8, NULL, 0, NULL, 0, NULL, 0);
    if (memcmp("\xf1\x01\x2c\xf5\x43\xf9\x45\x33\xdf\x27\xfe\xdf\xbf\x58\xe5\xb7\x9a\x3d\xc5\x17\xa9\xc4\x02\xbd\xbf"
               "\xc9\xa0\xc0\xf7\x21\xf9\xd5\x3f\xaf\x4a\xaf\xdc\x4b\x8f\x7a\x1b\x58\x0f\xca\xa5\x23\x38\xd4\xbd\x95"
               "\xf5\x89\x66\xa2\x43\xcd\xcd\x3f\x44\x6e\xd4\xbc\x54\x6d\x9f\x60\x7b\x19\x0d\xd6\x99\x54\x45\x0d\x16"
               "\xcd\x0e\x2d\x64\x37\x06\x7d\x8b\x44\xd1\x9a\x6a\xf7\xa7\xcf\xa8\x79\x4e\x5f\xbd\x72\x8e\x8f\xb2\xf2"
               "\xe8\xdb\x5d\xd4\xff\x1a\xa2\x75\xf3\x58\x86\x09\x8e\x80\xff\x84\x48\x86\x06\x0d\xa8\xb1\xe7\x13\x78"
               "\x46\xb2\x3b", out, 1024/8) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: HMACDRBG() test 4\n", __func__);

    const char seed5[] = "\xa1\xdc\x2d\xfe\xda\x4f\x3a\x11\x24\xe0\xe7\x5e\xbf\xbe\x5f\x98\xca\xc1\x10\x18\x22\x1d\xda"
    "\x3f\xdc\xf8\xf9\x12\x5d\x68\x44\x7a",
    nonce5[] = "\xba\xe5\xea\x27\x16\x65\x40\x51\x52\x68\xa4\x93\xa9\x6b\x51\x87";

    HMACDRBG(out, 1536 / 8, K, V, SHA384, 384 / 8, seed5, sizeof(seed5) - 1, nonce5, sizeof(nonce5) - 1, NULL, 0);
    HMACDRBG(out, 1536 / 8, K, V, SHA384, 384 / 8, NULL, 0, NULL, 0, NULL, 0);
    if (memcmp("\x22\x82\x93\xe5\x9b\x1e\x45\x45\xa4\xff\x9f\x23\x26\x16\xfc\x51\x08\xa1\x12\x8d\xeb\xd0\xf7\xc2\x0a"
               "\xce\x83\x7c\xa1\x05\xcb\xf2\x4c\x0d\xac\x1f\x98\x47\xda\xfd\x0d\x05\x00\x72\x1f\xfa\xd3\xc6\x84\xa9"
               "\x92\xd1\x10\xa5\x49\xa2\x64\xd1\x4a\x89\x11\xc5\x0b\xe8\xcd\x6a\x7e\x8f\xac\x78\x3a\xd9\x5b\x24\xf6"
               "\x4f\xd8\xcc\x4c\x8b\x64\x9e\xac\x2b\x15\xb3\x63\xe3\x0d\xf7\x95\x41\xa6\xb8\xa1\xca\xac\x23\x89\x49"
               "\xb4\x66\x43\x69\x4c\x85\xe1\xd5\xfc\xbc\xd9\xaa\xae\x62\x60\xac\xee\x66\x0b\x8a\x79\xbe\xa4\x8e\x07"
               "\x9c\xeb\x6a\x5e\xaf\x49\x93\xa8\x2c\x3f\x1b\x75\x8d\x7c\x53\xe3\x09\x4e\xea\xc6\x3d\xc2\x55\xbe\x6d"
               "\xcd\xcc\x2b\x51\xe5\xca\x45\xd2\xb2\x06\x84\xa5\xa8\xfa\x58\x06\xb9\x6f\x84\x61\xeb\xf5\x1b\xc5\x15"
               "\xa7\xdd\x8c\x54\x75\xc0\xe7\x0f\x2f\xd0\xfa\xf7\x86\x9a\x99\xab\x6c", out, 1536/8) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: HMACDRBG() test 5\n", __func__);

    const char seed6[] = "\x2c\xd9\x68\xba\xcd\xa2\xbc\x31\x4d\x2f\xb4\x1f\xe4\x33\x54\xfb\x76\x11\x34\xeb\x19\xee\xc6"
    "\x04\x31\xe2\xf3\x67\x55\xb8\x51\x26",
    nonce6[] = "\xe3\xde\xdf\x2a\xf9\x38\x2a\x1e\x65\x21\x43\xe9\x52\x21\x2d\x39",
    ps6[] = "\x59\xfa\x82\x35\x10\x88\x21\xac\xcb\xd3\xc1\x4e\xaf\x76\x85\x6d\x6a\x07\xf4\x33\x83\xdb\x4c\xc6\x03\x80"
    "\x40\xb1\x88\x10\xd5\x3c";

    HMACDRBG(out, 1536 / 8, K, V, SHA384, 384 / 8, seed6, sizeof(seed6) - 1, nonce6, sizeof(nonce6) - 1,
             ps6, sizeof(ps6) - 1);
    HMACDRBG(out, 1536 / 8, K, V, SHA384, 384 / 8, NULL, 0, NULL, 0, NULL, 0);
    if (memcmp("\x06\x05\x1c\xe6\xb2\xf1\xc3\x43\x78\xe0\x8c\xaf\x8f\xe8\x36\x20\x1f\xf7\xec\x2d\xb8\xfc\x5a\x25\x19"
               "\xad\xd2\x52\x4d\x90\x47\x01\x94\xb2\x47\xaf\x3a\x34\xa6\x73\x29\x8e\x57\x07\x0b\x25\x6f\x59\xfd\x09"
               "\x86\x32\x76\x8e\x2d\x55\x13\x7d\x6c\x17\xb1\xa5\x3f\xe4\x5d\x6e\xd0\xe3\x1d\x49\xe6\x48\x20\xdb\x14"
               "\x50\x14\xe2\xf0\x38\xb6\x9b\x72\x20\xe0\x42\xa8\xef\xc9\x89\x85\x70\x6a\xb9\x63\x54\x51\x23\x0a\x12"
               "\x8a\xee\x80\x1d\x4e\x37\x18\xff\x59\x51\x1c\x3f\x3f\xf1\xb2\x0f\x10\x97\x74\xa8\xdd\xc1\xfa\xdf\x41"
               "\xaf\xcc\x13\xd4\x00\x96\xd9\x97\x94\x88\x57\xa8\x94\xd0\xef\x8b\x32\x35\xc3\x21\x3b\xa8\x5c\x50\xc2"
               "\xf3\xd6\x1b\x0d\x10\x4e\xcc\xfc\xf3\x6c\x35\xfe\x5e\x49\xe7\x60\x2c\xb1\x53\x3d\xe1\x2f\x0b\xec\x61"
               "\x3a\x0e\xd9\x63\x38\x21\x95\x7e\x5b\x7c\xb3\x2f\x60\xb7\xc0\x2f\xa4", out, 1536/8) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: HMACDRBG() test 6\n", __func__);

    const char seed7[] = "\x35\x04\x9f\x38\x9a\x33\xc0\xec\xb1\x29\x32\x38\xfd\x95\x1f\x8f\xfd\x51\x7d\xfd\xe0\x60\x41"
    "\xd3\x29\x45\xb3\xe2\x69\x14\xba\x15",
    nonce7[] = "\xf7\x32\x87\x60\xbe\x61\x68\xe6\xaa\x9f\xb5\x47\x84\x98\x9a\x11";

    HMACDRBG(out, 2048 / 8, K, V, SHA512, 512 / 8, seed7, sizeof(seed7) - 1, nonce7, sizeof(nonce7) - 1, NULL, 0);
    HMACDRBG(out, 2048 / 8, K, V, SHA512, 512 / 8, NULL, 0, NULL, 0, NULL, 0);
    if (memcmp("\xe7\x64\x91\xb0\x26\x0a\xac\xfd\xed\x01\xad\x39\xfb\xf1\xa6\x6a\x88\x28\x4c\xaa\x51\x23\x36\x8a\x2a"
               "\xd9\x33\x0e\xe4\x83\x35\xe3\xc9\xc9\xba\x90\xe6\xcb\xc9\x42\x99\x62\xd6\x0c\x1a\x66\x61\xed\xcf\xaa"
               "\x31\xd9\x72\xb8\x26\x4b\x9d\x45\x62\xcf\x18\x49\x41\x28\xa0\x92\xc1\x7a\x8d\xa6\xf3\x11\x3e\x8a\x7e"
               "\xdf\xcd\x44\x27\x08\x2b\xd3\x90\x67\x5e\x96\x62\x40\x81\x44\x97\x17\x17\x30\x3d\x8d\xc3\x52\xc9\xe8"
               "\xb9\x5e\x7f\x35\xfa\x2a\xc9\xf5\x49\xb2\x92\xbc\x7c\x4b\xc7\xf0\x1e\xe0\xa5\x77\x85\x9e\xf6\xe8\x2d"
               "\x79\xef\x23\x89\x2d\x16\x7c\x14\x0d\x22\xaa\xc3\x2b\x64\xcc\xdf\xee\xe2\x73\x05\x28\xa3\x87\x63\xb2"
               "\x42\x27\xf9\x1a\xc3\xff\xe4\x7f\xb1\x15\x38\xe4\x35\x30\x7e\x77\x48\x18\x02\xb0\xf6\x13\xf3\x70\xff"
               "\xb0\xdb\xea\xb7\x74\xfe\x1e\xfb\xb1\xa8\x0d\x01\x15\x4a\x94\x59\xe7\x3a\xd3\x61\x10\x8b\xbc\x86\xb0"
               "\x91\x4f\x09\x51\x36\xcb\xe6\x34\x55\x5c\xe0\xbb\x26\x36\x18\xdc\x5c\x36\x72\x91\xce\x08\x25\x51\x89"
               "\x87\x15\x4f\xe9\xec\xb0\x52\xb3\xf0\xa2\x56\xfc\xc3\x0c\xc1\x45\x72\x53\x1c\x96\x28\x97\x36\x39\xbe"
               "\xda\x45\x6f\x2b\xdd\xf6", out, 2048/8) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: HMACDRBG() test 7\n", __func__);

    const char seed8[] = "\x73\x52\x9b\xba\x71\xa3\xd4\xb4\xfc\xf9\xa7\xed\xee\xd2\x69\xdb\xdc\x37\x48\xb9\x0d\xf6\x8c"
    "\x0d\x00\xe2\x45\xde\x54\x69\x8c\x77",
    nonce8[] = "\x22\xe2\xd6\xe2\x45\x01\x21\x2b\x6f\x05\x8e\x7c\x54\x13\x80\x07",
    ps8[] = "\xe2\xcc\x19\xe3\x15\x95\xd0\xe4\xde\x9e\x8b\xd3\xb2\x36\xde\xc2\xd4\xb0\x32\xc3\xdd\x5b\xf9\x89\x1c\x28"
    "\x4c\xd1\xba\xc6\x7b\xdb";

    HMACDRBG(out, 2048 / 8, K, V, SHA512, 512 / 8, seed8, sizeof(seed8) - 1, nonce8, sizeof(nonce8) - 1,
             ps8, sizeof(ps8) - 1);
    HMACDRBG(out, 2048 / 8, K, V, SHA512, 512 / 8, NULL, 0, NULL, 0, NULL, 0);
    if (memcmp("\x1a\x73\xd5\x8b\x73\x42\xc3\xc9\x33\xe3\xba\x15\xee\xdd\x82\x70\x98\x86\x91\xc3\x79\x4b\x45\xaa\x35"
               "\x85\x70\x39\x15\x71\x88\x1c\x0d\x9c\x42\x89\xe5\xb1\x98\xdb\x55\x34\xc3\xcb\x84\x66\xab\x48\x25\x0f"
               "\xa6\x7f\x24\xcb\x19\xb7\x03\x8e\x46\xaf\x56\x68\x7b\xab\x7e\x5d\xe3\xc8\x2f\xa7\x31\x2f\x54\xdc\x0f"
               "\x1d\xc9\x3f\x5b\x03\xfc\xaa\x60\x03\xca\xe2\x8d\x3d\x47\x07\x36\x8c\x14\x4a\x7a\xa4\x60\x91\x82\x2d"
               "\xa2\x92\xf9\x7f\x32\xca\xf9\x0a\xe3\xdd\x3e\x48\xe8\x08\xae\x12\xe6\x33\xaa\x04\x10\x10\x6e\x1a\xb5"
               "\x6b\xc0\xa0\xd8\x0f\x43\x8e\x9b\x34\x92\xe4\xa3\xbc\x88\xd7\x3a\x39\x04\xf7\xdd\x06\x0c\x48\xae\x8d"
               "\x7b\x12\xbf\x89\xa1\x95\x51\xb5\x3b\x3f\x55\xa5\x11\xd2\x82\x0e\x94\x16\x40\xc8\x45\xa8\xa0\x46\x64"
               "\x32\xc5\x85\x0c\x5b\x61\xbe\xc5\x27\x26\x02\x52\x11\x25\xad\xdf\x67\x7e\x94\x9b\x96\x78\x2b\xc0\x1a"
               "\x90\x44\x91\xdf\x08\x08\x9b\xed\x00\x4a\xd5\x6e\x12\xf8\xea\x1a\x20\x08\x83\xad\x72\xb3\xb9\xfa\xe1"
               "\x2b\x4e\xb6\x5d\x5c\x2b\xac\xb3\xce\x46\xc7\xc4\x84\x64\xc9\xc2\x91\x42\xfb\x35\xe7\xbc\x26\x7c\xe8"
               "\x52\x29\x6a\xc0\x42\xf9", out, 2048/8) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: HMACDRBG() test 8\n", __func__);
    
    return r;
}

int CypherTests() {
    int r = 1;
    const char key[] = "\0\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x10\x11\x12\x13\x14\x15\x16"
    "\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f",
    iv[] = "\0\0\0\x4a\0\0\0\0",
    msg[] = "Ladies and Gentlemen of the class of '99: If I could offer you only one tip for the future, sunscreen "
    "would be it.",
    cypher[] = "\x6e\x2e\x35\x9a\x25\x68\xf9\x80\x41\xba\x07\x28\xdd\x0d\x69\x81\xe9\x7e\x7a\xec\x1d\x43\x60\xc2\x0a"
    "\x27\xaf\xcc\xfd\x9f\xae\x0b\xf9\x1b\x65\xc5\x52\x47\x33\xab\x8f\x59\x3d\xab\xcd\x62\xb3\x57\x16\x39\xd6\x24\xe6"
    "\x51\x52\xab\x8f\x53\x0c\x35\x9f\x08\x61\xd8\x07\xca\x0d\xbf\x50\x0d\x6a\x61\x56\xa3\x8e\x08\x8a\x22\xb6\x5e\x52"
    "\xbc\x51\x4d\x16\xcc\xf8\x06\x81\x8c\xe9\x1a\xb7\x79\x37\x36\x5a\xf9\x0b\xbf\x74\xa3\x5b\xe6\xb4\x0b\x8e\xed\xf2"
    "\x78\x5e\x42\x87\x4d";
    uint8_t out[sizeof(msg) - 1];

    Chacha20(out, key, iv, msg, sizeof(msg) - 1, 1);
    if (memcmp(cypher, out, sizeof(out)) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: Chacha20() cypher test 0\n", __func__);

    Chacha20(out, key, iv, out, sizeof(out), 1);
    if (memcmp(msg, out, sizeof(out)) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: Chacha20() de-cypher test 0\n", __func__);

    const char key1[] = "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0",
    iv1[] = "\0\0\0\0\0\0\0\0",
    msg1[] = "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0"
    "\0\0\0\0\0\0\0\0\0\0\0\0",
    cypher1[] = "\x76\xb8\xe0\xad\xa0\xf1\x3d\x90\x40\x5d\x6a\xe5\x53\x86\xbd\x28\xbd\xd2\x19\xb8\xa0\x8d\xed\x1a\xa8"
    "\x36\xef\xcc\x8b\x77\x0d\xc7\xda\x41\x59\x7c\x51\x57\x48\x8d\x77\x24\xe0\x3f\xb8\xd8\x4a\x37\x6a\x43\xb8\xf4\x15"
    "\x18\xa1\x1c\xc3\x87\xb6\x69\xb2\xee\x65\x86";
    uint8_t out1[sizeof(msg1) - 1];

    Chacha20(out1, key1, iv1, msg1, sizeof(msg1) - 1, 0);
    if (memcmp(cypher1, out1, sizeof(out1)) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: Chacha20() cypher test 1\n", __func__);

    Chacha20(out1, key1, iv1, out1, sizeof(out1), 0);
    if (memcmp(msg1, out1, sizeof(out1)) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: Chacha20() de-cypher test 1\n", __func__);

    const char key2[] = "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\x01",
    iv2[] = "\0\0\0\0\0\0\0\x02",
    msg2[] = "Any submission to the IETF intended by the Contributor for publication as all or part of an IETF "
    "Internet-Draft or RFC and any statement made within the context of an IETF activity is considered an \"IETF "
    "Contribution\". Such statements include oral statements in IETF sessions, as well as written and electronic "
    "communications made at any time or place, which are addressed to",
    cypher2[] = "\xa3\xfb\xf0\x7d\xf3\xfa\x2f\xde\x4f\x37\x6c\xa2\x3e\x82\x73\x70\x41\x60\x5d\x9f\x4f\x4f\x57\xbd\x8c"
    "\xff\x2c\x1d\x4b\x79\x55\xec\x2a\x97\x94\x8b\xd3\x72\x29\x15\xc8\xf3\xd3\x37\xf7\xd3\x70\x05\x0e\x9e\x96\xd6\x47"
    "\xb7\xc3\x9f\x56\xe0\x31\xca\x5e\xb6\x25\x0d\x40\x42\xe0\x27\x85\xec\xec\xfa\x4b\x4b\xb5\xe8\xea\xd0\x44\x0e\x20"
    "\xb6\xe8\xdb\x09\xd8\x81\xa7\xc6\x13\x2f\x42\x0e\x52\x79\x50\x42\xbd\xfa\x77\x73\xd8\xa9\x05\x14\x47\xb3\x29\x1c"
    "\xe1\x41\x1c\x68\x04\x65\x55\x2a\xa6\xc4\x05\xb7\x76\x4d\x5e\x87\xbe\xa8\x5a\xd0\x0f\x84\x49\xed\x8f\x72\xd0\xd6"
    "\x62\xab\x05\x26\x91\xca\x66\x42\x4b\xc8\x6d\x2d\xf8\x0e\xa4\x1f\x43\xab\xf9\x37\xd3\x25\x9d\xc4\xb2\xd0\xdf\xb4"
    "\x8a\x6c\x91\x39\xdd\xd7\xf7\x69\x66\xe9\x28\xe6\x35\x55\x3b\xa7\x6c\x5c\x87\x9d\x7b\x35\xd4\x9e\xb2\xe6\x2b\x08"
    "\x71\xcd\xac\x63\x89\x39\xe2\x5e\x8a\x1e\x0e\xf9\xd5\x28\x0f\xa8\xca\x32\x8b\x35\x1c\x3c\x76\x59\x89\xcb\xcf\x3d"
    "\xaa\x8b\x6c\xcc\x3a\xaf\x9f\x39\x79\xc9\x2b\x37\x20\xfc\x88\xdc\x95\xed\x84\xa1\xbe\x05\x9c\x64\x99\xb9\xfd\xa2"
    "\x36\xe7\xe8\x18\xb0\x4b\x0b\xc3\x9c\x1e\x87\x6b\x19\x3b\xfe\x55\x69\x75\x3f\x88\x12\x8c\xc0\x8a\xaa\x9b\x63\xd1"
    "\xa1\x6f\x80\xef\x25\x54\xd7\x18\x9c\x41\x1f\x58\x69\xca\x52\xc5\xb8\x3f\xa3\x6f\xf2\x16\xb9\xc1\xd3\x00\x62\xbe"
    "\xbc\xfd\x2d\xc5\xbc\xe0\x91\x19\x34\xfd\xa7\x9a\x86\xf6\xe6\x98\xce\xd7\x59\xc3\xff\x9b\x64\x77\x33\x8f\x3d\xa4"
    "\xf9\xcd\x85\x14\xea\x99\x82\xcc\xaf\xb3\x41\xb2\x38\x4d\xd9\x02\xf3\xd1\xab\x7a\xc6\x1d\xd2\x9c\x6f\x21\xba\x5b"
    "\x86\x2f\x37\x30\xe3\x7c\xfd\xc4\xfd\x80\x6c\x22\xf2\x21";
    uint8_t out2[sizeof(msg2) - 1];

    Chacha20(out2, key2, iv2, msg2, sizeof(msg2) - 1, 1);
    if (memcmp(cypher2, out2, sizeof(out2)) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: Chacha20() cypher test 2\n", __func__);

    Chacha20(out2, key2, iv2, out2, sizeof(out2), 1);
    if (memcmp(msg2, out2, sizeof(out2)) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: Chacha20() de-cypher test 2\n", __func__);
    
    const char key3[] = "\x1c\x92\x40\xa5\xeb\x55\xd3\x8a\xf3\x33\x88\x86\x04\xf6\xb5\xf0\x47\x39\x17\xc1\x40\x2b\x80"
    "\x09\x9d\xca\x5c\xbc\x20\x70\x75\xc0",
    iv3[] = "\0\0\0\0\0\0\0\x02",
    msg3[] = "'Twas brillig, and the slithy toves\nDid gyre and gimble in the wabe:\nAll mimsy were the borogoves,\n"
    "And the mome raths outgrabe.",
    cypher3[] = "\x62\xe6\x34\x7f\x95\xed\x87\xa4\x5f\xfa\xe7\x42\x6f\x27\xa1\xdf\x5f\xb6\x91\x10\x04\x4c\x0d\x73\x11"
    "\x8e\xff\xa9\x5b\x01\xe5\xcf\x16\x6d\x3d\xf2\xd7\x21\xca\xf9\xb2\x1e\x5f\xb1\x4c\x61\x68\x71\xfd\x84\xc5\x4f\x9d"
    "\x65\xb2\x83\x19\x6c\x7f\xe4\xf6\x05\x53\xeb\xf3\x9c\x64\x02\xc4\x22\x34\xe3\x2a\x35\x6b\x3e\x76\x43\x12\xa6\x1a"
    "\x55\x32\x05\x57\x16\xea\xd6\x96\x25\x68\xf8\x7d\x3f\x3f\x77\x04\xc6\xa8\xd1\xbc\xd1\xbf\x4d\x50\xd6\x15\x4b\x6d"
    "\xa7\x31\xb1\x87\xb5\x8d\xfd\x72\x8a\xfa\x36\x75\x7a\x79\x7a\xc1\x88\xd1";
    uint8_t out3[sizeof(msg3) - 1];

    Chacha20(out3, key3, iv3, msg3, sizeof(msg3) - 1, 42);
    if (memcmp(cypher3, out3, sizeof(out3)) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: Chacha20() cypher test 3\n", __func__);

    Chacha20(out3, key3, iv3, out3, sizeof(out3), 42);
    if (memcmp(msg3, out3, sizeof(out3)) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: Chacha20() de-cypher test 3\n", __func__);

    return r;
}

int AuthEncryptTests() {
    int r = 1;
    const char msg1[] = "Ladies and Gentlemen of the class of '99: If I could offer you only one tip for the future, "
    "sunscreen would be it.",
    ad1[] = "\x50\x51\x52\x53\xc0\xc1\xc2\xc3\xc4\xc5\xc6\xc7",
    key1[] = "\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8a\x8b\x8c\x8d\x8e\x8f\x90\x91\x92\x93\x94\x95\x96\x97\x98\x99"
    "\x9a\x9b\x9c\x9d\x9e\x9f",
    nonce1[] = "\x07\x00\x00\x00\x40\x41\x42\x43\x44\x45\x46\x47",
    cypher1[] = "\xd3\x1a\x8d\x34\x64\x8e\x60\xdb\x7b\x86\xaf\xbc\x53\xef\x7e\xc2\xa4\xad\xed\x51\x29\x6e\x08\xfe\xa9"
    "\xe2\xb5\xa7\x36\xee\x62\xd6\x3d\xbe\xa4\x5e\x8c\xa9\x67\x12\x82\xfa\xfb\x69\xda\x92\x72\x8b\x1a\x71\xde\x0a\x9e"
    "\x06\x0b\x29\x05\xd6\xa5\xb6\x7e\xcd\x3b\x36\x92\xdd\xbd\x7f\x2d\x77\x8b\x8c\x98\x03\xae\xe3\x28\x09\x1b\x58\xfa"
    "\xb3\x24\xe4\xfa\xd6\x75\x94\x55\x85\x80\x8b\x48\x31\xd7\xbc\x3f\xf4\xde\xf0\x8e\x4b\x7a\x9d\xe5\x76\xd2\x65\x86"
    "\xce\xc6\x4b\x61\x16\x1a\xe1\x0b\x59\x4f\x09\xe2\x6a\x7e\x90\x2e\xcb\xd0\x60\x06\x91";
    uint8_t out1[16 + sizeof(msg1) - 1];
    size_t len;

    len = Chacha20Poly1305AEADEncrypt(out1, sizeof(out1), key1, nonce1, msg1, sizeof(msg1) - 1, ad1, sizeof(ad1) - 1);
    if (len != sizeof(cypher1) - 1 || memcmp(cypher1, out1, len) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: Chacha20Poly1305AEADEncrypt() cypher test 1\n", __func__);
    
    len = Chacha20Poly1305AEADDecrypt(out1, sizeof(out1), key1, nonce1, cypher1, sizeof(cypher1) - 1, ad1,
                                      sizeof(ad1) - 1);
    if (len != sizeof(msg1) - 1 || memcmp(msg1, out1, len) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: Chacha20Poly1305AEADDecrypt() cypher test 1\n", __func__);
    
    const char msg2[] = "Internet-Drafts are draft documents valid for a maximum of six months and may be updated, "
    "replaced, or obsoleted by other documents at any time. It is inappropriate to use Internet-Drafts as reference "
    "material or to cite them other than as /“work in progress./”",
    ad2[] = "\xf3\x33\x88\x86\0\0\0\0\0\0\x4e\x91",
    key2[] = "\x1c\x92\x40\xa5\xeb\x55\xd3\x8a\xf3\x33\x88\x86\x04\xf6\xb5\xf0\x47\x39\x17\xc1\x40\x2b\x80\x09\x9d\xca"
    "\x5c\xbc\x20\x70\x75\xc0",
    nonce2[] = "\0\0\0\0\x01\x02\x03\x04\x05\x06\x07\x08",
    cypher2[] = "\x64\xa0\x86\x15\x75\x86\x1a\xf4\x60\xf0\x62\xc7\x9b\xe6\x43\xbd\x5e\x80\x5c\xfd\x34\x5c\xf3\x89\xf1"
    "\x08\x67\x0a\xc7\x6c\x8c\xb2\x4c\x6c\xfc\x18\x75\x5d\x43\xee\xa0\x9e\xe9\x4e\x38\x2d\x26\xb0\xbd\xb7\xb7\x3c\x32"
    "\x1b\x01\x00\xd4\xf0\x3b\x7f\x35\x58\x94\xcf\x33\x2f\x83\x0e\x71\x0b\x97\xce\x98\xc8\xa8\x4a\xbd\x0b\x94\x81\x14"
    "\xad\x17\x6e\x00\x8d\x33\xbd\x60\xf9\x82\xb1\xff\x37\xc8\x55\x97\x97\xa0\x6e\xf4\xf0\xef\x61\xc1\x86\x32\x4e\x2b"
    "\x35\x06\x38\x36\x06\x90\x7b\x6a\x7c\x02\xb0\xf9\xf6\x15\x7b\x53\xc8\x67\xe4\xb9\x16\x6c\x76\x7b\x80\x4d\x46\xa5"
    "\x9b\x52\x16\xcd\xe7\xa4\xe9\x90\x40\xc5\xa4\x04\x33\x22\x5e\xe2\x82\xa1\xb0\xa0\x6c\x52\x3e\xaf\x45\x34\xd7\xf8"
    "\x3f\xa1\x15\x5b\x00\x47\x71\x8c\xbc\x54\x6a\x0d\x07\x2b\x04\xb3\x56\x4e\xea\x1b\x42\x22\x73\xf5\x48\x27\x1a\x0b"
    "\xb2\x31\x60\x53\xfa\x76\x99\x19\x55\xeb\xd6\x31\x59\x43\x4e\xce\xbb\x4e\x46\x6d\xae\x5a\x10\x73\xa6\x72\x76\x27"
    "\x09\x7a\x10\x49\xe6\x17\xd9\x1d\x36\x10\x94\xfa\x68\xf0\xff\x77\x98\x71\x30\x30\x5b\xea\xba\x2e\xda\x04\xdf\x99"
    "\x7b\x71\x4d\x6c\x6f\x2c\x29\xa6\xad\x5c\xb4\x02\x2b\x02\x70\x9b\xee\xad\x9d\x67\x89\x0c\xbb\x22\x39\x23\x36\xfe"
    "\xa1\x85\x1f\x38";
    uint8_t out2[sizeof(cypher2) - 1];

    len = Chacha20Poly1305AEADDecrypt(out2, sizeof(out2), key2, nonce2, cypher2, sizeof(cypher2) - 1, ad2,
                                      sizeof(ad2) - 1);
    if (len != sizeof(msg2) - 1 || memcmp(msg2, out2, len) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: Chacha20Poly1305AEADDecrypt() cypher test 2\n", __func__);

    len = Chacha20Poly1305AEADEncrypt(out2, sizeof(out2), key2, nonce2, msg2, sizeof(msg2) - 1, ad2, sizeof(ad2) - 1);
    if (len != sizeof(cypher2) - 1 || memcmp(cypher2, out2, len) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: Chacha20Poly1305AEADEncrypt() cypher test 2\n", __func__);

    return r;
}

int KeyTests() {
    int r = 1;
    BRKey key, key2;
    BRAddress addr;
    char *msg;
    UInt256 md;
    uint8_t sig[72], pubKey[65];
    size_t sigLen, pkLen;

    if (BRPrivKeyIsValid("S6c56bnXQiBjk9mqSYE7ykVQ7NzrRz"))
        r = 0, fprintf(stderr, "***FAILED*** %s: PrivKeyIsValid() test 0\n", __func__);

    // mini private key format
    if (!BRPrivKeyIsValid("Kx42x2xvyhPyvxvHs3cht4EcxAkTsqce6M6HrZH8YZYNwkrrxzvY"))
        r = 0, fprintf(stderr, "***FAILED*** %s: PrivKeyIsValid() test 1\n", __func__);

    printf("\n");
    BRKeySetPrivKey(&key, "Kx42x2xvyhPyvxvHs3cht4EcxAkTsqce6M6HrZH8YZYNwkrrxzvY");
    BRKeyAddress(&key, addr.s, sizeof(addr));
    printf("privKey:Kx42x2xvyhPyvxvHs3cht4EcxAkTsqce6M6HrZH8YZYNwkrrxzvY = %s\n", addr.s);
#if TESTNET
    if (!BRAddressEq(&addr, "ms8fwvXzrCoyatnGFRaLbepSqwGRxVJQF1"))
        r = 0, fprintf(stderr, "***FAILED*** %s: KeySetPrivKey() test 1\n", __func__);
#else
    if (!BRAddressEq(&addr, "RMWf5jvbFwD67TvBbaTLAFj9gpxjs9dV5F"))
        r = 0, fprintf(stderr, "***FAILED*** %s: KeySetPrivKey() test 1\n", __func__);
#endif


#if TESTNET
    if (!BRAddressEq(&addr, "mrhzp5mstA4Midx85EeCjuaUAAGANMFmRP"))
        r = 0, fprintf(stderr, "***FAILED*** %s: KeySetPrivKey() test 2\n", __func__);
#else
    if (!BRAddressEq(&addr, "1CC3X2gu58d6wXUWMffpuzN9JAfTUWu4Kj"))
        r = 0, fprintf(stderr, "***FAILED*** %s: KeySetPrivKey() test 2\n", __func__);
#endif

#if ! TESTNET
    // uncompressed private key
    if (!BRPrivKeyIsValid("5Kb8kLf9zgWQnogidDA76MzPL6TsZZY36hWXMssSzNydYXYB9KF"))
        r = 0, fprintf(stderr, "***FAILED*** %s: PrivKeyIsValid() test 3\n", __func__);

    BRKeySetPrivKey(&key, "5Kb8kLf9zgWQnogidDA76MzPL6TsZZY36hWXMssSzNydYXYB9KF");
    BRKeyAddress(&key, addr.s, sizeof(addr));
    printf("privKey:5Kb8kLf9zgWQnogidDA76MzPL6TsZZY36hWXMssSzNydYXYB9KF = %s\n", addr.s);
    if (!BRAddressEq(&addr, "1CC3X2gu58d6wXUWMffpuzN9JAfTUWu4Kj"))
        r = 0, fprintf(stderr, "***FAILED*** %s: KeySetPrivKey() test 3\n", __func__);

    // uncompressed private key export
    char privKey1[BRKeyPrivKey(&key, NULL, 0)];
    
    BRKeyPrivKey(&key, privKey1, sizeof(privKey1));
    printf("privKey:%s\n", privKey1);
    if (strcmp(privKey1, "5Kb8kLf9zgWQnogidDA76MzPL6TsZZY36hWXMssSzNydYXYB9KF") != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: KeyPrivKey() test 1\n", __func__);
    
    // compressed private key
    if (!BRPrivKeyIsValid("KyvGbxRUoofdw3TNydWn2Z78dBHSy2odn1d3wXWN2o3SAtccFNJL"))
        r = 0, fprintf(stderr, "***FAILED*** %s: PrivKeyIsValid() test 4\n", __func__);

    BRKeySetPrivKey(&key, "KyvGbxRUoofdw3TNydWn2Z78dBHSy2odn1d3wXWN2o3SAtccFNJL");
    BRKeyAddress(&key, addr.s, sizeof(addr));
    printf("privKey:KyvGbxRUoofdw3TNydWn2Z78dBHSy2odn1d3wXWN2o3SAtccFNJL = %s\n", addr.s);
    if (!BRAddressEq(&addr, "1JMsC6fCtYWkTjPPdDrYX3we2aBrewuEM3"))
        r = 0, fprintf(stderr, "***FAILED*** %s: KeySetPrivKey() test 4\n", __func__);
    
    // compressed private key export
    char privKey2[BRKeyPrivKey(&key, NULL, 0)];
    
    BRKeyPrivKey(&key, privKey2, sizeof(privKey2));
    printf("privKey:%s\n", privKey2);
    if (strcmp(privKey2, "KyvGbxRUoofdw3TNydWn2Z78dBHSy2odn1d3wXWN2o3SAtccFNJL") != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: KeyPrivKey() test 2\n", __func__);
#endif
    
    // signing
    BRKeySetSecret(&key, &u256_hex_decode("0000000000000000000000000000000000000000000000000000000000000001"), 1);
    msg = "Everything should be made as simple as possible, but not simpler.";
    SHA256(&md, msg, strlen(msg));
    sigLen = BRKeySign(&key, sig, sizeof(sig), md);
    
    char sig1[] = "\x30\x44\x02\x20\x33\xa6\x9c\xd2\x06\x54\x32\xa3\x0f\x3d\x1c\xe4\xeb\x0d\x59\xb8\xab\x58\xc7\x4f\x27"
    "\xc4\x1a\x7f\xdb\x56\x96\xad\x4e\x61\x08\xc9\x02\x20\x6f\x80\x79\x82\x86\x6f\x78\x5d\x3f\x64\x18\xd2\x41\x63\xdd"
    "\xae\x11\x7b\x7d\xb4\xd5\xfd\xf0\x07\x1d\xe0\x69\xfa\x54\x34\x22\x62";

    if (sigLen != sizeof(sig1) - 1 || memcmp(sig, sig1, sigLen) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: KeySign() test 1\n", __func__);

    if (!BRKeyVerify(&key, md, sig, sigLen))
        r = 0, fprintf(stderr, "***FAILED*** %s: KeyVerify() test 1\n", __func__);

    BRKeySetSecret(&key, &u256_hex_decode("fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364140"), 1);
    msg = "Equations are more important to me, because politics is for the present, but an equation is something for "
    "eternity.";
    SHA256(&md, msg, strlen(msg));
    sigLen = BRKeySign(&key, sig, sizeof(sig), md);
    
    char sig2[] = "\x30\x44\x02\x20\x54\xc4\xa3\x3c\x64\x23\xd6\x89\x37\x8f\x16\x0a\x7f\xf8\xb6\x13\x30\x44\x4a\xbb\x58"
    "\xfb\x47\x0f\x96\xea\x16\xd9\x9d\x4a\x2f\xed\x02\x20\x07\x08\x23\x04\x41\x0e\xfa\x6b\x29\x43\x11\x1b\x6a\x4e\x0a"
    "\xaa\x7b\x7d\xb5\x5a\x07\xe9\x86\x1d\x1f\xb3\xcb\x1f\x42\x10\x44\xa5";

    if (sigLen != sizeof(sig2) - 1 || memcmp(sig, sig2, sigLen) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: KeySign() test 2\n", __func__);
    
    if (!BRKeyVerify(&key, md, sig, sigLen))
        r = 0, fprintf(stderr, "***FAILED*** %s: KeyVerify() test 2\n", __func__);

    BRKeySetSecret(&key, &u256_hex_decode("fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364140"), 1);
    msg = "Not only is the Universe stranger than we think, it is stranger than we can think.";
    SHA256(&md, msg, strlen(msg));
    sigLen = BRKeySign(&key, sig, sizeof(sig), md);
    
    char sig3[] = "\x30\x45\x02\x21\x00\xff\x46\x6a\x9f\x1b\x7b\x27\x3e\x2f\x4c\x3f\xfe\x03\x2e\xb2\xe8\x14\x12\x1e\xd1"
    "\x8e\xf8\x46\x65\xd0\xf5\x15\x36\x0d\xab\x3d\xd0\x02\x20\x6f\xc9\x5f\x51\x32\xe5\xec\xfd\xc8\xe5\xe6\xe6\x16\xcc"
    "\x77\x15\x14\x55\xd4\x6e\xd4\x8f\x55\x89\xb7\xdb\x77\x71\xa3\x32\xb2\x83";
    
    if (sigLen != sizeof(sig3) - 1 || memcmp(sig, sig3, sigLen) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: KeySign() test 3\n", __func__);
    
    if (!BRKeyVerify(&key, md, sig, sigLen))
        r = 0, fprintf(stderr, "***FAILED*** %s: KeyVerify() test 3\n", __func__);

    BRKeySetSecret(&key, &u256_hex_decode("0000000000000000000000000000000000000000000000000000000000000001"), 1);
    msg = "How wonderful that we have met with a paradox. Now we have some hope of making progress.";
    SHA256(&md, msg, strlen(msg));
    sigLen = BRKeySign(&key, sig, sizeof(sig), md);
    
    char sig4[] = "\x30\x45\x02\x21\x00\xc0\xda\xfe\xc8\x25\x1f\x1d\x50\x10\x28\x9d\x21\x02\x32\x22\x0b\x03\x20\x2c\xba"
    "\x34\xec\x11\xfe\xc5\x8b\x3e\x93\xa8\x5b\x91\xd3\x02\x20\x75\xaf\xdc\x06\xb7\xd6\x32\x2a\x59\x09\x55\xbf\x26\x4e"
    "\x7a\xaa\x15\x58\x47\xf6\x14\xd8\x00\x78\xa9\x02\x92\xfe\x20\x50\x64\xd3";
    
    if (sigLen != sizeof(sig4) - 1 || memcmp(sig, sig4, sigLen) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: KeySign() test 4\n", __func__);
    
    if (!BRKeyVerify(&key, md, sig, sigLen))
        r = 0, fprintf(stderr, "***FAILED*** %s: KeyVerify() test 4\n", __func__);

    BRKeySetSecret(&key, &u256_hex_decode("69ec59eaa1f4f2e36b639716b7c30ca86d9a5375c7b38d8918bd9c0ebc80ba64"), 1);
    msg = "Computer science is no more about computers than astronomy is about telescopes.";
    SHA256(&md, msg, strlen(msg));
    sigLen = BRKeySign(&key, sig, sizeof(sig), md);
    
    char sig5[] = "\x30\x44\x02\x20\x71\x86\x36\x35\x71\xd6\x5e\x08\x4e\x7f\x02\xb0\xb7\x7c\x3e\xc4\x4f\xb1\xb2\x57\xde"
    "\xe2\x62\x74\xc3\x8c\x92\x89\x86\xfe\xa4\x5d\x02\x20\x0d\xe0\xb3\x8e\x06\x80\x7e\x46\xbd\xa1\xf1\xe2\x93\xf4\xf6"
    "\x32\x3e\x85\x4c\x86\xd5\x8a\xbd\xd0\x0c\x46\xc1\x64\x41\x08\x5d\xf6";
    
    if (sigLen != sizeof(sig5) - 1 || memcmp(sig, sig5, sigLen) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: KeySign() test 5\n", __func__);
    
    if (!BRKeyVerify(&key, md, sig, sigLen))
        r = 0, fprintf(stderr, "***FAILED*** %s: KeyVerify() test 5\n", __func__);

    BRKeySetSecret(&key, &u256_hex_decode("00000000000000000000000000007246174ab1e92e9149c6e446fe194d072637"), 1);
    msg = "...if you aren't, at any given time, scandalized by code you wrote five or even three years ago, you're not"
    " learning anywhere near enough";
    SHA256(&md, msg, strlen(msg));
    sigLen = BRKeySign(&key, sig, sizeof(sig), md);
    
    char sig6[] = "\x30\x45\x02\x21\x00\xfb\xfe\x50\x76\xa1\x58\x60\xba\x8e\xd0\x0e\x75\xe9\xbd\x22\xe0\x5d\x23\x0f\x02"
    "\xa9\x36\xb6\x53\xeb\x55\xb6\x1c\x99\xdd\xa4\x87\x02\x20\x0e\x68\x88\x0e\xbb\x00\x50\xfe\x43\x12\xb1\xb1\xeb\x08"
    "\x99\xe1\xb8\x2d\xa8\x9b\xaa\x5b\x89\x5f\x61\x26\x19\xed\xf3\x4c\xbd\x37";
    
    if (sigLen != sizeof(sig6) - 1 || memcmp(sig, sig6, sigLen) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: KeySign() test 6\n", __func__);
    
    if (!BRKeyVerify(&key, md, sig, sigLen))
        r = 0, fprintf(stderr, "***FAILED*** %s: KeyVerify() test 6\n", __func__);

    BRKeySetSecret(&key, &u256_hex_decode("000000000000000000000000000000000000000000056916d0f9b31dc9b637f3"), 1);
    msg = "The question of whether computers can think is like the question of whether submarines can swim.";
    SHA256(&md, msg, strlen(msg));
    sigLen = BRKeySign(&key, sig, sizeof(sig), md);
    
    char sig7[] = "\x30\x45\x02\x21\x00\xcd\xe1\x30\x2d\x83\xf8\xdd\x83\x5d\x89\xae\xf8\x03\xc7\x4a\x11\x9f\x56\x1f\xba"
    "\xef\x3e\xb9\x12\x9e\x45\xf3\x0d\xe8\x6a\xbb\xf9\x02\x20\x06\xce\x64\x3f\x50\x49\xee\x1f\x27\x89\x04\x67\xb7\x7a"
    "\x6a\x8e\x11\xec\x46\x61\xcc\x38\xcd\x8b\xad\xf9\x01\x15\xfb\xd0\x3c\xef";
    
    if (sigLen != sizeof(sig7) - 1 || memcmp(sig, sig7, sigLen) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: KeySign() test 7\n", __func__);
    
    if (!BRKeyVerify(&key, md, sig, sigLen))
        r = 0, fprintf(stderr, "***FAILED*** %s: KeyVerify() test 7\n", __func__);

    // compact signing
    BRKeySetSecret(&key, &u256_hex_decode("0000000000000000000000000000000000000000000000000000000000000001"), 1);
    msg = "foo";
    SHA256(&md, msg, strlen(msg));
    sigLen = BRKeyCompactSign(&key, sig, sizeof(sig), md);
    BRKeyRecoverPubKey(&key2, md, sig, sigLen);
    pkLen = BRKeyPubKey(&key2, pubKey, sizeof(pubKey));
    
    uint8_t pubKey1[BRKeyPubKey(&key, NULL, 0)];
    size_t pkLen1 = BRKeyPubKey(&key, pubKey1, sizeof(pubKey1));
    
    if (pkLen1 != pkLen || memcmp(pubKey, pubKey1, pkLen) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: KeyCompactSign() test 1\n", __func__);

    BRKeySetSecret(&key, &u256_hex_decode("0000000000000000000000000000000000000000000000000000000000000001"), 0);
    msg = "foo";
    SHA256(&md, msg, strlen(msg));
    sigLen = BRKeyCompactSign(&key, sig, sizeof(sig), md);
    BRKeyRecoverPubKey(&key2, md, sig, sigLen);
    pkLen = BRKeyPubKey(&key2, pubKey, sizeof(pubKey));
    
    uint8_t pubKey2[BRKeyPubKey(&key, NULL, 0)];
    size_t pkLen2 = BRKeyPubKey(&key, pubKey2, sizeof(pubKey2));
    
    if (pkLen2 != pkLen || memcmp(pubKey, pubKey2, pkLen) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: KeyCompactSign() test 2\n", __func__);

    // compact pubkey recovery
    pkLen = BRBase58Decode(pubKey, sizeof(pubKey), "26wZYDdvpmCrYZeUcxgqd1KquN4o6wXwLomBW5SjnwUqG");
    msg = "i am a test signed string";
    SHA256_2(&md, msg, strlen(msg));
    sigLen = BRBase58Decode(sig, sizeof(sig),
                            "3kq9e842BzkMfbPSbhKVwGZgspDSkz4YfqjdBYQPWDzqd77gPgR1zq4XG7KtAL5DZTcfFFs2iph4urNyXeBkXsEYY");
    BRKeyRecoverPubKey(&key2, md, sig, sigLen);
    uint8_t pubKey3[BRKeyPubKey(&key2, NULL, 0)];
    size_t pkLen3 = BRKeyPubKey(&key2, pubKey3, sizeof(pubKey3));

    if (pkLen3 != pkLen || memcmp(pubKey, pubKey3, pkLen) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: PubKeyRecover() test 1\n", __func__);

    pkLen = BRBase58Decode(pubKey, sizeof(pubKey), "26wZYDdvpmCrYZeUcxgqd1KquN4o6wXwLomBW5SjnwUqG");
    msg = "i am a test signed string do de dah";
    SHA256_2(&md, msg, strlen(msg));
    sigLen = BRBase58Decode(sig, sizeof(sig),
                            "3qECEYmb6x4X22sH98Aer68SdfrLwtqvb5Ncv7EqKmzbxeYYJ1hU9irP6R5PeCctCPYo5KQiWFgoJ3H5MkuX18gHu");

    BRKeyRecoverPubKey(&key2, md, sig, sigLen);
    uint8_t pubKey4[BRKeyPubKey(&key2, NULL, 0)];
    size_t pkLen4 = BRKeyPubKey(&key2, pubKey4, sizeof(pubKey4));
    
    if (pkLen4 != pkLen || memcmp(pubKey, pubKey4, pkLen) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: PubKeyRecover() test 2\n", __func__);

    pkLen = BRBase58Decode(pubKey, sizeof(pubKey), "gpRv1sNA3XURB6QEtGrx6Q18DZ5cSgUSDQKX4yYypxpW");
    msg = "i am a test signed string";
    SHA256_2(&md, msg, strlen(msg));
    sigLen = BRBase58Decode(sig, sizeof(sig),
                            "3oHQhxq5eW8dnp7DquTCbA5tECoNx7ubyiubw4kiFm7wXJF916SZVykFzb8rB1K6dEu7mLspBWbBEJyYk79jAosVR");

    BRKeyRecoverPubKey(&key2, md, sig, sigLen);
    uint8_t pubKey5[BRKeyPubKey(&key2, NULL, 0)];
    size_t pkLen5 = BRKeyPubKey(&key2, pubKey5, sizeof(pubKey5));
    
    if (pkLen5 != pkLen || memcmp(pubKey, pubKey5, pkLen) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: PubKeyRecover() test 3\n", __func__);

    printf("                                    ");
    return r;
}

int BIP38KeyTests() {
    int r = 1;
    BRKey key;
    char privKey[55], bip38Key[61];
    
    printf("\n");

    // non EC multiplied, uncompressed
    if (!BRKeySetPrivKey(&key, "5KN7MzqK5wt2TP1fQCYyHBtDrXdJuXbUzm4A9rKAteGu3Qi5CVR") ||
        !BRKeyBIP38Key(&key, bip38Key, sizeof(bip38Key), "TestingOneTwoThree") ||
        strncmp(bip38Key, "6PRVWUbkzzsbcVac2qwfssoUJAN1Xhrg6bNk8J7Nzm5H7kxEbn2Nh2ZoGg", sizeof(bip38Key)) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: KeyBIP38Key() test 1\n", __func__);
    
    if (!BRKeySetBIP38Key(&key, "6PRVWUbkzzsbcVac2qwfssoUJAN1Xhrg6bNk8J7Nzm5H7kxEbn2Nh2ZoGg", "TestingOneTwoThree") ||
        !BRKeyPrivKey(&key, privKey, sizeof(privKey)) ||
        strncmp(privKey, "5KN7MzqK5wt2TP1fQCYyHBtDrXdJuXbUzm4A9rKAteGu3Qi5CVR", sizeof(privKey)) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: KeySetBIP38Key() test 1\n", __func__);

    printf("privKey:%s\n", privKey);

    if (!BRKeySetPrivKey(&key, "5HtasZ6ofTHP6HCwTqTkLDuLQisYPah7aUnSKfC7h4hMUVw2gi5") ||
        !BRKeyBIP38Key(&key, bip38Key, sizeof(bip38Key), "Satoshi") ||
        strncmp(bip38Key, "6PRNFFkZc2NZ6dJqFfhRoFNMR9Lnyj7dYGrzdgXXVMXcxoKTePPX1dWByq", sizeof(bip38Key)) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: KeyBIP38Key() test 2\n", __func__);

    if (!BRKeySetBIP38Key(&key, "6PRNFFkZc2NZ6dJqFfhRoFNMR9Lnyj7dYGrzdgXXVMXcxoKTePPX1dWByq", "Satoshi") ||
        !BRKeyPrivKey(&key, privKey, sizeof(privKey)) ||
        strncmp(privKey, "5HtasZ6ofTHP6HCwTqTkLDuLQisYPah7aUnSKfC7h4hMUVw2gi5", sizeof(privKey)) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: KeySetBIP38Key() test 2\n", __func__);

    printf("privKey:%s\n", privKey);
    
    // non EC multiplied, compressed
    if (!BRKeySetPrivKey(&key, "L44B5gGEpqEDRS9vVPz7QT35jcBG2r3CZwSwQ4fCewXAhAhqGVpP") ||
        !BRKeyBIP38Key(&key, bip38Key, sizeof(bip38Key), "TestingOneTwoThree") ||
        strncmp(bip38Key, "6PYNKZ1EAgYgmQfmNVamxyXVWHzK5s6DGhwP4J5o44cvXdoY7sRzhtpUeo", sizeof(bip38Key)) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: KeyBIP38Key() test 3\n", __func__);

    if (!BRKeySetBIP38Key(&key, "6PYNKZ1EAgYgmQfmNVamxyXVWHzK5s6DGhwP4J5o44cvXdoY7sRzhtpUeo", "TestingOneTwoThree") ||
        !BRKeyPrivKey(&key, privKey, sizeof(privKey)) ||
        strncmp(privKey, "L44B5gGEpqEDRS9vVPz7QT35jcBG2r3CZwSwQ4fCewXAhAhqGVpP", sizeof(privKey)) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: KeySetBIP38Key() test 3\n", __func__);

    printf("privKey:%s\n", privKey);

    if (!BRKeySetPrivKey(&key, "KwYgW8gcxj1JWJXhPSu4Fqwzfhp5Yfi42mdYmMa4XqK7NJxXUSK7") ||
        !BRKeyBIP38Key(&key, bip38Key, sizeof(bip38Key), "Satoshi") ||
        strncmp(bip38Key, "6PYLtMnXvfG3oJde97zRyLYFZCYizPU5T3LwgdYJz1fRhh16bU7u6PPmY7", sizeof(bip38Key)) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: KeyBIP38Key() test 4\n", __func__);

    if (!BRKeySetBIP38Key(&key, "6PYLtMnXvfG3oJde97zRyLYFZCYizPU5T3LwgdYJz1fRhh16bU7u6PPmY7", "Satoshi") ||
        !BRKeyPrivKey(&key, privKey, sizeof(privKey)) ||
        strncmp(privKey, "KwYgW8gcxj1JWJXhPSu4Fqwzfhp5Yfi42mdYmMa4XqK7NJxXUSK7", sizeof(privKey)) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: KeySetBIP38Key() test 4\n", __func__);

    printf("privKey:%s\n", privKey);

    // EC multiplied, uncompressed, no lot/sequence number
    if (!BRKeySetBIP38Key(&key, "6PfQu77ygVyJLZjfvMLyhLMQbYnu5uguoJJ4kMCLqWwPEdfpwANVS76gTX", "TestingOneTwoThree") ||
        !BRKeyPrivKey(&key, privKey, sizeof(privKey)) ||
        strncmp(privKey, "5K4caxezwjGCGfnoPTZ8tMcJBLB7Jvyjv4xxeacadhq8nLisLR2", sizeof(privKey)) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: KeySetBIP38Key() test 5\n", __func__);

    printf("privKey:%s\n", privKey);

    if (!BRKeySetBIP38Key(&key, "6PfLGnQs6VZnrNpmVKfjotbnQuaJK4KZoPFrAjx1JMJUa1Ft8gnf5WxfKd", "Satoshi") ||
        !BRKeyPrivKey(&key, privKey, sizeof(privKey)) ||
        strncmp(privKey, "5KJ51SgxWaAYR13zd9ReMhJpwrcX47xTJh2D3fGPG9CM8vkv5sH", sizeof(privKey)) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: KeySetBIP38Key() test 6\n", __func__);

    printf("privKey:%s\n", privKey);
    
    // EC multiplied, uncompressed, with lot/sequence number
    if (!BRKeySetBIP38Key(&key, "6PgNBNNzDkKdhkT6uJntUXwwzQV8Rr2tZcbkDcuC9DZRsS6AtHts4Ypo1j", "MOLON LABE") ||
        !BRKeyPrivKey(&key, privKey, sizeof(privKey)) ||
        strncmp(privKey, "5JLdxTtcTHcfYcmJsNVy1v2PMDx432JPoYcBTVVRHpPaxUrdtf8", sizeof(privKey)) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: KeySetBIP38Key() test 7\n", __func__);

    printf("privKey:%s\n", privKey);

    if (!BRKeySetBIP38Key(&key, "6PgGWtx25kUg8QWvwuJAgorN6k9FbE25rv5dMRwu5SKMnfpfVe5mar2ngH",
                          "\u039c\u039f\u039b\u03a9\u039d \u039b\u0391\u0392\u0395") ||
        !BRKeyPrivKey(&key, privKey, sizeof(privKey)) ||
        strncmp(privKey, "5KMKKuUmAkiNbA3DazMQiLfDq47qs8MAEThm4yL8R2PhV1ov33D", sizeof(privKey)) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: KeySetBIP38Key() test 8\n", __func__);

    printf("privKey:%s\n", privKey);
    
//    // password NFC unicode normalization test
//    if (! KeySetBIP38Key(&key, "6PRW5o9FLp4gJDDVqJQKJFTpMvdsSGJxMYHtHaQBF3ooa8mwD69bapcDQn",
//                           "\u03D2\u0301\0\U00010400\U0001F4A9") ||
//        ! KeyPrivKey(&key, privKey, sizeof(privKey)) ||
//        strncmp(privKey, "5Jajm8eQ22H3pGWLEVCXyvND8dQZhiQhoLJNKjYXk9roUFTMSZ4", sizeof(privKey)) != 0)
//        r = 0, fprintf(stderr, "***FAILED*** %s: KeySetBIP38Key() test 9\n", __func__);
//
//    printf("privKey:%s\n", privKey);

    // incorrect password test
    if (BRKeySetBIP38Key(&key, "6PRW5o9FLp4gJDDVqJQKJFTpMvdsSGJxMYHtHaQBF3ooa8mwD69bapcDQn", "foobar"))
        r = 0, fprintf(stderr, "***FAILED*** %s: KeySetBIP38Key() test 10\n", __func__);

    printf("                                    ");
    return r;
}

int AddressTests() {
    int r = 1;
    UInt256 secret = u256_hex_decode("0000000000000000000000000000000000000000000000000000000000000001");
    BRKey k;
    BRAddress addr, addr2, addr3;

    BRKeySetSecret(&k, &secret, 1);
    if (!BRKeyAddress(&k, addr.s, sizeof(addr)))
        r = 0, fprintf(stderr, "***FAILED*** %s: KeyAddress()\n", __func__);

    uint8_t script[BRAddressScriptPubKey(NULL, 0, addr.s)];
    size_t scriptLen = BRAddressScriptPubKey(script, sizeof(script), addr.s);

    BRAddressFromScriptPubKey(addr2.s, sizeof(addr2), script, scriptLen);
    if (!BRAddressEq(&addr, &addr2))
        r = 0, fprintf(stderr, "***FAILED*** %s: AddressFromScriptPubKey()\n", __func__);

    // TODO: test AddressFromScriptSig()
    
    return r;
}

int BIP39MnemonicTests() {
    int r = 1;
    
    const char *s = "bless cloud wheel regular tiny venue bird web grief security dignity zoo";

    // test correct handling of bad checksum
    if (BRBIP39PhraseIsValid(BIP39WordsEn, s))
        r = 0, fprintf(stderr, "***FAILED*** %s: BIP39PhraseIsValid() test\n", __func__);

    UInt512 key = UINT512_ZERO;

//    BIP39DeriveKey(key.u8, NULL, NULL); // test invalid key
//    if (! UInt512IsZero(key)) r = 0, fprintf(stderr, "***FAILED*** %s: BIP39DeriveKey() test 0\n", __func__);

    UInt128 entropy = UINT128_ZERO;
    char phrase[BRBIP39Encode(NULL, 0, BIP39WordsEn, entropy.u8, sizeof(entropy))];
    size_t len = BRBIP39Encode(phrase, sizeof(phrase), BIP39WordsEn, entropy.u8, sizeof(entropy));
    
    if (strncmp(phrase, "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about",
                len)) r = 0, fprintf(stderr, "***FAILED*** %s: BIP39Encode() test 1\n", __func__);

    BRBIP39Decode(entropy.u8, sizeof(entropy), BIP39WordsEn, phrase);
    if (! UInt128IsZero(entropy)) r = 0, fprintf(stderr, "***FAILED*** %s: BRBIP39Decode() test 1\n", __func__);

    BRBIP39DeriveKey(key.u8, phrase, "TREZOR");
    if (! UInt512Eq(key, *(UInt512 *)"\xc5\x52\x57\xc3\x60\xc0\x7c\x72\x02\x9a\xeb\xc1\xb5\x3c\x05\xed\x03\x62\xad\xa3"
                    "\x8e\xad\x3e\x3e\x9e\xfa\x37\x08\xe5\x34\x95\x53\x1f\x09\xa6\x98\x75\x99\xd1\x82\x64\xc1\xe1\xc9"
                    "\x2f\x2c\xf1\x41\x63\x0c\x7a\x3c\x4a\xb7\xc8\x1b\x2f\x00\x16\x98\xe7\x46\x3b\x04"))
        r = 0, fprintf(stderr, "***FAILED*** %s: BIP39DeriveKey() test 1\n", __func__);

    UInt128 entropy2 = *(UInt128 *)"\x7f\x7f\x7f\x7f\x7f\x7f\x7f\x7f\x7f\x7f\x7f\x7f\x7f\x7f\x7f\x7f";
    char phrase2[BRBIP39Encode(NULL, 0, BIP39WordsEn, entropy2.u8, sizeof(entropy2))];
    size_t len2 = BRBIP39Encode(phrase2, sizeof(phrase2), BIP39WordsEn, entropy2.u8, sizeof(entropy2));
    
    if (strncmp(phrase2, "legal winner thank year wave sausage worth useful legal winner thank yellow", len2))
        r = 0, fprintf(stderr, "***FAILED*** %s: BIP39Encode() test 2\n", __func__);

    BRBIP39Decode(entropy.u8, sizeof(entropy), BIP39WordsEn, phrase2);
    if (! UInt128Eq(entropy2, entropy)) r = 0, fprintf(stderr, "***FAILED*** %s: BRBIP39Decode() test 2\n", __func__);

    BRBIP39DeriveKey(key.u8, phrase2, "TREZOR");
    if (! UInt512Eq(key, *(UInt512 *)"\x2e\x89\x05\x81\x9b\x87\x23\xfe\x2c\x1d\x16\x18\x60\xe5\xee\x18\x30\x31\x8d\xbf"
                    "\x49\xa8\x3b\xd4\x51\xcf\xb8\x44\x0c\x28\xbd\x6f\xa4\x57\xfe\x12\x96\x10\x65\x59\xa3\xc8\x09\x37"
                    "\xa1\xc1\x06\x9b\xe3\xa3\xa5\xbd\x38\x1e\xe6\x26\x0e\x8d\x97\x39\xfc\xe1\xf6\x07"))
        r = 0, fprintf(stderr, "***FAILED*** %s: BIP39DeriveKey() test 2\n", __func__);

    UInt128 entropy3 = *(UInt128 *)"\x80\x80\x80\x80\x80\x80\x80\x80\x80\x80\x80\x80\x80\x80\x80\x80";
    char phrase3[BRBIP39Encode(NULL, 0, BIP39WordsEn, entropy3.u8, sizeof(entropy3))];
    size_t len3 = BRBIP39Encode(phrase3, sizeof(phrase3), BIP39WordsEn, entropy3.u8, sizeof(entropy3));
    
    if (strncmp(phrase3, "letter advice cage absurd amount doctor acoustic avoid letter advice cage above",
                len3)) r = 0, fprintf(stderr, "***FAILED*** %s: BIP39Encode() test 3\n", __func__);

    BRBIP39Decode(entropy.u8, sizeof(entropy), BIP39WordsEn, phrase3);
    if (! UInt128Eq(entropy3, entropy)) r = 0, fprintf(stderr, "***FAILED*** %s: BRBIP39Decode() test 3\n", __func__);

    BRBIP39DeriveKey(key.u8, phrase3, "TREZOR");
    if (! UInt512Eq(key, *(UInt512 *)"\xd7\x1d\xe8\x56\xf8\x1a\x8a\xcc\x65\xe6\xfc\x85\x1a\x38\xd4\xd7\xec\x21\x6f\xd0"
                    "\x79\x6d\x0a\x68\x27\xa3\xad\x6e\xd5\x51\x1a\x30\xfa\x28\x0f\x12\xeb\x2e\x47\xed\x2a\xc0\x3b\x5c"
                    "\x46\x2a\x03\x58\xd1\x8d\x69\xfe\x4f\x98\x5e\xc8\x17\x78\xc1\xb3\x70\xb6\x52\xa8"))
        r = 0, fprintf(stderr, "***FAILED*** %s: BIP39DeriveKey() test 3\n", __func__);

    UInt128 entropy4 = *(UInt128 *)"\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff";
    char phrase4[BRBIP39Encode(NULL, 0, BIP39WordsEn, entropy4.u8, sizeof(entropy4))];
    size_t len4 = BRBIP39Encode(phrase4, sizeof(phrase4), BIP39WordsEn, entropy4.u8, sizeof(entropy4));
    
    if (strncmp(phrase4, "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong", len4))
        r = 0, fprintf(stderr, "***FAILED*** %s: BIP39Encode() test 4\n", __func__);

    BRBIP39Decode(entropy.u8, sizeof(entropy), BIP39WordsEn, phrase4);
    if (! UInt128Eq(entropy4, entropy)) r = 0, fprintf(stderr, "***FAILED*** %s: BRBIP39Decode() test 4\n", __func__);

    BRBIP39DeriveKey(key.u8, phrase4, "TREZOR");
    if (! UInt512Eq(key, *(UInt512 *)"\xac\x27\x49\x54\x80\x22\x52\x22\x07\x9d\x7b\xe1\x81\x58\x37\x51\xe8\x6f\x57\x10"
                    "\x27\xb0\x49\x7b\x5b\x5d\x11\x21\x8e\x0a\x8a\x13\x33\x25\x72\x91\x7f\x0f\x8e\x5a\x58\x96\x20\xc6"
                    "\xf1\x5b\x11\xc6\x1d\xee\x32\x76\x51\xa1\x4c\x34\xe1\x82\x31\x05\x2e\x48\xc0\x69"))
        r = 0, fprintf(stderr, "***FAILED*** %s: BIP39DeriveKey() test 4\n", __func__);

    UInt128 entropy5 = *(UInt128 *)"\x77\xc2\xb0\x07\x16\xce\xc7\x21\x38\x39\x15\x9e\x40\x4d\xb5\x0d";
    char phrase5[BRBIP39Encode(NULL, 0, BIP39WordsEn, entropy5.u8, sizeof(entropy5))];
    size_t len5 = BRBIP39Encode(phrase5, sizeof(phrase5), BIP39WordsEn, entropy5.u8, sizeof(entropy5));
    
    if (strncmp(phrase5, "jelly better achieve collect unaware mountain thought cargo oxygen act hood bridge",
                len5)) r = 0, fprintf(stderr, "***FAILED*** %s: BIP39Encode() test 5\n", __func__);

    BRBIP39Decode(entropy.u8, sizeof(entropy), BIP39WordsEn, phrase5);
    if (! UInt128Eq(entropy5, entropy)) r = 0, fprintf(stderr, "***FAILED*** %s: BRBIP39Decode() test 5\n", __func__);

    BRBIP39DeriveKey(key.u8, phrase5, "TREZOR");
    if (! UInt512Eq(key, *(UInt512 *)"\xb5\xb6\xd0\x12\x7d\xb1\xa9\xd2\x22\x6a\xf0\xc3\x34\x60\x31\xd7\x7a\xf3\x1e\x91"
                    "\x8d\xba\x64\x28\x7a\x1b\x44\xb8\xeb\xf6\x3c\xdd\x52\x67\x6f\x67\x2a\x29\x0a\xae\x50\x24\x72\xcf"
                    "\x2d\x60\x2c\x05\x1f\x3e\x6f\x18\x05\x5e\x84\xe4\xc4\x38\x97\xfc\x4e\x51\xa6\xff"))
        r = 0, fprintf(stderr, "***FAILED*** %s: BIP39DeriveKey() test 5\n", __func__);

    UInt128 entropy6 = *(UInt128 *)"\x04\x60\xef\x47\x58\x56\x04\xc5\x66\x06\x18\xdb\x2e\x6a\x7e\x7f";
    char phrase6[BRBIP39Encode(NULL, 0, BIP39WordsEn, entropy6.u8, sizeof(entropy6))];
    size_t len6 = BRBIP39Encode(phrase6, sizeof(phrase6), BIP39WordsEn, entropy6.u8, sizeof(entropy6));
    
    if (strncmp(phrase6, "afford alter spike radar gate glance object seek swamp infant panel yellow", len6))
        r = 0, fprintf(stderr, "***FAILED*** %s: BIP39Encode() test 6\n", __func__);

    BRBIP39Decode(entropy.u8, sizeof(entropy), BIP39WordsEn, phrase6);
    if (! UInt128Eq(entropy6, entropy)) r = 0, fprintf(stderr, "***FAILED*** %s: BRBIP39Decode() test 6\n", __func__);

    BRBIP39DeriveKey(key.u8, phrase6, "TREZOR");
    if (! UInt512Eq(key, *(UInt512 *)"\x65\xf9\x3a\x9f\x36\xb6\xc8\x5c\xbe\x63\x4f\xfc\x1f\x99\xf2\xb8\x2c\xbb\x10\xb3"
                    "\x1e\xdc\x7f\x08\x7b\x4f\x6c\xb9\xe9\x76\xe9\xfa\xf7\x6f\xf4\x1f\x8f\x27\xc9\x9a\xfd\xf3\x8f\x7a"
                    "\x30\x3b\xa1\x13\x6e\xe4\x8a\x4c\x1e\x7f\xcd\x3d\xba\x7a\xa8\x76\x11\x3a\x36\xe4"))
        r = 0, fprintf(stderr, "***FAILED*** %s: BIP39DeriveKey() test 6\n", __func__);

    UInt128 entropy7 = *(UInt128 *)"\xea\xeb\xab\xb2\x38\x33\x51\xfd\x31\xd7\x03\x84\x0b\x32\xe9\xe2";
    char phrase7[BRBIP39Encode(NULL, 0, BIP39WordsEn, entropy7.u8, sizeof(entropy7))];
    size_t len7 = BRBIP39Encode(phrase7, sizeof(phrase7), BIP39WordsEn, entropy7.u8, sizeof(entropy7));
    
    if (strncmp(phrase7, "turtle front uncle idea crush write shrug there lottery flower risk shell", len7))
        r = 0, fprintf(stderr, "***FAILED*** %s: BIP39Encode() test 7\n", __func__);

    BRBIP39Decode(entropy.u8, sizeof(entropy), BIP39WordsEn, phrase7);
    if (! UInt128Eq(entropy7, entropy)) r = 0, fprintf(stderr, "***FAILED*** %s: BRBIP39Decode() test 7\n", __func__);

    BRBIP39DeriveKey(key.u8, phrase7, "TREZOR");
    if (! UInt512Eq(key, *(UInt512 *)"\xbd\xfb\x76\xa0\x75\x9f\x30\x1b\x0b\x89\x9a\x1e\x39\x85\x22\x7e\x53\xb3\xf5\x1e"
                    "\x67\xe3\xf2\xa6\x53\x63\xca\xed\xf3\xe3\x2f\xde\x42\xa6\x6c\x40\x4f\x18\xd7\xb0\x58\x18\xc9\x5e"
                    "\xf3\xca\x1e\x51\x46\x64\x68\x56\xc4\x61\xc0\x73\x16\x94\x67\x51\x16\x80\x87\x6c"))
        r = 0, fprintf(stderr, "***FAILED*** %s: BIP39DeriveKey() test 7\n", __func__);

    UInt128 entropy8 = *(UInt128 *)"\x18\xab\x19\xa9\xf5\x4a\x92\x74\xf0\x3e\x52\x09\xa2\xac\x8a\x91";
    char phrase8[BRBIP39Encode(NULL, 0, BIP39WordsEn, entropy8.u8, sizeof(entropy8))];
    size_t len8 = BRBIP39Encode(phrase8, sizeof(phrase8), BIP39WordsEn, entropy8.u8, sizeof(entropy8));
    
    if (strncmp(phrase8, "board flee heavy tunnel powder denial science ski answer betray cargo cat", len8))
        r = 0, fprintf(stderr, "***FAILED*** %s: BIP39Encode() test 8\n", __func__);

    BRBIP39Decode(entropy.u8, sizeof(entropy), BIP39WordsEn, phrase8);
    if (! UInt128Eq(entropy8, entropy)) r = 0, fprintf(stderr, "***FAILED*** %s: BRBIP39Decode() test 8\n", __func__);

    BRBIP39DeriveKey(key.u8, phrase8, "TREZOR");
    if (! UInt512Eq(key, *(UInt512 *)"\x6e\xff\x1b\xb2\x15\x62\x91\x85\x09\xc7\x3c\xb9\x90\x26\x0d\xb0\x7c\x0c\xe3\x4f"
                    "\xf0\xe3\xcc\x4a\x8c\xb3\x27\x61\x29\xfb\xcb\x30\x0b\xdd\xfe\x00\x58\x31\x35\x0e\xfd\x63\x39\x09"
                    "\xf4\x76\xc4\x5c\x88\x25\x32\x76\xd9\xfd\x0d\xf6\xef\x48\x60\x9e\x8b\xb7\xdc\xa8"))
        r = 0, fprintf(stderr, "***FAILED*** %s: BIP39DeriveKey() test 8\n", __func__);

    return r;
}

int BIP32SequenceTests() {
    int r = 1;

    UInt128 seed = *(UInt128 *)"\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0A\x0B\x0C\x0D\x0E\x0F";
    BRKey key;

    printf("\n");

    BRBIP32PrivKey(&key, &seed, sizeof(seed), SEQUENCE_INTERNAL_CHAIN, 2 | 0x80000000);
    printf("000102030405060708090a0b0c0d0e0f/0H/1/2H prv = %s\n", u256_hex_encode(key.secret));
    if (! UInt256Eq(key.secret, u256_hex_decode("cbce0d719ecf7431d88e6a89fa1483e02e35092af60c042b1df2ff59fa424dca")))
        r = 0, fprintf(stderr, "***FAILED*** %s: BIP32PrivKey() test 1\n", __func__);
    
    // test for correct zero padding of private keys
    BRBIP32PrivKey(&key, &seed, sizeof(seed), SEQUENCE_EXTERNAL_CHAIN, 97);
    printf("000102030405060708090a0b0c0d0e0f/0H/0/97 prv = %s\n", u256_hex_encode(key.secret));
    if (! UInt256Eq(key.secret, u256_hex_decode("00136c1ad038f9a00871895322a487ed14f1cdc4d22ad351cfa1a0d235975dd7")))
        r = 0, fprintf(stderr, "***FAILED*** %s: BIP32PrivKey() test 2\n", __func__);
    
    BRMasterPubKey mpk = BRBIP32MasterPubKey(&seed, sizeof(seed));
    
//    printf("000102030405060708090a0b0c0d0e0f/0H fp:%08x chain:%s pubkey:%02x%s\n", be32(mpk.fingerPrint),
//           u256_hex_encode(mpk.chainCode), mpk.pubKey[0], u256_hex_encode(*(UInt256 *)&mpk.pubKey[1]));
//    if (be32(mpk.fingerPrint) != 0x3442193e ||
//        ! UInt256Eq(mpk.chainCode,
//                    u256_hex_decode("47fdacbd0f1097043b78c63c20c34ef4ed9a111d980047ad16282c7ae6236141")) ||
//        mpk.pubKey[0] != 0x03 ||
//        ! UInt256Eq(*(UInt256 *)&mpk.pubKey[1],
//                    u256_hex_decode("5a784662a4a20a65bf6aab9ae98a6c068a81c52e4b032c0fb5400c706cfccc56")))
//        r = 0, fprintf(stderr, "***FAILED*** %s: BIP32MasterPubKey() test\n", __func__);

    uint8_t pubKey[33];

    BRBIP32PubKey(pubKey, sizeof(pubKey), mpk, SEQUENCE_EXTERNAL_CHAIN, 0);
    printf("000102030405060708090a0b0c0d0e0f/0H/0/0 pub = %02x%s\n", pubKey[0],
           u256_hex_encode(*(UInt256 *)&pubKey[1]));
    if (pubKey[0] != 0x02 ||
        ! UInt256Eq(*(UInt256 *)&pubKey[1],
                    u256_hex_decode("7b6a7dd645507d775215a9035be06700e1ed8c541da9351b4bd14bd50ab61428")))
        r = 0, fprintf(stderr, "***FAILED*** %s: BIP32PubKey() test\n", __func__);

    UInt512 dk;
    BRAddress addr;

    BRBIP39DeriveKey(dk.u8, "inhale praise target steak garlic cricket paper better evil almost sadness crawl city "
                            "banner amused fringe fox insect roast aunt prefer hollow basic ladder", NULL);
    BRBIP32BitIDKey(&key, dk.u8, sizeof(dk), 0, "http://bitid.bitcoin.blue/callback");
    BRKeyAddress(&key, addr.s, sizeof(addr));
    if (strncmp(addr.s, "1J34vj4wowwPYafbeibZGht3zy3qERoUM1", sizeof(addr)) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: BIP32BitIDKey() test %s \n", addr.s, __func__);

    printf("                                    ");
    return r;
}

int TransactionTests() {
    int r = 1;
    UInt256 secret = u256_hex_decode("0000000000000000000000000000000000000000000000000000000000000001"),
            inHash = u256_hex_decode("0000000000000000000000000000000000000000000000000000000000000001");
    BRKey k[2];
    BRAddress address, addr;
    
    memset(&k[0], 0, sizeof(k[0])); // test with array of keys where first key is empty/invalid
    BRKeySetSecret(&k[1], &secret, 1);
    BRKeyAddress(&k[1], address.s, sizeof(address));

    uint8_t script[BRAddressScriptPubKey(NULL, 0, address.s)];
    size_t scriptLen = BRAddressScriptPubKey(script, sizeof(script), address.s);
    BRTransaction *tx = BRTransactionNew(1);

    BRTransactionAddInput(tx, inHash, 0, 1, script, scriptLen, NULL, 0, TXIN_SEQUENCE);
    BRTransactionAddOutput(tx, 100000000, script, scriptLen);
    BRTransactionAddOutput(tx, 4900000000, script, scriptLen);
    
    uint8_t buf[BRTransactionSerialize(tx, NULL, 0)]; // test serializing/parsing unsigned tx
    size_t len = BRTransactionSerialize(tx, buf, sizeof(buf));
    
    if (len == 0) r = 0, fprintf(stderr, "***FAILED*** %s: TransactionSerialize() test 0\n", __func__);
    BRTransactionFree(tx);
    tx = BRTransactionParse(buf, len);
    
    if (! tx || tx->inCount != 1 || tx->outCount != 2)
        r = 0, fprintf(stderr, "***FAILED*** %s: TransactionParse() test 0\n", __func__);
    if (! tx) return r;

    BRTransactionSign(tx, k, 2);
    BRAddressFromScriptSig(addr.s, sizeof(addr), tx->inputs[0].signature, tx->inputs[0].sigLen);
    if (!BRTransactionIsSigned(tx) || !BRAddressEq(&address, &addr))
        r = 0, fprintf(stderr, "***FAILED*** %s: TransactionSign() test 1\n", __func__);

    uint8_t buf2[BRTransactionSerialize(tx, NULL, 0)];
    size_t len2 = BRTransactionSerialize(tx, buf2, sizeof(buf2));

    BRTransactionFree(tx);
    tx = BRTransactionParse(buf2, len2);

    if (! tx || !BRTransactionIsSigned(tx))
        r = 0, fprintf(stderr, "***FAILED*** %s: TransactionParse() test 1\n", __func__);
    if (! tx) return r;
    
    uint8_t buf3[BRTransactionSerialize(tx, NULL, 0)];
    size_t len3 = BRTransactionSerialize(tx, buf3, sizeof(buf3));
    
    if (len2 != len3 || memcmp(buf2, buf3, len2) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: TransactionSerialize() test 1\n", __func__);
    BRTransactionFree(tx);
    
    tx = BRTransactionNew(1);
    BRTransactionAddInput(tx, inHash, 0, 1, script, scriptLen, NULL, 0, TXIN_SEQUENCE);
    BRTransactionAddInput(tx, inHash, 0, 1, script, scriptLen, NULL, 0, TXIN_SEQUENCE);
    BRTransactionAddInput(tx, inHash, 0, 1, script, scriptLen, NULL, 0, TXIN_SEQUENCE);
    BRTransactionAddInput(tx, inHash, 0, 1, script, scriptLen, NULL, 0, TXIN_SEQUENCE);
    BRTransactionAddInput(tx, inHash, 0, 1, script, scriptLen, NULL, 0, TXIN_SEQUENCE);
    BRTransactionAddInput(tx, inHash, 0, 1, script, scriptLen, NULL, 0, TXIN_SEQUENCE);
    BRTransactionAddInput(tx, inHash, 0, 1, script, scriptLen, NULL, 0, TXIN_SEQUENCE);
    BRTransactionAddInput(tx, inHash, 0, 1, script, scriptLen, NULL, 0, TXIN_SEQUENCE);
    BRTransactionAddInput(tx, inHash, 0, 1, script, scriptLen, NULL, 0, TXIN_SEQUENCE);
    BRTransactionAddInput(tx, inHash, 0, 1, script, scriptLen, NULL, 0, TXIN_SEQUENCE);
    BRTransactionAddOutput(tx, 1000000, script, scriptLen);
    BRTransactionAddOutput(tx, 1000000, script, scriptLen);
    BRTransactionAddOutput(tx, 1000000, script, scriptLen);
    BRTransactionAddOutput(tx, 1000000, script, scriptLen);
    BRTransactionAddOutput(tx, 1000000, script, scriptLen);
    BRTransactionAddOutput(tx, 1000000, script, scriptLen);
    BRTransactionAddOutput(tx, 1000000, script, scriptLen);
    BRTransactionAddOutput(tx, 1000000, script, scriptLen);
    BRTransactionAddOutput(tx, 1000000, script, scriptLen);
    BRTransactionAddOutput(tx, 1000000, script, scriptLen);
    BRTransactionSign(tx, k, 2);
    BRAddressFromScriptSig(addr.s, sizeof(addr), tx->inputs[tx->inCount - 1].signature,
                           tx->inputs[tx->inCount - 1].sigLen);
    if (!BRTransactionIsSigned(tx) || !BRAddressEq(&address, &addr))
        r = 0, fprintf(stderr, "***FAILED*** %s: TransactionSign() test 2\n", __func__);

    uint8_t buf4[BRTransactionSerialize(tx, NULL, 0)];
    size_t len4 = BRTransactionSerialize(tx, buf4, sizeof(buf4));

    BRTransactionFree(tx);
    tx = BRTransactionParse(buf4, len4);
    if (! tx || !BRTransactionIsSigned(tx))
        r = 0, fprintf(stderr, "***FAILED*** %s: TransactionParse() test 2\n", __func__);
    if (! tx) return r;

    uint8_t buf5[BRTransactionSerialize(tx, NULL, 0)];
    size_t len5 = BRTransactionSerialize(tx, buf5, sizeof(buf5));
    
    if (len4 != len5 || memcmp(buf4, buf5, len4) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: TransactionSerialize() test 2\n", __func__);
    BRTransactionFree(tx);
    
    return r;
}

static void walletBalanceChanged(void *info, uint64_t balance) {
    printf("balance changed %"PRIu64"\n", balance);
}

static void walletTxAdded(void *info, BRTransaction *tx) {
    printf("tx added: %s\n", u256_hex_encode(tx->txHash));
}

static void walletTxUpdated(void *info, const UInt256 txHashes[], size_t txCount, uint32_t blockHeight, uint32_t timestamp) {
    for (size_t i = 0; i < txCount; i++) printf("tx updated: %s\n", u256_hex_encode(txHashes[i]));
}

static void walletTxDeleted(void *info, UInt256 txHash, int notifyUser, int recommendRescan) {
    printf("tx deleted: %s\n", u256_hex_encode(txHash));
}

// TODO: test standard free transaction no change<<<<<<<<<<<<<
// TODO: test free transaction who's inputs are too new to hit min free priority
// TODO: test transaction with change below min allowable output
// TODO: test gap limit with gaps in address chain less than the limit
// TODO: test removing a transaction that other transansactions depend on
// TODO: test tx ordering for multiple tx with same block height
// TODO: port all applicable tests from bitcoinj and bitcoincore

int WalletTests() {
    int r = 1;
    BRMasterPubKey mpk = BRBIP32MasterPubKey("", 1);
    BRWallet *w = BRWalletNew(NULL, 0, mpk);
    UInt256 secret = u256_hex_decode("0000000000000000000000000000000000000000000000000000000000000001"),
            inHash = u256_hex_decode("0000000000000000000000000000000000000000000000000000000000000001");
    BRKey k;
    BRAddress addr, recvAddr = BRWalletReceiveAddress(w);
    BRTransaction *tx;
    
    printf("\n");

    BRWalletSetCallbacks(w, w, walletBalanceChanged, walletTxAdded, walletTxUpdated, walletTxDeleted);
    BRKeySetSecret(&k, &secret, 1);
    BRKeyAddress(&k, addr.s, sizeof(addr));
    
    tx = BRWalletCreateTransaction(w, 1, addr.s);
    if (tx) r = 0, fprintf(stderr, "***FAILED*** %s: WalletCreateTransaction() test 0\n", __func__);
    
    tx = BRWalletCreateTransaction(w, CORBIES, addr.s);
    if (tx) r = 0, fprintf(stderr, "***FAILED*** %s: WalletCreateTransaction() test 1\n", __func__);
    
    uint8_t inScript[BRAddressScriptPubKey(NULL, 0, addr.s)];
    size_t inScriptLen = BRAddressScriptPubKey(inScript, sizeof(inScript), addr.s);
    uint8_t outScript[BRAddressScriptPubKey(NULL, 0, recvAddr.s)];
    size_t outScriptLen = BRAddressScriptPubKey(outScript, sizeof(outScript), recvAddr.s);
    
    tx = BRTransactionNew(1);
    BRTransactionAddInput(tx, inHash, 0, 1, inScript, inScriptLen, NULL, 0, TXIN_SEQUENCE);
    BRTransactionAddOutput(tx, CORBIES, outScript, outScriptLen);
//    WalletRegisterTransaction(w, tx); // test adding unsigned tx
//    if (WalletBalance(w) != 0)
//        r = 0, fprintf(stderr, "***FAILED*** %s: WalletRegisterTransaction() test 1\n", __func__);

    if (BRWalletTransactions(w, NULL, 0) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: WalletTransactions() test 1\n", __func__);

    BRTransactionSign(tx, &k, 1);
    BRWalletRegisterTransaction(w, tx);
    if (BRWalletBalance(w) != CORBIES)
        r = 0, fprintf(stderr, "***FAILED*** %s: WalletRegisterTransaction() test 2\n", __func__);

    if (BRWalletTransactions(w, NULL, 0) != 1)
        r = 0, fprintf(stderr, "***FAILED*** %s: WalletTransactions() test 2\n", __func__);

    BRWalletRegisterTransaction(w, tx); // test adding same tx twice
    if (BRWalletBalance(w) != CORBIES)
        r = 0, fprintf(stderr, "***FAILED*** %s: WalletRegisterTransaction() test 3\n", __func__);

    tx = BRTransactionNew(1);
    BRTransactionAddInput(tx, inHash, 1, 1, inScript, inScriptLen, NULL, 0, TXIN_SEQUENCE - 1);
    BRTransactionAddOutput(tx, CORBIES, outScript, outScriptLen);
    tx->lockTime = 1000;
    BRTransactionSign(tx, &k, 1);

    if (!BRWalletTransactionIsPending(w, tx))
        r = 0, fprintf(stderr, "***FAILED*** %s: WalletTransactionIsPending() test\n", __func__);

    BRWalletRegisterTransaction(w, tx); // test adding tx with future lockTime
    if (BRWalletBalance(w) != CORBIES)
        r = 0, fprintf(stderr, "***FAILED*** %s: WalletRegisterTransaction() test 4\n", __func__);

    BRWalletUpdateTransactions(w, &tx->txHash, 1, 1000, 1);
    if (BRWalletBalance(w) != CORBIES*2)
        r = 0, fprintf(stderr, "***FAILED*** %s: WalletUpdateTransactions() test\n", __func__);

    BRWalletFree(w);
    tx = BRTransactionNew(1);
    BRTransactionAddInput(tx, inHash, 0, 1, inScript, inScriptLen, NULL, 0, TXIN_SEQUENCE);
    BRTransactionAddOutput(tx, CORBIES, outScript, outScriptLen);
    BRTransactionSign(tx, &k, 1);
    tx->timestamp = 1;
    w = BRWalletNew(&tx, 1, mpk);
    if (BRWalletBalance(w) != CORBIES)
        r = 0, fprintf(stderr, "***FAILED*** %s: WalletNew() test\n", __func__);

    if (BRWalletAllAddrs(w, NULL, 0) != SEQUENCE_GAP_LIMIT_EXTERNAL + SEQUENCE_GAP_LIMIT_INTERNAL + 1)
        r = 0, fprintf(stderr, "***FAILED*** %s: WalletAllAddrs() test\n", __func__);
    
    UInt256 hash = tx->txHash;

    tx = BRWalletCreateTransaction(w, CORBIES * 2, addr.s);
    if (tx) r = 0, fprintf(stderr, "***FAILED*** %s: WalletCreateTransaction() test 3\n", __func__);

    if (BRWalletFeeForTxAmount(w, CORBIES / 2) < 1000)
        r = 0, fprintf(stderr, "***FAILED*** %s: WalletFeeForTxAmount() test 1\n", __func__);
    
    tx = BRWalletCreateTransaction(w, CORBIES / 2, addr.s);
    if (! tx) r = 0, fprintf(stderr, "***FAILED*** %s: WalletCreateTransaction() test 4\n", __func__);

    if (tx) BRWalletSignTransaction(w, tx, "", 1);
    if (tx && !BRTransactionIsSigned(tx))
        r = 0, fprintf(stderr, "***FAILED*** %s: WalletSignTransaction() test\n", __func__);
    
    if (tx) tx->timestamp = 1, BRWalletRegisterTransaction(w, tx);
    if (tx && BRWalletBalance(w) + BRWalletFeeForTx(w, tx) != CORBIES/2)
        r = 0, fprintf(stderr, "***FAILED*** %s: WalletRegisterTransaction() test 5\n", __func__);
    
    if (BRWalletTransactions(w, NULL, 0) != 2)
        r = 0, fprintf(stderr, "***FAILED*** %s: WalletTransactions() test 3\n", __func__);
    
    if (tx && BRWalletTransactionForHash(w, tx->txHash) != tx)
        r = 0, fprintf(stderr, "***FAILED*** %s: WalletTransactionForHash() test\n", __func__);

    if (tx && !BRWalletTransactionIsValid(w, tx))
        r = 0, fprintf(stderr, "***FAILED*** %s: WalletTransactionIsValid() test\n", __func__);

    if (tx && !BRWalletTransactionIsVerified(w, tx))
        r = 0, fprintf(stderr, "***FAILED*** %s: WalletTransactionIsVerified() test\n", __func__);

    if (tx && BRWalletTransactionIsPending(w, tx))
        r = 0, fprintf(stderr, "***FAILED*** %s: WalletTransactionIsPending() test 2\n", __func__);

    BRWalletRemoveTransaction(w, hash); // removing first tx should recursively remove second, leaving none
    if (BRWalletTransactions(w, NULL, 0) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: WalletRemoveTransaction() test\n", __func__);

    if (!BRAddressEq(BRWalletReceiveAddress(w).s, recvAddr.s)) // verify used addresses are correctly tracked
        r = 0, fprintf(stderr, "***FAILED*** %s: BRWalletReceiveAddress() test\n", __func__);
    
    if (BRWalletFeeForTxAmount(w, CORBIES) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: WalletFeeForTxAmount() test 2\n", __func__);
    
    printf("                                    ");
    BRWalletFree(w);

    int64_t amt;
    
    tx = BRTransactionNew(1);
    BRTransactionAddInput(tx, inHash, 0, 1, inScript, inScriptLen, NULL, 0, TXIN_SEQUENCE);
    BRTransactionAddOutput(tx, 740000, outScript, outScriptLen);
    BRTransactionSign(tx, &k, 1);
    w = BRWalletNew(&tx, 1, mpk);
    BRWalletSetCallbacks(w, w, walletBalanceChanged, walletTxAdded, walletTxUpdated, walletTxDeleted);
    BRWalletSetFeePerKb(w, 65000);
    amt = BRWalletMaxOutputAmount(w);
    tx = BRWalletCreateTransaction(w, amt, addr.s);
    
    if (BRWalletAmountSentByTx(w, tx) - BRWalletFeeForTx(w, tx) != amt || BRWalletAmountReceivedFromTx(w, tx) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: WalletMaxOutputAmount() test 1\n", __func__);

    BRTransactionFree(tx);
    BRWalletFree(w);
    
    amt = RavencoinAmount(50000, 50000);
    if (amt != CORBIES) r = 0, fprintf(stderr, "***FAILED*** %s: RavencoinAmount() test 1\n", __func__);

    amt = RavencoinAmount(-50000, 50000);
    if (amt != -CORBIES) r = 0, fprintf(stderr, "***FAILED*** %s: RavencoinAmount() test 2\n", __func__);
    
    amt = BRLocalAmount(CORBIES, 50000);
    if (amt != 50000) r = 0, fprintf(stderr, "***FAILED*** %s: LocalAmount() test 1\n", __func__);

    amt = BRLocalAmount(-CORBIES, 50000);
    if (amt != -50000) r = 0, fprintf(stderr, "***FAILED*** %s: LocalAmount() test 2\n", __func__);
    
    return r;
}

int BloomFilterTests() {
    int r = 1;
    BRBloomFilter *f = BRBloomFilterNew(0.01, 3, 0, BLOOM_UPDATE_ALL);
    char data1[] = "\x99\x10\x8a\xd8\xed\x9b\xb6\x27\x4d\x39\x80\xba\xb5\xa8\x5c\x04\x8f\x09\x50\xc8";

    BRBloomFilterInsertData(f, (uint8_t *) data1, sizeof(data1) - 1);
    if (!BRBloomFilterContainsData(f, (uint8_t *) data1, sizeof(data1) - 1))
        r = 0, fprintf(stderr, "***FAILED*** %s: BloomFilterContainsData() test 1\n", __func__);

    // one bit difference
    char data2[] = "\x19\x10\x8a\xd8\xed\x9b\xb6\x27\x4d\x39\x80\xba\xb5\xa8\x5c\x04\x8f\x09\x50\xc8";
    
    if (BRBloomFilterContainsData(f, (uint8_t *) data2, sizeof(data2) - 1))
        r = 0, fprintf(stderr, "***FAILED*** %s: BloomFilterContainsData() test 2\n", __func__);
    
    char data3[] = "\xb5\xa2\xc7\x86\xd9\xef\x46\x58\x28\x7c\xed\x59\x14\xb3\x7a\x1b\x4a\xa3\x2e\xee";

    BRBloomFilterInsertData(f, (uint8_t *) data3, sizeof(data3) - 1);
    if (!BRBloomFilterContainsData(f, (uint8_t *) data3, sizeof(data3) - 1))
        r = 0, fprintf(stderr, "***FAILED*** %s: BloomFilterContainsData() test 3\n", __func__);

    char data4[] = "\xb9\x30\x06\x70\xb4\xc5\x36\x6e\x95\xb2\x69\x9e\x8b\x18\xbc\x75\xe5\xf7\x29\xc5";

    BRBloomFilterInsertData(f, (uint8_t *) data4, sizeof(data4) - 1);
    if (!BRBloomFilterContainsData(f, (uint8_t *) data4, sizeof(data4) - 1))
        r = 0, fprintf(stderr, "***FAILED*** %s: BloomFilterContainsData() test 4\n", __func__);

    // check against satoshi client output
    uint8_t buf1[BRBloomFilterSerialize(f, NULL, 0)];
    size_t len1 = BRBloomFilterSerialize(f, buf1, sizeof(buf1));
    char d1[] = "\x03\x61\x4e\x9b\x05\x00\x00\x00\x00\x00\x00\x00\x01";
    
    if (len1 != sizeof(d1) - 1 || memcmp(buf1, d1, len1) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: BloomFilterSerialize() test 1\n", __func__);

    BRBloomFilterFree(f);
    f = BRBloomFilterNew(0.01, 3, 2147483649, BLOOM_UPDATE_P2PUBKEY_ONLY);

    char data5[] = "\x99\x10\x8a\xd8\xed\x9b\xb6\x27\x4d\x39\x80\xba\xb5\xa8\x5c\x04\x8f\x09\x50\xc8";

    BRBloomFilterInsertData(f, (uint8_t *) data5, sizeof(data5) - 1);
    if (!BRBloomFilterContainsData(f, (uint8_t *) data5, sizeof(data5) - 1))
        r = 0, fprintf(stderr, "***FAILED*** %s: BloomFilterContainsData() test 5\n", __func__);

    // one bit difference
    char data6[] = "\x19\x10\x8a\xd8\xed\x9b\xb6\x27\x4d\x39\x80\xba\xb5\xa8\x5c\x04\x8f\x09\x50\xc8";
    
    if (BRBloomFilterContainsData(f, (uint8_t *) data6, sizeof(data6) - 1))
        r = 0, fprintf(stderr, "***FAILED*** %s: BloomFilterContainsData() test 6\n", __func__);

    char data7[] = "\xb5\xa2\xc7\x86\xd9\xef\x46\x58\x28\x7c\xed\x59\x14\xb3\x7a\x1b\x4a\xa3\x2e\xee";

    BRBloomFilterInsertData(f, (uint8_t *) data7, sizeof(data7) - 1);
    if (!BRBloomFilterContainsData(f, (uint8_t *) data7, sizeof(data7) - 1))
        r = 0, fprintf(stderr, "***FAILED*** %s: BloomFilterContainsData() test 7\n", __func__);

    char data8[] = "\xb9\x30\x06\x70\xb4\xc5\x36\x6e\x95\xb2\x69\x9e\x8b\x18\xbc\x75\xe5\xf7\x29\xc5";

    BRBloomFilterInsertData(f, (uint8_t *) data8, sizeof(data8) - 1);
    if (!BRBloomFilterContainsData(f, (uint8_t *) data8, sizeof(data8) - 1))
        r = 0, fprintf(stderr, "***FAILED*** %s: BloomFilterContainsData() test 8\n", __func__);

    // check against satoshi client output
    uint8_t buf2[BRBloomFilterSerialize(f, NULL, 0)];
    size_t len2 = BRBloomFilterSerialize(f, buf2, sizeof(buf2));
    char d2[] = "\x03\xce\x42\x99\x05\x00\x00\x00\x01\x00\x00\x80\x02";
    
    if (len2 != sizeof(d2) - 1 || memcmp(buf2, d2, len2) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: BloomFilterSerialize() test 2\n", __func__);

    BRBloomFilterFree(f);
    return r;
}

int MerkleBlockTests() {
    int r = 1;
    char block[] = // block 10001 filtered to include only transactions 0, 1, 2, and 6
    "\x01\x00\x00\x00\x06\xe5\x33\xfd\x1a\xda\x86\x39\x1f\x3f\x6c\x34\x32\x04\xb0\xd2\x78\xd4\xaa\xec\x1c"
    "\x0b\x20\xaa\x27\xba\x03\x00\x00\x00\x00\x00\x6a\xbb\xb3\xeb\x3d\x73\x3a\x9f\xe1\x89\x67\xfd\x7d\x4c\x11\x7e\x4c"
    "\xcb\xba\xc5\xbe\xc4\xd9\x10\xd9\x00\xb3\xae\x07\x93\xe7\x7f\x54\x24\x1b\x4d\x4c\x86\x04\x1b\x40\x89\xcc\x9b\x0c"
    "\x00\x00\x00\x08\x4c\x30\xb6\x3c\xfc\xdc\x2d\x35\xe3\x32\x94\x21\xb9\x80\x5e\xf0\xc6\x56\x5d\x35\x38\x1c\xa8\x57"
    "\x76\x2e\xa0\xb3\xa5\xa1\x28\xbb\xca\x50\x65\xff\x96\x17\xcb\xcb\xa4\x5e\xb2\x37\x26\xdf\x64\x98\xa9\xb9\xca\xfe"
    "\xd4\xf5\x4c\xba\xb9\xd2\x27\xb0\x03\x5d\xde\xfb\xbb\x15\xac\x1d\x57\xd0\x18\x2a\xae\xe6\x1c\x74\x74\x3a\x9c\x4f"
    "\x78\x58\x95\xe5\x63\x90\x9b\xaf\xec\x45\xc9\xa2\xb0\xff\x31\x81\xd7\x77\x06\xbe\x8b\x1d\xcc\x91\x11\x2e\xad\xa8"
    "\x6d\x42\x4e\x2d\x0a\x89\x07\xc3\x48\x8b\x6e\x44\xfd\xa5\xa7\x4a\x25\xcb\xc7\xd6\xbb\x4f\xa0\x42\x45\xf4\xac\x8a"
    "\x1a\x57\x1d\x55\x37\xea\xc2\x4a\xdc\xa1\x45\x4d\x65\xed\xa4\x46\x05\x54\x79\xaf\x6c\x6d\x4d\xd3\xc9\xab\x65\x84"
    "\x48\xc1\x0b\x69\x21\xb7\xa4\xce\x30\x21\xeb\x22\xed\x6b\xb6\xa7\xfd\xe1\xe5\xbc\xc4\xb1\xdb\x66\x15\xc6\xab\xc5"
    "\xca\x04\x21\x27\xbf\xaf\x9f\x44\xeb\xce\x29\xcb\x29\xc6\xdf\x9d\x05\xb4\x7f\x35\xb2\xed\xff\x4f\x00\x64\xb5\x78"
    "\xab\x74\x1f\xa7\x82\x76\x22\x26\x51\x20\x9f\xe1\xa2\xc4\xc0\xfa\x1c\x58\x51\x0a\xec\x8b\x09\x0d\xd1\xeb\x1f\x82"
    "\xf9\xd2\x61\xb8\x27\x3b\x52\x5b\x02\xff\x1a";
    uint8_t block2[sizeof(block) - 1];
    BRMerkleBlock *b;
    
    b = BRMerkleBlockParse((uint8_t *) block, sizeof(block) - 1);
    
    if (! UInt256Eq(b->blockHash,
        UInt256Reverse(u256_hex_decode("00000000000080b66c911bd5ba14a74260057311eaeb1982802f7010f1a9f090"))))
        r = 0, fprintf(stderr, "***FAILED*** %s: MerkleBlockParse() test\n", __func__);

    if (!BRMerkleBlockIsValid(b, (uint32_t) time(NULL)))
        r = 0, fprintf(stderr, "***FAILED*** %s: MerkleBlockParse() test\n", __func__);
    
    if (BRMerkleBlockSerialize(b, block2, sizeof(block2)) != sizeof(block2) ||
        memcmp(block, block2, sizeof(block2)) != 0)
        r = 0, fprintf(stderr, "***FAILED*** %s: MerkleBlockSerialize() test\n", __func__);
    
    if (!MerkleBlockContainsTxHash(b,
                                   u256_hex_decode("4c30b63cfcdc2d35e3329421b9805ef0c6565d35381ca857762ea0b3a5a128bb")))
        r = 0, fprintf(stderr, "***FAILED*** %s: MerkleBlockContainsTxHash() test\n", __func__);
    
    if (BRMerkleBlockTxHashes(b, NULL, 0) != 4)
        r = 0, fprintf(stderr, "***FAILED*** %s: MerkleBlockTxHashes() test 0\n", __func__);
    
    UInt256 txHashes[BRMerkleBlockTxHashes(b, NULL, 0)];

    BRMerkleBlockTxHashes(b, txHashes, 4);
    
    if (! UInt256Eq(txHashes[0],
                    u256_hex_decode("4c30b63cfcdc2d35e3329421b9805ef0c6565d35381ca857762ea0b3a5a128bb")))
        r = 0, fprintf(stderr, "***FAILED*** %s: MerkleBlockTxHashes() test 1\n", __func__);
    
    if (! UInt256Eq(txHashes[1],
                    u256_hex_decode("ca5065ff9617cbcba45eb23726df6498a9b9cafed4f54cbab9d227b0035ddefb")))
        r = 0, fprintf(stderr, "***FAILED*** %s: MerkleBlockTxHashes() test 2\n", __func__);
    
    if (! UInt256Eq(txHashes[2],
                    u256_hex_decode("bb15ac1d57d0182aaee61c74743a9c4f785895e563909bafec45c9a2b0ff3181")))
        r = 0, fprintf(stderr, "***FAILED*** %s: MerkleBlockTxHashes() test 3\n", __func__);
    
    if (! UInt256Eq(txHashes[3],
                    u256_hex_decode("c9ab658448c10b6921b7a4ce3021eb22ed6bb6a7fde1e5bcc4b1db6615c6abc5")))
        r = 0, fprintf(stderr, "***FAILED*** %s: MerkleBlockTxHashes() test 4\n", __func__);
    
    // TODO: test a block with an odd number of tree rows both at the tx level and merkle node level

    // TODO: XXX test MerkleBlockVerifyDifficulty()
    
    // TODO: test (CVE-2012-2459) vulnerability
    
    if (b) BRMerkleBlockFree(b);
    return r;
}

void PeerAcceptMessageTest(BRPeer *peer, const uint8_t *msg, size_t len, const char *type);

int PeerTests() {
    int r = 1;
    BRPeer *p = BRPeerNew(BR_CHAIN_PARAMS.magicNumber);
    const char msg[] = "my message";

    PeerAcceptMessageTest(p, (const uint8_t *) msg, sizeof(msg) - 1, "inv");
    return r;
}

int scriptValidationTest() {

    int fails = 0;

//    txid: 64603f5ab88514b5f1ceb6beb0292420b2f059bcbaff5507ae0016f1adb9909b testnet
    const char txHash[] = "\x02\x00\x00\x00\x01\x81\xed\x09\xe9\x8e\x90\xe7\xaf\x95\xd8\x00\xb4\x0f\xf0\x84\xc0\x77\xe7"
                          "\xcb\x43\x77\x19\x45\xbc\xec\xc5\xdd\x63\x4e\xe6\x33\x16\x02\x00\x00\x00\x6a\x47\x30\x44\x02"
                          "\x20\x0c\x60\x41\x11\x45\x90\x1b\x7c\x69\x8d\xa0\x93\x76\xe3\x47\xe9\xa5\x46\x4c\xb6\xd6\xec"
                          "\xfd\xef\x12\xc4\x0b\x49\x2d\xa7\x40\xb8\x02\x20\x1b\x51\xa4\xed\x9e\x89\xfa\x54\xb9\xda\x55"
                          "\xa4\x71\xb3\xcb\xe8\x68\xb4\x5d\x6f\x89\xb9\x61\x8a\xf7\xdc\x5b\xb9\x45\xc5\xec\x34\x01\x21"
                          "\x03\x49\xbe\x01\xf3\xeb\x7b\xf2\xa0\x20\x2f\x7d\xc2\x83\x0a\x88\xe1\xb8\x74\xa2\x87\xb6\x62"
                          "\xb3\x6c\x28\x4a\x84\xe9\x7c\xd5\xf8\xdd\xfe\xff\xff\xff\x04\x00\x74\x3b\xa4\x0b\x00\x00\x00"
                          "\x19\x76\xa9\x14\xdd\xa3\xd2\x17\x97\xff\x26\xcb\x8a\xe9\xa7\x69\xbd\xc6\x8c\xf4\x56\x7f\x5b"
                          "\xba\x88\xac\xcc\x50\xfa\x41\x3d\x00\x00\x00\x19\x76\xa9\x14\x06\xe8\xc3\x18\x61\xea\xad\x14"
                          "\x54\x2b\x42\x5b\x53\xb2\x14\x94\x44\x58\x0d\xe4\x88\xac\x00\x00\x00\x00\x00\x00\x00\x00\x40"
                          "\x76\xa9\x14\xa1\x25\xa3\xf3\xd7\xe0\xc9\xe4\x7b\x3a\x18\x19\xa7\x94\xd7\xe6\x0d\xd8\x9b\x4e"
                          "\x88\xac\xc0\x24\x72\x76\x6e\x6f\x1f\x54\x48\x49\x53\x49\x53\x54\x48\x49\x52\x54\x59\x43\x48"
                          "\x41\x52\x41\x43\x54\x45\x52\x41\x53\x53\x45\x54\x54\x45\x53\x54\x21\x75\x00\x00\x00\x00\x00"
                          "\x00\x00\x00\x4b\x76\xa9\x14\xa1\x25\xa3\xf3\xd7\xe0\xc9\xe4\x7b\x3a\x18\x19\xa7\x94\xd7\xe6"
                          "\x0d\xd8\x9b\x4e\x88\xac\xc0\x2f\x72\x76\x6e\x71\x1e\x54\x48\x49\x53\x49\x53\x54\x48\x49\x52"
                          "\x54\x59\x43\x48\x41\x52\x41\x43\x54\x45\x52\x41\x53\x53\x45\x54\x54\x45\x53\x54\x00\xa0\x72"
                          "\x4e\x18\x09\x00\x00\x08\x01\x00\x00\x75\x16\x6c\x00\x00";

//    THISISTHIRTYCHARACTERASSETTEST
//    "\x54\x48\x49\x53\x49\x53\x54\x48\x49\x52\x54\x59\x43\x48\x41\x52\x41\x43\x54\x45\x52\x41\x53\x53\x45\x54\x54\x45\x53\x54"

    // txid: 64603f5ab88514b5f1ceb6beb0292420b2f059bcbaff5507ae0016f1adb9909b testnet
    // This is the change Script pub key
    const uint8_t new_scriptPubKey[] = "\x76\xa9\x14\xa1\x25\xa3\xf3\xd7\xe0\xc9\xe4\x7b\x3a\x18\x19\xa7\x94\xd7\xe6\x0d"
                                   "\xd8\x9b\x4e\x88\xac\xc0\x2f\x72\x76\x6e\x71\x1e\x54\x48\x49\x53\x49\x53\x54\x48\x49"
                                   "\x52\x54\x59\x43\x48\x41\x52\x41\x43\x54\x45\x52\x41\x53\x53\x45\x54\x54\x45\x53\x54"
                                   "\x00\xa0\x72\x4e\x18\x09\x00\x00\x08\x01\x00\x00\x75";

    // \x21 is exclamation point added to the end of the asset name for ownership
    // This is the owner script pub key
    const uint8_t new_scriptPubKey2[] = "\x76\xa9\x14\xa1\x25\xa3\xf3\xd7\xe0\xc9\xe4\x7b\x3a\x18\x19\xa7\x94\xd7\xe6\x0d\xd8"
                                     "\x9b\x4e\x88\xac\xc0\x24\x72\x76\x6e\x6f\x1f\x54\x48\x49\x53\x49\x53\x54\x48\x49\x52"
                                     "\x54\x59\x43\x48\x41\x52\x41\x43\x54\x45\x52\x41\x53\x53\x45\x54\x54\x45\x53\x54\x21\x75";

    const uint8_t new_scriptPubKey3[] = "\x76\xa9\x14\x19\x67\xb9\x54\x67\xe9\xe7\x9f\xee\x9d\x71\xe3\x07\xdb\x65\xa4\x2b"
                                        "\x46\xd4\xd4\x88\xac\xc0\x37\x72\x76\x6e\x71\x05\x4e\x41\x4d\x45\x32\x00\x90\x72"
                                        "\x24\x98\x27\x00\x00\x08\x01\x01\x12\x20\x3d\xea\xf2\x50\x62\x50\x5c\x90\x65\x56"
                                        "\xfb\x6d\xaf\x96\x58\x73\xd1\x4b\x24\x26\x4b\x76\x91\x60\x28\x5b\xb7\x49\x29\x3b"
                                        "\x4e\x86\x75";

    // txid: c2d833400517ec6f66c4bdb5b65c1783f14712a90de6a19565f9f76fefae6142 testnet
    const uint8_t reissue_scriptPubKey[] = "\x76\xa9\x14\xc3\xdb\x97\xa1\x19\x17\xbd\x69\xe6\x96\xe3\x29\xf9\x88\xfc\x29"
                                           "\x21\x01\x6a\x73\x88\xac\xc0\x12\x72\x76\x6e\x72\x03\x42\x45\x4e\x00\xe8\x76"
                                           "\x48\x17\x00\x00\x00\x01\x00\x75";

    // txid: 50f7e0874d9975880d60ee56b416e49631a63d3c459d5c89162e2e1b638c2adb testnet
    const uint8_t transfer_scriptPubKey[] = "\x76\xa9\x14\xed\x73\xb6\xfd\xa7\x2c\xb9\x72\x63\xc9\x58\x8b\xd7\x20\xbd\x9a"
                                            "\x3e\x75\x61\xfe\x88\xac\xc0\x2b\x72\x76\x6e\x74\x1e\x54\x48\x49\x53\x49\x53"
                                            "\x54\x48\x49\x52\x54\x59\x43\x48\x41\x52\x41\x43\x54\x45\x52\x41\x53\x53\x45"
                                            "\x54\x54\x45\x53\x54\x00\x1c\xba\x40\x12\x09\x00\x00\x75";

    // txid: 64603f5ab88514b5f1ceb6beb0292420b2f059bcbaff5507ae0016f1adb9909b testnet
    const uint8_t owner_scriptPubKey[] = "\x76\xa9\x14\xa1\x25\xa3\xf3\xd7\xe0\xc9\xe4\x7b\x3a\x18\x19\xa7\x94\xd7\xe6\x0d"
                                         "\xd8\x9b\x4e\x88\xac\xc0\x24\x72\x76\x6e\x6f\x1f\x54\x48\x49\x53\x49\x53\x54\x48"
                                         "\x49\x52\x54\x59\x43\x48\x41\x52\x41\x43\x54\x45\x52\x41\x53\x53\x45\x54\x54\x45"
                                         "\x53\x54\x21\x75";

    // txid: 79bbb8060bbbcfb52afccd0010f172f57898a4f0762620d9e216c7efc30c1b12 testnet, New Asset Creation.
    const uint8_t scriptPubKey_withIPFS[] = "\x76\xa9\x14\x10\xa9\x7c\xbb\xb2\xfc\x28\x4c\x38\xb5\x3b\xc4\xa5\xec\x3d\x24"
                                            "\x55\x6f\xa7\xf7\x88\xac\xc0\x3a\x72\x76\x6e\x71\x07\x4f\x4b\x4b\x4b\x4b\x4b"
                                            "\x4b\x00\x10\xa5\xd4\xe8\x00\x00\x00\x08\x01\x01\x22\x12\x20\x4f\x0b\x01\x8a"
                                            "\x3b\x00\x3b\x7c\x99\xf9\x74\x27\xf4\x10\xca\xfe\x57\x07\xba\x18\xd2\x8b\x13"
                                            "\xcd\x8b\xfa\x59\xe0\x8e\x11\x03\x80\x75";

    printf("ScriptValidationTest IsScriptAsset... ");
    printf("%s\n", IsScriptAsset(new_scriptPubKey, sizeof(new_scriptPubKey)) ? "***Success: is Asset***" : "***FAIL***");
    printf("ScriptValidationTest IsScriptNewAsset... ");
    printf("%s\n", IsScriptNewAsset(new_scriptPubKey, sizeof(new_scriptPubKey)) ? "***Success: is NewAsset***" : "***FAIL***");
    printf("ScriptValidationTest IsScriptOwnerAsset... ");
    printf("%s\n", IsScriptOwnerAsset(owner_scriptPubKey, sizeof(owner_scriptPubKey)) ? "***Success: is OwnerAsset***" : "***FAIL***");
    printf("ScriptValidationTest IsScriptReissueAsset... ");
    printf("%s\n", IsScriptReissueAsset(reissue_scriptPubKey, sizeof(reissue_scriptPubKey)) ? "***Success: is ReissueAsset***" : "***FAIL***");
    printf("ScriptValidationTest IsScriptTransferAsset... ");
    printf("%s\n", IsScriptTransferAsset(transfer_scriptPubKey, sizeof(transfer_scriptPubKey)) ? "***Success: is TransferAsset***" : "***FAIL***");

    BRAsset *asset = NewAsset();
    printf("\nGetAssetDataTest IsScriptNewAsset... ");
    GetAssetData(new_scriptPubKey3, sizeof(new_scriptPubKey3), asset);
    printf(" Asset type: %s", GetAssetType(asset->type));

    printf("\nGetAssetDataTest IsScriptNewAsset... ");
    GetAssetData(scriptPubKey_withIPFS, sizeof(scriptPubKey_withIPFS), asset);
    printf(" Asset type: %s", GetAssetType(asset->type));

    printf("\nGetAssetDataTest IsScriptReissueAsset... ");
    GetAssetData(reissue_scriptPubKey, sizeof(reissue_scriptPubKey), asset);
    printf(" Asset type: %s", GetAssetType(asset->type));

    printf("\nGetAssetDataTest IsScriptTransferAsset... ");
    GetAssetData(transfer_scriptPubKey, sizeof(transfer_scriptPubKey), asset);
    printf(" Asset type: %s", GetAssetType(asset->type));

    return fails;
}

int scriptCreationTest() {

    int r = 0;

    BRMasterPubKey mpk = BRBIP32MasterPubKey("", 1);
    BRWallet *w = BRWalletNew(NULL, 0, mpk);
    BRAddress addr = BRWalletReceiveAddress(w);
    uint8_t outScript[BRAddressScriptPubKey(NULL, 0, addr.s)];
    size_t outScriptLen = BRAddressScriptPubKey(outScript, sizeof(outScript), addr.s);

    uint8_t name_helper[6] = "ROSHIIX";
    BRAsset asset = { .type = TRANSFER, .amount = 109999, .name = name_helper, .nameLen = sizeof(name_helper), .unit = 0,
                      .reissuable = 0, .hasIPFS = 0, .IPFSHash = NULL };

    //TODO fix this shit!
//    size_t off = ConstructTransferAssetScript(outScript, /*outScriptLen*/ 100, &asset);

    return r;
}

int BIP44KeyTests() {
    int r = 1;
    BRKey key;
    BRAddress addr;

    if (!BRPrivKeyIsValid("KzfMncfYAQniviEdv4AiRB5VGxtNHB1urnncmwbSUrNWiw91Y8Yd"))
        r = 0, fprintf(stderr, "***FAILED*** %s: PrivKeyIsValid() test 0\n", __func__);

    if (BRPrivKeyIsValid("S6c56bnXQiBjk9mqSYE7ykVQ7NzrRz"))
        r = 0, fprintf(stderr, "***FAILED*** %s: PrivKeyIsValid() test 1\n", __func__);

    printf("\n");

    BRKeySetPrivKey(&key, "KzfMncfYAQniviEdv4AiRB5VGxtNHB1urnncmwbSUrNWiw91Y8Yd");
    BRKeyAddress(&key, addr.s, sizeof(addr));
    printf("privKey:KzfMncfYAQniviEdv4AiRB5VGxtNHB1urnncmwbSUrNWiw91Y8Yd = %s\n", addr.s);

    // m/44'/0'/0'/0/0
    if (!BRAddressEq(&addr, "RU6G3nfEmA6UDk6bRnBqG6qRP7g63AL2AB"))
        r = 0, fprintf(stderr, "***FAILED*** %s: KeySetPrivKey() test 2\n", __func__);

    // m/44'/0'/0'/0/1
    if (BRAddressEq(&addr, "RE4La4DzVwKLy4wCCT6QKS7SfyBYDtAqiw"))
        r = 0, fprintf(stderr, "***FAILED*** %s: KeySetPrivKey() test 3\n", __func__);

    printf("                                    ");
    return r;
}

int IpfsDecodingHash() {

    int r = 0;

    char *p;
    p = "QmTfCejgo2wTwqnDJs8Lu1pCNeCrCDuE4GAwkna93zdd7d";

    uint8_t buf1[BRBase58Decode(NULL, 0, p)];
    size_t len1 = BRBase58Decode(buf1, sizeof(buf1), p);

    if (len1 != 0) r = 0, fprintf(stderr, "***FAILED*** %s: Base58Decode() test 1\n", __func__);


    char *s;
    s = "\x12\x20\x4f\x0b\x01\x8a\x3b\x00\x3b\x7c\x99\xf9\x74\x27\xf4\x10\xca"
               "\xfe\x57\x07\xba\x18\xd2\x8b\x13\xcd\x8b\xfa\x59\xe0\x8e\x11\x03\x80";

    char s5[BRBase58CheckEncode(NULL, 0, (uint8_t *) s, 21)];
    size_t l5 = BRBase58CheckEncode(s5, sizeof(s5), (uint8_t *) s, 21);
    uint8_t b5[BRBase58CheckDecode(NULL, 0, s5)];

    BRBase58CheckDecode(b5, sizeof(b5), s5);
    if (memcmp(s, b5, l5) != 0)
        fprintf(stderr, "***FAILED*** %s: Base58CheckDecode() test\n", __func__);

    return r;
}



int RunTests() {
    int fail = 0;
    
    printf("IntsTests...                      ");
    printf("%s\n", (IntsTests()) ? "success" : (fail++, "***FAIL***"));
    printf("ArrayTests...                     ");
    printf("%s\n", (ArrayTests()) ? "success" : (fail++, "***FAIL***"));
    printf("SetTests...                       ");
    printf("%s\n", (SetTests()) ? "success" : (fail++, "***FAIL***"));
    printf("Base58Tests...                    ");
    printf("%s\n", (Base58Tests()) ? "success" : (fail++, "***FAIL***"));
    printf("HashTests...                      ");
    printf("%s\n", (HashTests()) ? "success" : (fail++, "***FAIL***"));
    printf("MacTests...                       ");
    printf("%s\n", (MacTests()) ? "success" : (fail++, "***FAIL***"));
    printf("DrbgTests...                      ");
    printf("%s\n", (DrbgTests()) ? "success" : (fail++, "***FAIL***"));
    printf("CypherTests...                    ");
    printf("%s\n", (CypherTests()) ? "success" : (fail++, "***FAIL***"));
    printf("AuthEncryptTests...               ");
    printf("%s\n", (AuthEncryptTests()) ? "success" : (fail++, "***FAIL***"));
    printf("KeyTests...                       ");
    printf("%s\n", (KeyTests()) ? "success" : (fail++, "***FAIL***"));
    printf("BIP38KeyTests...                  ");
#if SKIP_BIP38
    printf("SKIPPED\n");
#else
    printf("%s\n", (BIP38KeyTests()) ? "success" : (fail++, "***FAIL***"));
#endif
    printf("AddressTests...                   ");
    printf("%s\n", (AddressTests()) ? "success" : (fail++, "***FAIL***"));
    printf("BIP39MnemonicTests...             ");
    printf("%s\n", (BIP39MnemonicTests()) ? "success" : (fail++, "***FAIL***"));
    printf("BIP32SequenceTests...             ");
    printf("%s\n", (BIP32SequenceTests()) ? "success" : (fail++, "***FAIL***"));
    printf("TransactionTests...               ");
    printf("%s\n", (TransactionTests()) ? "success" : (fail++, "***FAIL***"));
    printf("WalletTests...                    ");
    printf("%s\n", (WalletTests()) ? "success" : (fail++, "***FAIL***"));
    printf("BloomFilterTests...               ");
    printf("%s\n", (BloomFilterTests()) ? "success" : (fail++, "***FAIL***"));
    printf("MerkleBlockTests...               ");
    printf("%s\n", (MerkleBlockTests()) ? "success" : (fail++, "***FAIL***"));
    printf("\n");
    printf("%s\n", (scriptValidationTest()) ? "success" : (fail++, "***FAIL***"));
    printf("\n");
    printf("%s\n", (scriptCreationTest()) ? "success" : (fail++, "***FAIL***"));
    printf("\n");
//    printf("%s\n", (IpfsDecodingHash()) ? "success" : (fail++, "***FAIL***"));
//    printf("\n");

    if (fail > 0) printf("%d TEST FUNCTION(S) ***FAILED***\n", fail);
    else printf("ALL TESTS PASSED\n");
    
    return (fail == 0);
}

#ifndef BITCOIN_TEST_NO_MAIN
void syncStarted(void *info) {
    printf("sync started\n");
}

void syncStopped(void *info, int error) {
    printf("sync stopped: %s\n", strerror(error));
}

void txStatusUpdate(void *info) {
    printf("transaction status updated\n");
}

int main(int argc, const char *argv[])  {

//    int r = RunTests();
    int r = 0;

    int err = 0;
    UInt512 seed = UINT512_ZERO;
    BRMasterPubKey mpk = MASTER_PUBKEY_NONE;
    BRWallet *wallet;
    BRPeerManager *manager;

    BRBIP39DeriveKey(seed.u8, "throw detail divorce logic typical monkey armor infant purchase ocean lecture novel",
                     NULL);
    mpk = BRBIP32MasterPubKey(&seed, sizeof(seed));
//    mpk = BIP44MasterPubKey(&seed, sizeof(seed), 0 | BIP32_HARD, 0 | BIP32_HARD);
//    mpk = BIP44MasterPubKey(&seed, sizeof(seed), 0, 175);

    wallet = BRWalletNew(NULL, 0, mpk);
    BRWalletSetCallbacks(wallet, wallet, walletBalanceChanged, walletTxAdded, walletTxUpdated, walletTxDeleted);
    printf("wallet created with first receive address: %s\n", BRWalletReceiveAddress(wallet).s);

    manager = BRPeerManagerNew(&BR_CHAIN_PARAMS, wallet, BIP39_CREATION_TIME, NULL, 0, NULL, 0);
    BRPeerManagerSetCallbacks(manager, manager, syncStarted, syncStopped, txStatusUpdate, NULL, NULL, NULL, NULL);

    BRPeerManagerConnect(manager);
    while (err == 0 && BRPeerManagerPeerCount(manager) > 0) err = sleep(1);
    if (err != 0) printf("sleep got a signal\n");

    BRPeerManagerDisconnect(manager);
    BRPeerManagerFree(manager);
    BRWalletFree(wallet);
    sleep(5);

    return (r) ? 0 : 1;
}

#endif
