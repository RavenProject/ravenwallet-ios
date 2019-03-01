//
// Created by ROSHii on 8/11/18.
// C module for assets creation and scripts for tx signing
//

#include "BRAssets.h"
#include "BRAddress.h"
#include <string.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <util.h>
#include "BRArray.h"
#include "BRScript.h"
#include "BRBase58.h"

const char *GetAssetScriptType(BRAssetScriptType type) {
    switch (type) {
        case TRANSFER :
            return "TRANSFER";
        case REISSUE :
            return "REISSUE";
        case NEW_ASSET :
            return "NEW";
        case OWNER:
            return "OWNER";
        case INVALID :
            return "INVALID";
    }
}

const char *GetAssetType(BRAssetType type) {
    switch (type) {
        case ROOT :
            return "ROOT";
        case UNIQUE :
            return "UNIQUE";
        case CHANNEL :
            return "CHANNEL";
        case VOTE :
            return "VOTE";
        case SUB:
            return "SUB";
    }
}

#define foreach(item, array) \
for(int keep = 1, \
count = 0,\
size = sizeof (array) / sizeof *(array); \
keep && count != size; \
keep = !keep, count++) \
for(item = (array) + count; keep; keep = !keep)

Amount GetIssueAssetBurnAmount() {
    return IssueAssetBurnAmount;
}

Amount GetReissueAssetBurnAmount() {
    return ReissueAssetBurnAmount;
}

Amount GetIssueSubAssetBurnAmount() {
    return IssueSubAssetBurnAmount;
}

Amount GetIssueUniqueAssetBurnAmount() {
    return IssueUniqueAssetBurnAmount;
}

bool IsNewAsset(const BRTransaction *tx) {
    
    // Issuing an Asset must contain at least 1 TxOut( Raven Burn Output, Any Number of other Outputs ..., Owner Asset Output, issue Output)
    if (tx->outCount < 3)
        return false;
    
    // Check for the assets data TxOut. This will always be the last output in the transaction
    if (!CheckIssueDataTx(tx->outputs[tx->outCount - 1]))
        return false;
    
    // Check to make sure the owner asset is created
    if (!CheckOwnerDataTx(tx->outputs[tx->outCount - 2]))
        return false;
    
    // Check for the Burn TxOut in one of the vouts ( This is needed because the change TxOut index is random because of the shuffle).
    foreach(BRTxOutput *out, tx->outputs)
    if (CheckIssueBurnTx(out))
        return true;
    
    return false;
}

bool IsReissueAsset(const BRTransaction *tx) {
    // Reissuing an Asset must contain at least 3 CTxOut ( Raven Burn Tx, Any Number of other Outputs ..., Reissue Asset Output, Owner Asset Change Output)
    if (tx->outCount < 3)
        return false;
    
    // Check for the reissue asset data TxOut. This will always be the last output in the transaction
    if (!CheckReissueDataTx(tx->outputs[tx->outCount - 1]))
        return false;
    
    // Check that there is an asset transfer, this will be the owner asset change
    bool ownerFound = false;
    foreach(BRTxOutput *out, tx->outputs)
    if (CheckTransferOwnerTx(out)) {
        ownerFound = true;
        break;
    }
    
    if (!ownerFound)
        return false;
    
    // Check for the Burn TxOut in one of the vouts ( This is needed because the change TxOut index is random because of the shuffle).
    foreach(BRTxOutput *out, tx->outputs)
    if (CheckReissueBurnTx(out))
        return true;
    
    return false;
}

// Retrieve root asset's issuance data from given transaction
bool AssetFromTransaction(const BRTransaction *tx, BRAsset *asset, char *strAddress) {
    // Check to see if the transaction is an new asset issue tx
    if (!IsNewAsset(tx))
        return false;
    
    // Get the scriptPubKey from the last tx in vout
    uint8_t *scriptPubKey = tx->outputs[tx->outCount - 1].script;
    size_t scriptLen = tx->outputs[tx->outCount - 1].scriptLen;
    
    return NewAssetFromScriptPubKey(strAddress, sizeof(strAddress), scriptPubKey, scriptLen, asset);
}

