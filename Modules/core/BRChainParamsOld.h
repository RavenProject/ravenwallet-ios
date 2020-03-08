//
//  ChainParams.h
//
//  Created by Aaron Voisine on 1/10/18.
//  Copyright (c) 2019 breadwallet LLC
//  Update by Roshii on 4/1/18.
//  Copyright (c) 2018 ravencoin core team
//


#ifndef BRChainParams_h
#define BRChainParams_h

#include "BRPeerManager.h"
#include <assert.h>

static const int64_t COIN = 100000000;

// Burn Amounts
static const uint64_t IssueAssetBurnAmount = 500 * COIN;
static const uint64_t ReissueAssetBurnAmount = 100 * COIN;
static const uint64_t IssueSubAssetBurnAmount = 100 * COIN;
static const uint64_t IssueUniqueAssetBurnAmount = 5 * COIN;


typedef struct {
    uint32_t height;
    UInt256 hash;
    uint32_t timestamp;
    uint32_t target;
} CheckPoint;

static const char *MainNetDNSSeeds[] = {
        "seed-raven.ravencoin.com", "seed-raven.ravencoin.org.", "seed-raven.bitactivate.com.", NULL
};

static const char *TestNetDNSSeeds[] = {
        "127.0.0.1", "3.214.65.115", "3.220.176.189", "107.23.17.170", NULL
//        "seed-testnet-raven.ravencoin.com", "seed-testnet-raven.ravencoin.org.", "seed-testnet-raven.bitactivate.com.",NULL
};

static const char *RegTestDNSSeeds[] = {
        "127.0.0.1", NULL
};

// blockchain checkpoints - these are also used as starting points for partial chain downloads, so they must be at
// difficulty transition boundaries in order to verify the block difficulty at the immediately following transition
static const CheckPoint MainNetCheckpoints[] = {
        {      0, u256_hex_decode("0000006b444bc2f2ffe627be9d9e7e7a0730000870ef6eb6da46c8eae389df90"), 1514999494, 0x1e00ffff },
        {   2016, u256_hex_decode("0000003e7c74d91113e9f8b203673bc77474112a3811f4fc25f577e5d4228035"), 1515022405, 0x1d3fffc0 },
        {   4032, u256_hex_decode("0000000e7029625c8ceb5e42f2a84c15e1c4326ea91c3369d49d64655560c9c3"), 1515034394, 0x1d0ffff0 },
        {  20160, u256_hex_decode("00000000146e792b63f2a18db16f32d2afc9f0b332839eb502cb9c9a8f1bc033"), 1515665731, 0x1c53dd22 },
        {  40320, u256_hex_decode("00000000085e7d049938d66a08d151891c0087a6b3d78d400f1ca0944991ffde"), 1516664426, 0x1c0a0075 },
        {  60480, u256_hex_decode("0000000000683f2d1bb44dd545eb4fea28c0f51eb513ea32b4e813f185a1f6ab"), 1517740553, 0x1c01b501 },
        {  80640, u256_hex_decode("00000000000735f443ea62266bb7799a760c8336da0c7b7a987c895e83c9ea73"), 1518771490, 0x1b43e935 },
        { 100800, u256_hex_decode("00000000000bf40aa747ca97da99e1e6878efff28f709d1969f0a2d95dda1414"), 1519826997, 0x1b0fabc1 },
        { 120960, u256_hex_decode("000000000000203f20f1f2fc50546b4f3d0693a53e781b499884661e6762eb05"), 1520934202, 0x1b060077 },
        { 141120, u256_hex_decode("00000000000367e05ceca64ebf6b72a87510bdcb6252ff071b7f4971661e9acf"), 1522092453, 0x1b03cc83 },
        { 161280, u256_hex_decode("0000000000024a1d42423dd3e1cde28c78fe34857db63f08d21f11fc13e594c3"), 1523259269, 0x1b028d7d },
        { 181440, u256_hex_decode("000000000000d202bdeb7993a1de022f82231fdce97e22f054626291eb79f4cb"), 1524510281, 0x1b038153 },
        { 201600, u256_hex_decode("000000000001a16d8b86e19ac87df227458d29b5fb70dfef7e5b0203df085617"), 1525709579, 0x1b0306f4 },
        { 221760, u256_hex_decode("000000000002b4a1ef811a31e58489794dba047e4e78e18d5611c94d7fc60174"), 1526920402, 0x1b02ff59 },
        { 241920, u256_hex_decode("000000000001e64a356c6665afcb2871bc7f18e5609663b5b54a82fa204ee9b1"), 1528150015, 0x1b037c77 },
        { 262080, u256_hex_decode("0000000000014a11d3aacdc5ee21e69fd8aefe10f0e617508dfb3e78d1ca82be"), 1529359488, 0x1b037276 },
        { 282240, u256_hex_decode("00000000000182bbfada9dd47003bed09880b7a1025edcb605f9c048f2bad49e"), 1530594496, 0x1b042cda },
        { 302400, u256_hex_decode("000000000001e9862c28d3359f2b568b03811988f2db2f91ab8b412acac891ed"), 1531808927, 0x1b0422c8 },
        { 322560, u256_hex_decode("000000000001d50eaf12266c6ecaefec473fecd9daa7993db05b89e6ab381388"), 1533209846, 0x1b04cb9e },
        { 338778, u256_hex_decode("000000000003198106731cb28fc24e9ace995a37709b026b25dfa905aea54517"), 1535599185, 0x1b07cf3a },
        { 341086, u256_hex_decode("000000000001c72e3613de62be33974f69993bf16f10d117d14321afa4259a0e"), 1535734416, 0x1b0203f4 }
};

