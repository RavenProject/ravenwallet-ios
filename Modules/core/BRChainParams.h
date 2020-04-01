//
//  BRChainParams.h
//
//  Created by Aaron Voisine on 1/10/18.
//  Copyright (c) 2019 breadwallet LLC
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

#ifndef BRChainParams_h
#define BRChainParams_h

#include "BRMerkleBlock.h"
#include "BRSet.h"
#include "BRPeer.h"
#include <assert.h>

static const int64_t COIN = 100000000;

// Burn Amounts
static const uint64_t IssueAssetBurnAmount = 500 * COIN;
static const uint64_t ReissueAssetBurnAmount = 100 * COIN;
static const uint64_t IssueSubAssetBurnAmount = 100 * COIN;
static const uint64_t IssueUniqueAssetBurnAmount = 5 * COIN;

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


typedef struct {
    uint32_t height;
    UInt256 hash;
    uint32_t timestamp;
    uint32_t target;
} BRCheckPoint;

typedef struct {
    const char **dnsSeeds; // NULL terminated array of dns seeds
    uint16_t standardPort;
    uint32_t magicNumber;
    uint64_t services;
    int (*verifyDifficulty)(const BRMerkleBlock *block, const BRMerkleBlock *previous, uint32_t transitionTime);
    const BRCheckPoint *checkpoints;
    size_t checkpointsCount;
} BRChainParams;

extern const BRChainParams *BRMainNetParams;
extern const BRChainParams *BRTestNetParams;

#endif // BRChainParams_h