bool OwnerFromTransaction(const BRTransaction *tx, char *ownerName, char *strAddress) {
    // Check to see if the transaction is an new asset issue tx
    if (IsNewAsset(tx))
        return false;
    
    // Get the scriptPubKey from the last tx in vout
    uint8_t *scriptPubKey = tx->outputs[tx->outCount - 2].script;
    size_t scriptLen = tx->outputs[tx->outCount - 1].scriptLen;
    
    return OwnerAssetFromScriptPubKey(strAddress, sizeof(strAddress), scriptPubKey, scriptLen, NULL);
    
}

bool ReissueAssetFromTransaction(const BRTransaction *tx, BRAsset *reissue, char *strAddress) {
    // Check to see if the transaction is a reissue tx
    if (!IsReissueAsset(tx))
        return false;
    
    // Get the scriptPubKey from the last tx in vout
    uint8_t *scriptPubKey = tx->outputs[tx->outCount - 1].script;
    size_t scriptLen = tx->outputs[tx->outCount - 1].scriptLen;
    
    return ReissueAssetFromScriptPubKey(strAddress, sizeof(strAddress), scriptPubKey, scriptLen, reissue);
}

bool NewAssetFromScriptPubKey(char *addr, size_t addrLen, const uint8_t *script, size_t scriptLen, BRAsset *asset) {
    
    assert(script != NULL || scriptLen == 0);
    if (!script || scriptLen == 0 || scriptLen > MAX_SCRIPT_LENGTH) return 0;
    
    size_t off = 0, sLen = 0;
    
    uint8_t *assetScript;
    size_t assetScriptLen = scriptLen - 31;
    uint64_t amount;
    
    assetScript = malloc(assetScriptLen);
    assert(assetScript);
    
    memcpy(assetScript, script + 31, assetScriptLen);
    
    size_t name_size = (size_t) BRVarInt(&assetScript[off], (off <= (assetScriptLen) ? (assetScriptLen) - off : 0),
                                         &sLen);
    off += sLen;
    
    if (off <= assetScriptLen) {
        asset->name = malloc(name_size + 1);
        memcpy(asset->name, assetScript + off, name_size);
        asset->nameLen = name_size;
        off += name_size;
        
        *(asset->name + name_size) = '\0';
        assert(*(asset->name + name_size) == '\0');
    }
    
    amount = (off + sizeof(uint64_t) <= assetScriptLen) ? UInt64GetLE(&assetScript[off]) : 0;
    asset->amount = amount;
    off += sizeof(uint64_t);
    
    asset->unit = assetScript[off];
    off += sizeof(uint8_t);
    
    asset->reissuable = assetScript[off];
    off += sizeof(uint8_t);
    
    asset->hasIPFS = assetScript[off];
    off += sizeof(uint8_t);
    
    // Check the end of the script
    if (asset->hasIPFS == 0 || assetScript[off] == OP_DROP) {
        free(assetScript);
        return true;
    }
    
    size_t IPFS_length = 34;
    uint8_t IPFS_hash[IPFS_length];
    
    if (off <= assetScriptLen + IPFS_length) {
        memcpy(&IPFS_hash, assetScript + off, IPFS_length);
        off += IPFS_length;
        
        // Encode IPFS Hash to Base58, give a char array of 46 characters.
        size_t n = EncodeIPFS(NULL, 0, IPFS_hash, IPFS_length);
        EncodeIPFS(asset->IPFSHash, n, IPFS_hash, IPFS_length);
        
        if (assetScript[off] != OP_DROP) {
            free(assetScript);
            return false;
        }
    }
    
    free(assetScript);
    return true;
}

