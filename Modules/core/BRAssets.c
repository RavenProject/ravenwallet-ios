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
#include "Version.h"
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
    
    // Reissuing an Asset must contain at least 3 CTxOut( Raven Burn Tx, Any Number of other Outputs ..., Owner Asset Change Tx, Reissue Tx)
    if (tx->outCount < 3)
        return false;
    
    // Check for the assets data CTxOut. This will always be the last output in the transaction
    if (!CheckIssueDataTx(tx->outputs[tx->outCount - 1]))
        return false;
    
    // Check to make sure the owner asset is created
    if (!CheckOwnerDataTx(tx->outputs[tx->outCount - 2]))
        return false;
    
    // Check for the Burn CTxOut in one of the vouts ( This is needed because the change CTxOut is places in a random position in the CWalletTx
    foreach(BRTxOutput *out, tx->outputs)
    if (CheckIssueBurnTx(out))
        return true;
    
    return false;
}

bool IsReissueAsset(const BRTransaction *tx) {
    // Reissuing an Asset must contain at least 3 CTxOut ( Raven Burn Tx, Any Number of other Outputs ..., Reissue Asset Tx, Owner Asset Change Tx)
    if (tx->outCount < 3)
        return false;
    
    // Check for the reissue asset data CTxOut. This will always be the last output in the transaction
    if (!CheckReissueDataTx(tx->outputs[tx->outCount - 1]))
        return false;
    
    // Check that there is an asset transfer, this will be the owner asset change
    bool ownerFound = false;
    foreach(BRTxOutput *out, tx->outputs)
    if (CheckTransferOwnerTx(out)) {
        //                ownerFound = true;
        break;
    }
    
    //    if (!ownerFound)
    //        return false;
    
    // Check for the Burn CTxOut in one of the vouts ( This is needed because the change CTxOut is placed in a random position in the CWalletTx
    foreach(BRTxOutput *out, tx->outputs)
    if (CheckReissueBurnTx(out))
        return true;
    
    return false;
}

// Retrieve assets data from given transaction
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
    
    //TODO: change this from VarInt to Uint8
    asset->unit = BRVarInt(&assetScript[off], (off <= (assetScriptLen) ? (assetScriptLen) - off : 0), &sLen);
    off += sLen;
    
    //TODO: change this from VarInt to Uint8
    asset->reissuable = BRVarInt(&assetScript[off], (off <= (assetScriptLen) ? (assetScriptLen) - off : 0), &sLen);
    off += sLen;
    
    //TODO: change this from VarInt to Uint8
    asset->hasIPFS = BRVarInt(&assetScript[off], (off <= (assetScriptLen) ? (assetScriptLen) - off : 0), &sLen);
    off += sLen;
    
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
ReissueAssetFromScriptPubKey(char *addr, size_t addrLen, const uint8_t *script, size_t scriptLen, BRAsset *reissue) {
    return true;
}

bool CheckIssueBurnTx(const BRTxOutput *txOut) {
    // Check the first transaction is the 500 Burn amount to the burn address
    if (txOut->amount != GetIssueAssetBurnAmount())
        return false;
    
    // Extract the destination
    char destination[36];
    if (!BRAddressFromScriptPubKey(destination, sizeof(destination), txOut->script, txOut->scriptLen))
        return false;
    
    // Verify address is valid
    if (!BRAddressIsValid(destination))
        return false;
    
    // Check destination address is the correct burn address
    if (strcmp(destination, strReissueAssetBurnAddressMainNet) != 0)
        return false;
    
    return true;
    
}

bool CheckReissueBurnTx(const BRTxOutput *txOut) {
    // Check the first transaction and verify that the correct RVN Amount
    if (txOut->amount != GetReissueAssetBurnAmount())
        return false;
    
    // Extract the destination
    char destination[36];
    if (!BRAddressFromScriptPubKey(destination, sizeof(destination), txOut->script, txOut->scriptLen))
        return false;
    
    // Verify address is valid
    if (!BRAddressIsValid(destination))
        return false;
    
    // Check destination address is the correct burn address
    if (strcmp(destination, strReissueAssetBurnAddressMainNet) != 0)
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
    
    // Get the Asset or Transfer Asset from the scriptPubKey
    if (IsScriptNewAsset(script, scriptLen)) {
        data->type = NEW_ASSET;
        if (NewAssetFromScriptPubKey(addr.s, sizeof(addr), script, scriptLen, data)) {
            return true;
        }
    } else if (IsScriptTransferAsset(script, scriptLen)) {
        data->type = TRANSFER;
        if (TransferAssetFromScriptPubKey(addr.s, sizeof(addr), script, scriptLen, data)) {
            return true;
        }
    } else if (IsScriptOwnerAsset(script, scriptLen)) {
        data->type = OWNER;
        if (OwnerAssetFromScriptPubKey(addr.s, sizeof(addr), script, scriptLen, data)) {
            return true;
        }
    } else if (IsScriptReissueAsset(script, scriptLen)) {
        data->type = REISSUE;
        if (NewAssetFromScriptPubKey(addr.s, sizeof(addr), script, scriptLen, data)) {
            return true;
        }
    }
    
    return false;
}