static const CheckPoint TestNetCheckpoints[] = {
        {0,      u256_hex_decode("000000ecfc5e6324a079542221d00e10362bdc894d56500c414060eea8a3ad5a"), 1533751200, 0x1e00ffff },
        {2016,  u256_hex_decode("00000003961b4ac0556c9b5487cef5a73fed288a5afed7ff3f6d79ec8cfd63b3"), 1570205903, 0x1d04ab56 },
        {4032,  u256_hex_decode("00000000054f04d2f2187f474b5df94c99b74c6a8a5f45830c12b8f5129f5b7b"), 1570313108, 0x1c2f9b34 },
        {20160, u256_hex_decode("0000001c535b965a47922167a9e8720c353d450bd27f36f65c281fe5cafe4f61"), 1571340578, 0x1d2382fe },
        {40320, u256_hex_decode("000000052ca091fbb7b698cf9a1054982e6ffa7a9a4574d67274486cbefc82ab"), 1572593216, 0x1d077cb8 },
        {122976, u256_hex_decode("000000903d87f99e5c3f49c3cd6854439adba01516424498a589e09cce2b56cb"), 1535599185, 0x1b07cf3a }
}; // New testnet (7th), port:18770 useragent:"/Ravencoin2.1.1/"

static const CheckPoint RegTestCheckpoints[] = {
        {} // todo: retrieve using RPC call on local wallet!!
};

static int MainNetVerifyDifficulty(const BRMerkleBlock *block, const BRSet *blockSet) {
    const BRMerkleBlock *previous, *b = NULL;
    uint32_t i;

    assert(block != NULL);
    assert(blockSet != NULL);

    // check if we hit a difficulty transition, and find previous transition block
    if ((block->height % BLOCK_DIFFICULTY_INTERVAL) == 0) {
        for (i = 0, b = block; b && i < BLOCK_DIFFICULTY_INTERVAL; i++) {
            b = BRSetGet(blockSet, &b->prevBlock);
        }
    }

    previous = BRSetGet(blockSet, &block->prevBlock);
    return BRMerkleBlockVerifyDifficulty(block, previous, (b) ? b->timestamp : 0);
}

static int TestNetVerifyDifficulty(const BRMerkleBlock *block, const BRSet *blockSet) {
    return 1; // XXX skip testnet difficulty check for now
}

static int RegTestVerifyDifficulty(const BRMerkleBlock *block, const BRSet *blockSet) {
    return 1; // regtest diff check
}

// MainNet Burn Addresses
static const char strIssueAssetBurnAddressMainNet[] = "RXissueAssetXXXXXXXXXXXXXXXXXhhZGt";
static const char strReissueAssetBurnAddressMainNet[] = "RXReissueAssetXXXXXXXXXXXXXXVEFAWu";
static const char strIssueSubAssetBurnAddressMainNet[] = "RXissueSubAssetXXXXXXXXXXXXXWcwhwL";
static const char strIssueUniqueAssetBurnAddressMainNet[] = "RXissueUniqueAssetXXXXXXXXXXWEAe58";
static const char strGlobalBurnAddressMainNet[] = "RXBurnXXXXXXXXXXXXXXXXXXXXXXWUo9FV"; // Global Burn Address

// TestNet Burn Addresses
static const char strIssueAssetBurnAddressTestNet[] = "n1issueAssetXXXXXXXXXXXXXXXXWdnemQ";
static const char strReissueAssetBurnAddressTestNet[] = "n1ReissueAssetXXXXXXXXXXXXXXWG9NLd";
static const char strIssueSubAssetBurnAddressTestNet[] = "n1issueSubAssetXXXXXXXXXXXXXbNiH6v";
static const char strIssueUniqueAssetBurnAddressTestNet[] = "n1issueUniqueAssetXXXXXXXXXXS4695i";
static const char strGlobalBurnAddressTestNet[] = "n1BurnXXXXXXXXXXXXXXXXXXXXXXU1qejP"; // Global Burn Address

// RegTest Burn Addresses
static const char strIssueAssetBurnAddressRegTest[] = "n1issueAssetXXXXXXXXXXXXXXXXWdnemQ";
static const char strReissueAssetBurnAddressRegTest[] = "n1ReissueAssetXXXXXXXXXXXXXXWG9NLd";
static const char strIssueSubAssetBurnAddressRegTest[] = "n1issueSubAssetXXXXXXXXXXXXXbNiH6v";
static const char strIssueUniqueAssetBurnAddressRegTest[] = "n1issueUniqueAssetXXXXXXXXXXS4695i";
static const char strGlobalBurnAddressRegTest[] = "n1BurnXXXXXXXXXXXXXXXXXXXXXXU1qejP"; // Global Burn Address

static const BRChainParams BRMainNetParams = {
        MainNetDNSSeeds,
        8767,       // standardPort
        0x4e564152, // magicNumber
        0,          // services
        MainNetVerifyDifficulty,
        MainNetCheckpoints,
        sizeof(MainNetCheckpoints) / sizeof(*MainNetCheckpoints)
};

static const BRChainParams BRTestNetParamsRecord = {
        TestNetDNSSeeds,
        18770,      // standardPort
        0x544e5652, // magicNumber
        0,          // services
        TestNetVerifyDifficulty,
        TestNetCheckpoints,
        sizeof(TestNetCheckpoints) / sizeof(*TestNetCheckpoints)
};
const BRChainParams *BRTestNetParams = &BRTestNetParamsRecord;

static const BRChainParams BRRegTestParams = {
        RegTestDNSSeeds,
        18444,      // standardPort
        0x574f5243, // magicNumber
        0,          // services
        RegTestVerifyDifficulty,
        RegTestCheckpoints,
        sizeof(RegTestCheckpoints) / sizeof(*RegTestCheckpoints)
};
#endif // BRChainParams_h