bool
TransferAssetFromScriptPubKey(char *addr, size_t addrLen, const uint8_t *script, size_t scriptLen, BRAsset *asset) {
    
    assert(script != NULL || scriptLen == 0);
    if (!script || scriptLen == 0 || scriptLen > MAX_SCRIPT_LENGTH) return 0;
    
    size_t off = 0, sLen = 0;
    //    AddressFromScriptPubKey(addr, addrLen, script, scriptLen);
    
    uint8_t *assetScript;
    size_t assetScriptLen = scriptLen - 31;
    uint64_t amount;
    
    assetScript = malloc(assetScriptLen);
    assert(assetScript);
    
    memcpy(assetScript, script + 31, assetScriptLen);
    
    size_t name_size = (size_t) BRVarInt(&assetScript[off], (off <= (assetScriptLen) ? (assetScriptLen) - off : 0),
                                         &sLen);
    off += sLen;
    
    if (off <= assetScriptLen) {
        asset->name = malloc(name_size + 1);
        memcpy(asset->name, assetScript + off, name_size);
        asset->nameLen = name_size;
        off += name_size;
        
        *(asset->name + name_size) = '\0';
        assert(*(asset->name + (name_size)) == '\0');
    }
    
    amount = (off + sizeof(uint64_t) <= assetScriptLen) ? UInt64GetLE(&assetScript[off]) : 0;
    asset->amount = amount;
    off += sizeof(uint64_t);
    
//    printf("/nBMEX TransferAssetFromScriptPubKey 267 asset name %s, %llu\n", asset->name, asset->amount / COIN);

    // Check the end of the script
    if (assetScript[off] != OP_DROP) {
        free(assetScript);
        return false;
    }
    
    free(assetScript);
    return true;
}

bool
OwnerAssetFromScriptPubKey(char *addr, size_t addrLen, const uint8_t *script, size_t scriptLen, BRAsset *asset) {
    
    assert(asset != NULL);
    assert(script != NULL || scriptLen == 0);
    if (!script || scriptLen == 0 || scriptLen > MAX_SCRIPT_LENGTH) return 0;
    
    size_t off = 0, sLen = 0;

    uint8_t *assetScript;
    size_t assetScriptLen = scriptLen - 31;
    uint64_t amount;
    
    assetScript = malloc(assetScriptLen);
    assert(assetScript);
    
    memcpy(assetScript, script + 31, assetScriptLen);
    
    size_t name_size = (size_t) BRVarInt(&assetScript[off], (off <= (assetScriptLen) ? (assetScriptLen) - off : 0),
                                         &sLen);
    off += sLen;
    
    if (off <= assetScriptLen) {
        asset->name = malloc(name_size + 1);
        memcpy(asset->name, assetScript + off, name_size);
        asset->nameLen = name_size;
        off += name_size;
        
        *(asset->name + name_size) = '\0';
        assert(*(asset->name + name_size) == '\0');
    }
    if((off + sizeof(uint64_t)) < assetScriptLen) {
        amount = (off + sizeof(uint64_t) <= assetScriptLen) ? UInt64GetLE(&assetScript[off]) : 0;
        asset->amount = amount;
        off += sizeof(uint64_t);
    } else asset->amount = 1 * COIN;
    
    if (assetScript[off] != OP_DROP) {
        free(assetScript);
        return false;
    }
    
    free(assetScript);
    return true;
}