size_t DecodeIPFS(uint8_t *data, size_t dataLen, const char *str) {
    
    assert(data != NULL || dataLen == 0);
    return BRBase58Decode(data, dataLen, str);
    
}

size_t EncodeIPFS(char *str, size_t strLen, const uint8_t *data, size_t dataLen) {
    
    assert(data != NULL || dataLen == 0);
    return BRBase58Encode(str, strLen, data, dataLen);
    
}

size_t BRTxOutputSetNewAssetScript(uint8_t *script, size_t scriptLen, BRAsset *asset) {
    
    size_t off = 25;
    
//    assert(script != NULL || scriptLen == 0);
    assert(asset != NULL || asset->type == NEW_ASSET);
    if(!script) {
        if(asset->hasIPFS == 0)
            return 25 + 6 + 1 + asset->nameLen + sizeof(uint64_t) + 3*sizeof(uint8_t) + 1;
        else
            return 25 + 6 + 1 + asset->nameLen + sizeof(uint64_t) + 3*sizeof(uint8_t) + 1 /*+ 1 */+ 34;
    }
    if (!script || scriptLen == 0 || scriptLen > MAX_SCRIPT_LENGTH) return 0;
    
//    if(script) script = (uint8_t *)realloc(script, scriptLen + asset->nameLen + 12);

    script[25] = OP_RVN_ASSET;
    
    script[27] = RVN_R;
    script[28] = RVN_V;
    script[29] = RVN_N;
    script[30] = RVN_Q;
    
    off += 6;
    
    off += BRVarIntSet((script ? &script[off] : NULL), off, asset->nameLen);
    
    // Todo change asset name from char to uint8_t, if it works
    strncpy(script + off, asset->name, asset->nameLen);
    off += asset->nameLen;
    
    //    if (script && off + sizeof(uint64_t) <= scriptLen) UInt64SetLE(&script[off], asset->amount);
    UInt64SetLE(&script[off], asset->amount);
    off += sizeof(uint64_t);
    
    script[off] = asset->unit;
    off += sizeof(uint8_t);
    
    script[off] = asset->reissuable;
    off += sizeof(uint8_t);
    
    script[off] = asset->hasIPFS;
    off += sizeof(uint8_t);
    
    if(asset->hasIPFS == 1) {
        size_t n = DecodeIPFS(NULL, 0, asset->IPFSHash);
        uint8_t IPFS_hash[n];
        DecodeIPFS(IPFS_hash, n, asset->IPFSHash);
        
//        script[off] = n;
//        off += sizeof(uint8_t);

        strncpy(script + off, IPFS_hash, n);
        // TODO: create global variable for IPFS_HASH_LENGTH
        off += n;
    }
    
    script[26] = off - 25 - 2;
    
    script[off] = OP_DROP;
    off++;
    
    return off;
}

