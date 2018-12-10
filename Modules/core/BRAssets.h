//
// Created by ROSHii on 8/11/18.
//

#ifndef BRASSETS_H
#define BRASSETS_H


#include <string.h>
#include "BRTransaction.h"
#include "BRScript.h"
#include <stdbool.h>
#include "BRWallet.h"
#include "ChainParams.h"

#ifdef TESTNET
#define ASSET_ACTIVATION        6048
#elif REGTEST
#define ASSET_ACTIVATION        0
#else
#define ASSET_ACTIVATION        435456
#endif

//typedef int64_t Amount;

#define OWNER_TAG "!"
#define OWNER_LENGTH 1
#define OWNER_UNITS 0
#define MIN_ASSET_LENGTH 3
#define OWNER_ASSET_AMOUNT 1 * COIN

#define ASSET_TRANSFER_STRING "transfer_asset"
#define ASSET_NEW_STRING "new_asset"
#define ASSET_REISSUE_STRING "reissue_asset"

const char *GetAssetType(BRAssetType type);

// Functions to be used to get access to the current burn amount required for specific asset issuance transactions
Amount GetIssueAssetBurnAmount();
Amount GetReissueAssetBurnAmount();
Amount GetIssueSubAssetBurnAmount();
Amount GetIssueUniqueAssetBurnAmount();

bool AssetFromTransaction(const BRTransaction *tx, BRAsset* asset, char *strAddress);
bool OwnerFromTransaction(const BRTransaction *tx, char *ownerName, char *strAddress);
bool ReissueAssetFromTransaction(const BRTransaction *tx, BRAsset* reissue, char *strAddress);

bool TransferAssetFromScriptPubKey(char *addr, size_t addrLen, const uint8_t *script, size_t scriptLen,
                                   BRAsset *asset);
bool AssetFromScriptPubKey(char *addr, size_t addrLen, const uint8_t *script, size_t scriptLen, BRAsset *asset);
bool OwnerAssetFromScriptPubKey(char *addr, size_t addrLen, const uint8_t *script, size_t scriptLen, BRAsset *asset);
bool ReissueAssetFromScriptPubKey(char *addr, size_t addrLen, const uint8_t *script, size_t scriptLen,
                                  BRAsset *reissue);

bool CheckIssueBurnTx(const BRTxOutput *txOut);
bool CheckReissueBurnTx(const BRTxOutput *txOut);

bool CheckIssueDataTx(BRTxOutput txOut);
bool CheckOwnerDataTx(BRTxOutput txOut);
bool CheckReissueDataTx(BRTxOutput txOut);
bool CheckTransferOwnerTx(const BRTxOutput *txOut);

bool IsNewOwnerTxValid(const BRTransaction *tx, const char *assetName, const char *address, char *errorMsg);

bool CheckAssetOwner(const char *assetName);

bool GetAssetData(const uint8_t *script, size_t scriptLen, BRAsset *data);

size_t DecodeIPFS(uint8_t *data, size_t dataLen, const char *str);
size_t EncodeIPFS(char *str, size_t strLen, const uint8_t *data, size_t dataLen);

size_t ConstructNewAssetScript(uint8_t *script, size_t scriptLen, BRAsset *asset);
size_t ConstructTransferAssetScript(uint8_t *script, size_t scriptLen, BRAsset *asset);
size_t ConstructReissueAssetScript(uint8_t *script, size_t scriptLen, BRAsset *asset);
size_t ConstructOwnerAssetScript(uint8_t *script, size_t scriptLen, BRAsset *asset);

bool CreateAssetTransaction(BRWallet* wallet, const BRAsset* asset, const char *address, char *rvnChangeAddress,
        BRKey* key, Amount* nFeeRequired);
bool CreateReissueAssetTransaction(BRWallet *pwallet, const BRAsset *asset, const char *address,
        const char *changeAddress, BRKey* key, Amount* nFeeRequired);
bool CreateTransferAssetTransaction(BRWallet* pwallet, const char *changeAddress, BRKey* key, Amount* nFeeRequired);
bool SendAssetTransaction(BRWallet* pwallet, BRKey* key);

// returns a newly allocated empty asset that must be freed by calling AssetFree()
BRAsset *NewAsset(void);

// frees memory allocated for tx
void AssetFree(BRAsset *asset);

char *PrintAsset(BRAsset asset);

#endif //BRASSETS_H