bool
ReissueAssetFromScriptPubKey(char *addr, size_t addrLen, const uint8_t *script, size_t scriptLen, BRAsset *asset) {
    
    assert(script != NULL || scriptLen == 0);
    if (!script || scriptLen == 0 || scriptLen > MAX_SCRIPT_LENGTH) return 0;
    
    size_t off = 0, sLen = 0;
    
    uint8_t *assetScript;
    size_t assetScriptLen = scriptLen - 31;
    uint64_t amount;
    
    assetScript = malloc(assetScriptLen);
    assert(assetScript);
    
    memcpy(assetScript, script + 31, assetScriptLen);
    
    size_t name_size = (size_t) BRVarInt(&assetScript[off], (off <= (assetScriptLen) ? (assetScriptLen) - off : 0),
                                         &sLen);
    off += sLen;
    
    if (off <= assetScriptLen) {
        asset->name = malloc(name_size + 1);
        memcpy(asset->name, assetScript + off, name_size);
        asset->nameLen = name_size;
        off += name_size;
        
        *(asset->name + name_size) = '\0';
        assert(*(asset->name + name_size) == '\0');
    }
    
    amount = (off + sizeof(uint64_t) <= assetScriptLen) ? UInt64GetLE(&assetScript[off]) : 0;
    asset->amount = amount;
    off += sizeof(uint64_t);
    
    asset->unit = assetScript[off];
    off += sizeof(uint8_t);
    
    asset->reissuable = assetScript[off];
    off += sizeof(uint8_t);
    
    // Check the end of the script
    if (assetScript[off] == OP_DROP) {
        asset->hasIPFS = 0;
        free(assetScript);
        return true;
    }
    
    asset->hasIPFS = 1;
    size_t IPFS_length = 34;
    uint8_t IPFS_hash[IPFS_length];
    
    if (off <= assetScriptLen + IPFS_length) {
        memcpy(&IPFS_hash, assetScript + off, IPFS_length);
        off += IPFS_length;
        
        // Encode IPFS Hash to Base58, give a char array of 46 characters.
        size_t n = EncodeIPFS(NULL, 0, IPFS_hash, IPFS_length);
        EncodeIPFS(asset->IPFSHash, n, IPFS_hash, IPFS_length);
        
        if (assetScript[off] != OP_DROP) {
            free(assetScript);
            return false;
        }
    }
    
    free(assetScript);
    return true;
}

bool CheckIssueBurnTx(const BRTxOutput *txOut) {
    // Check the transaction is the 500 Burn amount to the burn address
    if (txOut->amount != GetIssueAssetBurnAmount())
        return false;
    
    // Verify address is valid
    if (!BRAddressIsValid(txOut->address))
        return false;
    
#if TESTNET
    if (strcmp(txOut->address, strIssueAssetBurnAddressTestNet) != 0)
        return false;
#endif
    if (strcmp(txOut->address, strIssueAssetBurnAddressMainNet) != 0)
        return false;

    return true;
    
}

bool CheckReissueBurnTx(const BRTxOutput *txOut) {
    // Check the transaction and verify that the correct RVN Amount
    if (txOut->amount != GetReissueAssetBurnAmount())
        return false;
    
    // Verify address is valid
    if (!BRAddressIsValid(txOut->address))
        return false;
    
    // Check destination address is the correct burn address
#if TESTNET
    if (strcmp(txOut->address, strReissueAssetBurnAddressTestNet) != 0)
        return false;
#endif
    if (strcmp(txOut->address, strReissueAssetBurnAddressMainNet) != 0)
        return false;

    return true;
}

bool CheckIssueDataTx(BRTxOutput txOut) {
    
    return IsScriptAsset(txOut.script, txOut.scriptLen);
    
}

bool CheckOwnerDataTx(BRTxOutput txOut) {
    
    return IsScriptOwnerAsset(txOut.script, txOut.scriptLen);
    
}

bool CheckReissueDataTx(BRTxOutput txOut) {
    
    return IsScriptReissueAsset(txOut.script, txOut.scriptLen);
    
}

bool CheckTransferOwnerTx(const BRTxOutput *txOut) {
    
    return IsScriptTransferAsset(txOut->script, txOut->scriptLen);
    
}

bool CheckAssetOwner(const char *assetName) {
    
    return true;
}