size_t BRTxOutputSetTransferAssetScript(uint8_t *script, size_t scriptLen, BRAsset *asset) {
    
    size_t off = 25;
    
//    assert(script != NULL || scriptLen == 0);
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
    
    // Todo change asset name from char to uint8_t, if it works
    strncpy(script + off, asset->name, asset->nameLen);
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
    
    assert(asset != NULL || asset->type == NEW_ASSET);
    if(!script) {
        if(asset->hasIPFS == 0)
            return 25 + 6 + 1 + asset->nameLen + sizeof(uint64_t) + 3 * sizeof(uint8_t) + 1;
        else return 25 + 6 + 1 + asset->nameLen + sizeof(uint64_t) + 3 * sizeof(uint8_t) + 1 + 46;
    }
    if (!script || scriptLen == 0 || scriptLen > MAX_SCRIPT_LENGTH) return 0;
    
    script[25] = OP_RVN_ASSET;
    
    script[27] = RVN_R;
    script[28] = RVN_V;
    script[29] = RVN_N;
    script[30] = RVN_R;
    
    off += 6;
    
    off += BRVarIntSet((script ? &script[off] : NULL), off, asset->nameLen);
    
    // Todo change asset name from char to uint8_t, if it works
    strncpy(script + off, asset->name, asset->nameLen);
    off += asset->nameLen;
    
    //    if (script && off + sizeof(uint64_t) <= scriptLen) UInt64SetLE(&script[off], asset->amount);
    UInt64SetLE(&script[off], asset->amount);
    off += sizeof(uint64_t);
    
    //    BRVarIntSet(script + off, off, asset->unit);
    script[off] = asset->unit;
    off += sizeof(uint8_t);
    
    //    BRVarIntSet(script + off, off, asset->reissuable);
    script[off] = asset->reissuable;
    off += sizeof(uint8_t);
    
    //    BRVarIntSet(script + off, off, asset->hasIPFS);
    script[off] = asset->hasIPFS;
    off += sizeof(uint8_t);
    
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
    strncpy(script + off, asset->name, asset->nameLen);
    off += asset->nameLen;
    
    strncpy(script + off, OWNER_TAG, strlen(OWNER_TAG));
    off += strlen(OWNER_TAG);
    
//    UInt64SetLE(&script[off], 1 * COIN);
//    off += sizeof(uint64_t);
    
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
    strncpy(script + off, asset->name, asset->nameLen);
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
    strncpy(script + off, asset->name, asset->nameLen);
    off += asset->nameLen;
    
    strncpy(script + off, OWNER_TAG, OWNER_LENGTH);
    off += strlen(OWNER_TAG);
    
    UInt64SetLE(&script[off], COIN);
    off += sizeof(uint64_t);
    
    script[26] = off - 25 - 2;
    
    script[off] = OP_DROP;
    off++;
    
    return off;
}

bool CreateAssetTransaction(BRWallet *wallet, const BRAsset *asset, const char *address, char *rvnChangeAddress,
                            BRKey *key, Amount *nFeeRequired) {
    
    int error = 0;
    
    BRTransaction *tx, *transaction = BRTransactionNew();
    UTXO *o;
    size_t i;
    
    assert(asset != NULL);
    assert(wallet != NULL);
    assert(address == NULL || BRAddressIsValid(address));
    assert(rvnChangeAddress == NULL || BRAddressIsValid(rvnChangeAddress));
    
    if (rvnChangeAddress && (strlen(rvnChangeAddress) == 0 || !BRAddressIsValid(rvnChangeAddress)))
        return false;
    
    // Get the burn amount for assets issuance.
    Amount burnAmount = GetIssueAssetBurnAmount();
    
    //
    //    for (i = 0; i < array_count(wallet->utxos); i++) {
    //
    //    }
    
    return true;
}

bool CreateReissueAssetTransaction(BRWallet *pwallet, const BRAsset *asset, const char *address,
                                   const char *changeAddress, BRKey *key, Amount *nFeeRequired) {
    
    return true;
}

bool
CreateTransferAssetTransaction(BRWallet *pwallet, const char *changeAddress, BRKey *key, Amount *nFeeRequired) {
    
    return true;
}

bool SendAssetTransaction(BRWallet *pwallet, BRKey *key) {
    
    return true;
}

BRAsset *NewAsset(void) {
    
    BRAsset *asset = calloc(1, sizeof(*asset));
    
    assert(asset != NULL);
    
    // todo initialize variable and allocate array mem
    //    array_new(asset->name, 1);
    
    return asset;
}

void showAsset(BRAsset* asset){
    printf("BMEX name %s, type %d, amount %llu, unit %d, hasIpfs %d, reiss %d \n", asset->name, asset->type, asset->amount, asset->unit, asset->hasIPFS, asset->reissuable);
}

void showTransaction(BRTransaction* tx){
    printf("BMEX tx %s \n", tx->txHash);
}

// frees memory allocated for asset
void AssetFree(BRAsset *asset) {
    assert(asset != NULL);
    
    if (asset) {
        if(asset->name) free(asset->name); // Check allocation problem for freeing
        free(asset);
    }
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
