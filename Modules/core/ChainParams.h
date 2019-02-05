//
//  ChainParams.h
//
//  Created by Aaron Voisine on 1/10/18.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#ifndef ChainParams_h
#define ChainParams_h

#include "BRMerkleBlock.h"
#include "BRSet.h"
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

typedef struct {
    const char *const *dnsSeeds; // NULL terminated array of dns seeds
    uint16_t standardPort;
    uint32_t magicNumber;
    uint64_t services;

    int (*verifyDifficulty)(const BRMerkleBlock *block, const BRSet *blockSet); // blockSet must have last 2016 blocks or 180 for DGW
    const CheckPoint *checkpoints;
    size_t checkpointsCount;
} ChainParams;

static const char *MainNetDNSSeeds[] = {
        "seed-raven.ravencoin.com", "seed-raven.ravencoin.org.", "seed-raven.bitactivate.com.", NULL
};

static const char *TestNetDNSSeeds[] = {
        "seed-testnet-raven.ravencoin.com", "seed-testnet-raven.ravencoin.org.", "seed-testnet-raven.bitactivate.com.",
        "52.37.117.13", "52.19.46.153", "34.248.252.173", "34.220.62.90", NULL
};

static const char *RegTestDNSSeeds[] = {
        "127.0.0.1", NULL
};

// blockchain checkpoints - these are also used as starting points for partial chain downloads, so they must be at
// difficulty transition boundaries in order to verify the block difficulty at the immediately following transition
static const CheckPoint MainNetCheckpoints[] = {
    {      0, "0000006b444bc2f2ffe627be9d9e7e7a0730000870ef6eb6da46c8eae389df90", 1514999494, 0x1e00ffff },
        {   2016, "0000003e7c74d91113e9f8b203673bc77474112a3811f4fc25f577e5d4228035", 1515022405, 0x1d3fffc0 },
        {   4032, "0000000e7029625c8ceb5e42f2a84c15e1c4326ea91c3369d49d64655560c9c3", 1515034394, 0x1d0ffff0 },
        {  20160, "00000000146e792b63f2a18db16f32d2afc9f0b332839eb502cb9c9a8f1bc033", 1515665731, 0x1c53dd22 },
        {  40320, "00000000085e7d049938d66a08d151891c0087a6b3d78d400f1ca0944991ffde", 1516664426, 0x1c0a0075 },
        {  60480, "0000000000683f2d1bb44dd545eb4fea28c0f51eb513ea32b4e813f185a1f6ab", 1517740553, 0x1c01b501 },
        {  80640, "00000000000735f443ea62266bb7799a760c8336da0c7b7a987c895e83c9ea73", 1518771490, 0x1b43e935 },
        { 100800, "00000000000bf40aa747ca97da99e1e6878efff28f709d1969f0a2d95dda1414", 1519826997, 0x1b0fabc1 },
        { 120960, "000000000000203f20f1f2fc50546b4f3d0693a53e781b499884661e6762eb05", 1520934202, 0x1b060077 },
        { 141120, "00000000000367e05ceca64ebf6b72a87510bdcb6252ff071b7f4971661e9acf", 1522092453, 0x1b03cc83 },
        { 161280, "0000000000024a1d42423dd3e1cde28c78fe34857db63f08d21f11fc13e594c3", 1523259269, 0x1b028d7d },
        { 181440, "000000000000d202bdeb7993a1de022f82231fdce97e22f054626291eb79f4cb", 1524510281, 0x1b038153 },
        { 201600, "000000000001a16d8b86e19ac87df227458d29b5fb70dfef7e5b0203df085617", 1525709579, 0x1b0306f4 },
        { 221760, "000000000002b4a1ef811a31e58489794dba047e4e78e18d5611c94d7fc60174", 1526920402, 0x1b02ff59 },
        { 241920, "000000000001e64a356c6665afcb2871bc7f18e5609663b5b54a82fa204ee9b1", 1528150015, 0x1b037c77 },
        { 262080, "0000000000014a11d3aacdc5ee21e69fd8aefe10f0e617508dfb3e78d1ca82be", 1529359488, 0x1b037276 },
        { 282240, "00000000000182bbfada9dd47003bed09880b7a1025edcb605f9c048f2bad49e", 1530594496, 0x1b042cda },
        { 302400, "000000000001e9862c28d3359f2b568b03811988f2db2f91ab8b412acac891ed", 1531808927, 0x1b0422c8 },
        { 322560, "000000000001d50eaf12266c6ecaefec473fecd9daa7993db05b89e6ab381388", 1533209846, 0x1b04cb9e },
        { 338778, "000000000003198106731cb28fc24e9ace995a37709b026b25dfa905aea54517", 1535599185, 0x1b07cf3a },
        { 341086, "000000000001c72e3613de62be33974f69993bf16f10d117d14321afa4259a0e", 1535734416, 0x1b0203f4 }
};

static const CheckPoint TestNetCheckpoints[] = {
        {0,      "0000006ebc14cb6777bedda407702dfbc6b273f1af956bcfd6f4f98a2eb14433", 1533751200, 0x1e00ffff },  //Ravenized
        {13572,   "0000000079d39ce0974c30dfe6864afdb4fbd5a857b2c92d1fae018ce0defd3c", 1534653139, 0x1d013c98 },
        {24715,   "00000022dc6cdab73a14ba54ab0f34e6d8a6a65fab9fd3c7ca9b5342d3d96a12", 1535395316, 0x1d347780 },
        {338778,   "000000000003198106731cb28fc24e9ace995a37709b026b25dfa905aea54517", 1535599185, 0x1b07cf3a }
};

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

static const ChainParams MainNetParams = {
        MainNetDNSSeeds,
        8767,       // standardPort
        0x4e564152, // magicNumber
        0,          // services
        MainNetVerifyDifficulty,
        MainNetCheckpoints,
        sizeof(MainNetCheckpoints) / sizeof(*MainNetCheckpoints)
};

static const ChainParams TestNetParams = {
        TestNetDNSSeeds,
        18768,      // standardPort
        0x544e5652, // magicNumber
        0,          // services
        TestNetVerifyDifficulty,
        TestNetCheckpoints,
        sizeof(TestNetCheckpoints) / sizeof(*TestNetCheckpoints)
};

static const ChainParams RegTestParams = {
        RegTestDNSSeeds,
        18444,      // standardPort
        0x574f5243, // magicNumber
        0,          // services
        RegTestVerifyDifficulty,
        RegTestCheckpoints,
        sizeof(RegTestCheckpoints) / sizeof(*RegTestCheckpoints)
};
#endif // ChainParams_h