bool GetAssetData(const uint8_t *script, size_t scriptLen, BRAsset *data) {
    
    BRAddress addr;
    
    // Gets the Asset from the scriptPubKey
    if (IsScriptNewAsset(script, scriptLen)) {
        data->type = NEW_ASSET;
        return NewAssetFromScriptPubKey(addr.s, sizeof(addr), script, scriptLen, data);
    } else if (IsScriptTransferAsset(script, scriptLen)) {
        data->type = TRANSFER;
        return TransferAssetFromScriptPubKey(addr.s, sizeof(addr), script, scriptLen, data);
    } else if (IsScriptOwnerAsset(script, scriptLen)) {
        data->type = OWNER;
        return OwnerAssetFromScriptPubKey(addr.s, sizeof(addr), script, scriptLen, data);
    } else if (IsScriptReissueAsset(script, scriptLen)) {
        data->type = REISSUE;
        return ReissueAssetFromScriptPubKey(addr.s, sizeof(addr), script, scriptLen, data);
    }
    
    return false;
}

size_t DecodeIPFS(uint8_t *data, size_t dataLen, const char *str) {
    
    return BRBase58Decode(data, dataLen, str);
}

size_t EncodeIPFS(char *str, size_t strLen, const uint8_t *data, size_t dataLen) {
    
    return BRBase58Encode(str, strLen, data, dataLen);
}

size_t BRTxOutputSetNewAssetScript(uint8_t *script, size_t scriptLen, BRAsset *asset) {
    
    size_t off = 25;
    
    assert(asset != NULL && asset->type == NEW_ASSET);
    if(!script) {
        if(asset->hasIPFS == 0)
            return 25 + 6 + 1 + asset->nameLen + sizeof(uint64_t) + 3*sizeof(uint8_t) + 1;
        else
            return 25 + 6 + 1 + asset->nameLen + sizeof(uint64_t) + 3*sizeof(uint8_t) + 1 + IPFS_HASH_LENGTH;
    }
    if (!script || scriptLen == 0 || scriptLen > MAX_SCRIPT_LENGTH) return 0;
    
    script[25] = OP_RVN_ASSET;
    
    script[27] = RVN_R;
    script[28] = RVN_V;
    script[29] = RVN_N;
    script[30] = RVN_Q;
    
    off += 6;
    
    off += BRVarIntSet((script ? &script[off] : NULL), off, asset->nameLen);
    
    // Todo change asset name from char to uint8_t, if it works
    memcpy(script + off, asset->name, asset->nameLen);
    off += asset->nameLen;
    
    UInt64SetLE(&script[off], asset->amount);
    off += sizeof(uint64_t);
    
    script[off] = (int) (asset->unit);
    off += sizeof(uint8_t);
    
    script[off] = (int) (asset->reissuable);
    off += sizeof(uint8_t);
    
    script[off] = (int) (asset->hasIPFS);
    off += sizeof(uint8_t);

    if(asset->hasIPFS == 1) {
        size_t n = DecodeIPFS(NULL, 0, asset->IPFSHash);
        uint8_t IPFS_hash[n];
        DecodeIPFS(IPFS_hash, n, asset->IPFSHash);
        
        memcpy(script + off, IPFS_hash, n);
        off += n;
    }
    
    script[26] = off - 25 - 2;
    
    script[off] = OP_DROP;
    off++;
    
    return off;
}

size_t BRTxOutputSetTransferAssetScript(uint8_t *script, size_t scriptLen, BRAsset *asset) {
    
    size_t off = 25;
    
    assert(asset != NULL);
    if(!script) return 25 + 6 + 1 + asset->nameLen + sizeof(uint64_t) + 1;
    if (!script || scriptLen == 0 || scriptLen > MAX_SCRIPT_LENGTH) return 0;
    
    script[25] = OP_RVN_ASSET;
    
    script[27] = RVN_R;
    script[28] = RVN_V;
    script[29] = RVN_N;
    script[30] = RVN_T;
    
    off += 6;
    
    off += BRVarIntSet((script ? &script[off] : NULL), off, asset->nameLen);
    
    memcpy(script + off, asset->name, asset->nameLen);
    off += asset->nameLen;
    
    UInt64SetLE(&script[off], asset->amount);
    off += sizeof(uint64_t);
    
    script[26] = off - 25 - 2;
    
    script[off] = OP_DROP;
    off++;
    
    return off;
}

size_t BRTxOutputSetReissueAssetScript(uint8_t *script, size_t scriptLen, BRAsset *asset) {
    
    //TODO: change 25 to global variable Script Size (make it of find it)
    size_t off = 25;
    
    assert(asset != NULL && asset->type != NEW_ASSET);
    if(!script) {
        if(asset->hasIPFS == 0)
            return 25 + 6 + 1 + asset->nameLen + sizeof(uint64_t) + 3 * sizeof(uint8_t) + 1;
        else
            return 25 + 6 + 1 + asset->nameLen + sizeof(uint64_t) + 3 * sizeof(uint8_t) + 1 + IPFS_HASH_LENGTH;
    }
    if (!script || scriptLen == 0 || scriptLen > MAX_SCRIPT_LENGTH) return 0;
    
    script[25] = OP_RVN_ASSET;
    
    script[27] = RVN_R;
    script[28] = RVN_V;
    script[29] = RVN_N;
    script[30] = RVN_R;
    
    off += 6;
    
    off += BRVarIntSet((script ? &script[off] : NULL), off, asset->nameLen);
    
    memcpy(script + off, asset->name, asset->nameLen);
    off += asset->nameLen;
    
    UInt64SetLE(&script[off], asset->amount);
    off += sizeof(uint64_t);
    
    script[off] = (int) (asset->unit);
    off += sizeof(uint8_t);
    
    script[off] = (int) (asset->reissuable);
    off += sizeof(uint8_t);
    
    if(asset->hasIPFS == 1) {
        size_t n = DecodeIPFS(NULL, 0, asset->IPFSHash);
        uint8_t IPFS_hash[n];
        DecodeIPFS(IPFS_hash, n, asset->IPFSHash);
        printf("Decoded ipfs hash: %s", IPFS_hash);
        
        memcpy(script + off, IPFS_hash, n);
        off += n; //IPFS_HASH_LENGTH
    }
    
    script[26] = off - 25 - 2;
    
    script[off] = OP_DROP;
    off++;
    
    return off;
}

size_t BRTxOutputSetOwnerAssetScript(uint8_t *script, size_t scriptLen, BRAsset *asset) {
    
    size_t off = 25;
    
    assert(script != NULL || scriptLen == 0);
    if (!script) return 25 + 6 + 1 + asset->nameLen + OWNER_LENGTH + 1;
    if (!script || scriptLen == 0 || scriptLen > MAX_SCRIPT_LENGTH) return 0;
    
    script[25] = OP_RVN_ASSET;
    
    script[27] = RVN_R;
    script[28] = RVN_V;
    script[29] = RVN_N;
    script[30] = RVN_O;
    
    off += 6;
    
    size_t ownerNameSize = asset->nameLen + 1;
    off += BRVarIntSet((script ? &script[off] : NULL), off, ownerNameSize);
    
    // TODO: change asset name from char * to uint8_t *
    memcpy(script + off, asset->name, asset->nameLen);
    off += asset->nameLen;
    
    memcpy(script + off, OWNER_TAG, strlen(OWNER_TAG));
    off += strlen(OWNER_TAG);
    
    script[26] = off - 25 - 2;
    
    script[off] = OP_DROP;
    off++;
    
    return off;
}

size_t BRTxOutputSetTransferOwnerAssetScript(uint8_t *script, size_t scriptLen, BRAsset *asset) {
    
    
    size_t off = 25;
    
    assert(script != NULL || scriptLen == 0);
    if (!script) return 25 + 6 + 1 + asset->nameLen + sizeof(uint64_t) /*+ OWNER_LENGTH*/ + 1;
    if (!script || scriptLen == 0 || scriptLen > MAX_SCRIPT_LENGTH) return 0;
    
    script[25] = OP_RVN_ASSET;
    
    script[27] = RVN_R;
    script[28] = RVN_V;
    script[29] = RVN_N;
    script[30] = RVN_T;
    
    off += 6;
    
    size_t ownerNameSize = asset->nameLen;
    off += BRVarIntSet((script ? &script[off] : NULL), off, ownerNameSize);
    
    // TODO: change asset name from char * to uint8_t *
    memcpy(script + off, asset->name, asset->nameLen);
    off += asset->nameLen;
    
    //BMEX: OwnerShip tag removed in iOS
    //    strncpy(script + off, OWNER_TAG, strlen(OWNER_TAG));
    //    off += strlen(OWNER_TAG);
    
    UInt64SetLE(&script[off], asset->amount);
    off += sizeof(uint64_t);

    script[26] = off - 25 - 2;
    
    script[off] = OP_DROP;
    off++;
    
    return off;
}

// TODO: Test Test, remove this, please don't forget (cry)
size_t BRTxOutputSetTransferOwnerAssetScriptWithoutTag(uint8_t *script, size_t scriptLen, BRAsset *asset) {
    
    size_t off = 25;
    
    assert(script != NULL || scriptLen == 0);
    if (!script) return 25 + 6 + 1 + asset->nameLen + sizeof(uint64_t) + OWNER_LENGTH + 1;
    if (!script || scriptLen == 0 || scriptLen > MAX_SCRIPT_LENGTH) return 0;
    
    script[25] = OP_RVN_ASSET;
    
    script[27] = RVN_R;
    script[28] = RVN_V;
    script[29] = RVN_N;
    script[30] = RVN_T;
    
    off += 6;
    
    size_t ownerNameSize = asset->nameLen + OWNER_LENGTH;
    off += BRVarIntSet((script ? &script[off] : NULL), off, ownerNameSize);
    
    // TODO: change asset name from char * to uint8_t *
    memcpy(script + off, asset->name, asset->nameLen);
    off += asset->nameLen;
    
    memcpy(script + off, OWNER_TAG, OWNER_LENGTH);
    off += strlen(OWNER_TAG);
    
    UInt64SetLE(&script[off], COIN);
    off += sizeof(uint64_t);
    
    script[26] = off - 25 - 2;
    
    script[off] = OP_DROP;
    off++;
    
    return off;
}

BRAsset *NewAsset(void) {
    
    BRAsset *asset = calloc(1, sizeof(*asset));
    
    assert(asset != NULL);
    
    // todo initialize variable and allocate array mem
    //    array_new(asset->name, 1);
    
    return asset;
}

// frees memory allocated for asset
void AssetFree(BRAsset *asset) {
    assert(asset != NULL);
    
    if (asset) {
        if(asset->name) free(asset->name); // Check allocation problem for freeing
        free(asset);
    }
}

void showAsset(BRAsset* asset){
    printf("BMEX2: asset: Name %s, amount %llu unit %d, reissu %d, hasIpfs %d\n ", asset->name, asset->amount, asset->unit, asset->reissuable, asset->hasIPFS);
}

void CopyAsset(BRAsset *asst, BRTransaction *tx) {
    tx->asset = NewAsset();
    tx->asset->name = malloc(asst->nameLen);
    strcpy(tx->asset->name, asst->name);
    tx->asset->nameLen = asst->nameLen;
    tx->asset->amount = asst->amount;
    tx->asset->type = asst->type;
    tx->asset->reissuable = asst->reissuable;
    tx->asset->unit = asst->unit;
    tx->asset->hasIPFS = asst->hasIPFS;
    if(asst->hasIPFS == 1)
        strcpy(tx->asset->IPFSHash, asst->IPFSHash);
}
