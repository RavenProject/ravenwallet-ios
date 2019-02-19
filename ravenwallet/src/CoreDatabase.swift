//
//  Database.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2017-11-10.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import Foundation
import Core
import sqlite3

internal let SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)
internal let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

enum WalletManagerError: Error {
    case sqliteError(errorCode: Int32, description: String)
}

private func SafeSqlite3ColumnBlob<T>(statement: OpaquePointer, iCol: Int32) -> UnsafePointer<T>? {
    guard let result = sqlite3_column_blob(statement, iCol) else { return nil }
    return result.assumingMemoryBound(to: T.self)
}

class CoreDatabase {
    
    private let dbPath: String
    private var db: OpaquePointer? = nil
    private var txEnt: Int32 = 0
    private var blockEnt: Int32 = 0
    private var peerEnt: Int32 = 0
    private var assetsCount: Int = 0
    private let queue = DispatchQueue(label: "com.mediciventures.ravenwallet.corecbqueue")
    
    init(dbPath: String = "RavenWallet.sqlite") {
        self.dbPath = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil,
                                                   create: false).appendingPathComponent(dbPath).path
        queue.async {
            try? self.openDatabase()
        }
        print("Test dbPath ", self.dbPath)//BMEX Todo : should delete this comment
    }
    
    deinit {
        if db != nil { sqlite3_close(db) }
    }
    
    func close() {
        if db != nil { sqlite3_close(db) }
    }
    
    func delete() {
        try? FileManager.default.removeItem(atPath: dbPath)
    }
    
    private func openDatabase() throws {
        // open sqlite database
        if sqlite3_open_v2( self.dbPath, &db,
                            SQLITE_OPEN_FULLMUTEX | SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE, nil
            ) != SQLITE_OK {
            print(String(cString: sqlite3_errmsg(db)))
            
            #if DEBUG
            throw WalletManagerError.sqliteError(errorCode: sqlite3_errcode(db),
                                                 description: String(cString: sqlite3_errmsg(db)))
            #else
            try FileManager.default.removeItem(atPath: self.dbPath)
            
            if sqlite3_open_v2( self.dbPath, &db,
                                SQLITE_OPEN_FULLMUTEX | SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE, nil
                ) != SQLITE_OK {
                throw WalletManagerError.sqliteError(errorCode: sqlite3_errcode(db),
                                                     description: String(cString: sqlite3_errmsg(db)))
            }
            #endif
        }
        
        // create tables and indexes (these are inherited from CoreData)
        
        // tx table
        sqlite3_exec(db, "create table if not exists ZBRTXMETADATAENTITY (" +
            "Z_PK integer primary key," +
            "Z_ENT integer," +
            "Z_OPT integer," +
            "ZTYPE integer," +
            "ZBLOB blob," +
            "ZTXHASH blob)", nil, nil, nil)
        sqlite3_exec(db, "create index if not exists ZBRTXMETADATAENTITY_ZTXHASH_INDEX " +
            "on ZBRTXMETADATAENTITY (ZTXHASH)", nil, nil, nil)
        sqlite3_exec(db, "create index if not exists ZBRTXMETADATAENTITY_ZTYPE_INDEX " +
            "on ZBRTXMETADATAENTITY (ZTYPE)", nil, nil, nil)
        if sqlite3_errcode(db) != SQLITE_OK { print(String(cString: sqlite3_errmsg(db))) }
        
        // blocks table
        sqlite3_exec(db, "create table if not exists ZBRMERKLEBLOCKENTITY (" +
            "Z_PK integer primary key," +
            "Z_ENT integer," +
            "Z_OPT integer," +
            "ZHEIGHT integer," +
            "ZNONCE integer," +
            "ZTARGET integer," +
            "ZTOTALTRANSACTIONS integer," +
            "ZVERSION integer," +
            "ZTIMESTAMP timestamp," +
            "ZBLOCKHASH blob," +
            "ZFLAGS blob," +
            "ZHASHES blob," +
            "ZMERKLEROOT blob," +
            "ZPREVBLOCK blob)", nil, nil, nil)
        sqlite3_exec(db, "create index if not exists ZBRMERKLEBLOCKENTITY_ZBLOCKHASH_INDEX " +
            "on ZBRMERKLEBLOCKENTITY (ZBLOCKHASH)", nil, nil, nil)
        sqlite3_exec(db, "create index if not exists ZBRMERKLEBLOCKENTITY_ZHEIGHT_INDEX " +
            "on ZBRMERKLEBLOCKENTITY (ZHEIGHT)", nil, nil, nil)
        sqlite3_exec(db, "create index if not exists ZBRMERKLEBLOCKENTITY_ZPREVBLOCK_INDEX " +
            "on ZBRMERKLEBLOCKENTITY (ZPREVBLOCK)", nil, nil, nil)
        if sqlite3_errcode(db) != SQLITE_OK { print(String(cString: sqlite3_errmsg(db))) }
        
        // peers table
        sqlite3_exec(db, "create table if not exists ZBRPEERENTITY (" +
            "Z_PK integer PRIMARY KEY," +
            "Z_ENT integer," +
            "Z_OPT integer," +
            "ZADDRESS integer," +
            "ZMISBEHAVIN integer," +
            "ZPORT integer," +
            "ZSERVICES integer," +
            "ZTIMESTAMP timestamp)", nil, nil, nil)
        sqlite3_exec(db, "create index if not exists ZBRPEERENTITY_ZADDRESS_INDEX on ZBRPEERENTITY (ZADDRESS)",
                     nil, nil, nil)
        sqlite3_exec(db, "create index if not exists ZBRPEERENTITY_ZMISBEHAVIN_INDEX on ZBRPEERENTITY (ZMISBEHAVIN)",
                     nil, nil, nil)
        sqlite3_exec(db, "create index if not exists ZBRPEERENTITY_ZPORT_INDEX on ZBRPEERENTITY (ZPORT)",
                     nil, nil, nil)
        sqlite3_exec(db, "create index if not exists ZBRPEERENTITY_ZTIMESTAMP_INDEX on ZBRPEERENTITY (ZTIMESTAMP)",
                     nil, nil, nil)
        if sqlite3_errcode(db) != SQLITE_OK { print(String(cString: sqlite3_errmsg(db))) }
        
        // Asset Table
        sqlite3_exec(db, "create table if not exists ZBRASSET (" +
            "Z_ID integer PRIMARY KEY AUTOINCREMENT," +
            "Z_NAME VARCHAR NOT NULL," +
            "Z_AMOUNT integer NOT NULL," +
            "Z_UNITS integer NOT NULL," +
            "Z_REISSUBALE integer NOT NULL," +
            "Z_HAS_IPFS integer NOT NULL," +
            "Z_IPFS_HASH VARCHAR," +
            "Z_OWNERSHIP integer NOT NULL," +
            "Z_ISHIDDEN integer," +
            "Z_SORT integer)", nil, nil, nil)
        if sqlite3_errcode(db) != SQLITE_OK { print(String(cString: sqlite3_errmsg(db))) }
        
        // Asset Table
        sqlite3_exec(db, "create table if not exists ZBRASSET_NAME (" +
            "Z_ID integer PRIMARY KEY AUTOINCREMENT," +
            "Z_ASSET_NAME VARCHAR NOT NULL," +
            "Z_IPFS_HASH VARCHAR," +
            "Z_TX_HASH VARCHAR," +
            "Z_ADDRESS_OWNER integer NOT NULL," +
            "ZTIMESTAMP integer)", nil, nil, nil)
        if sqlite3_errcode(db) != SQLITE_OK { print(String(cString: sqlite3_errmsg(db))) }
        
        // AddressBook Table
        sqlite3_exec(db, "create table if not exists ZBRADDRESSBOOK (" +
            "Z_NAME VARCHAR," +
            "Z_ADDRESS VARCHAR PRIMARY KEY)", nil, nil, nil)
        if sqlite3_errcode(db) != SQLITE_OK { print(String(cString: sqlite3_errmsg(db))) }
        
        // primary keys
        sqlite3_exec(db, "create table if not exists Z_PRIMARYKEY (" +
            "Z_ENT INTEGER PRIMARY KEY," +
            "Z_NAME VARCHAR," +
            "Z_SUPER INTEGER," +
            "Z_MAX INTEGER)", nil, nil, nil)
        sqlite3_exec(db, "insert into Z_PRIMARYKEY (Z_ENT, Z_NAME, Z_SUPER, Z_MAX) " +
            "select 6, 'BRTxMetadataEntity', 0, 0 except " +
            "select 6, Z_NAME, 0, 0 from Z_PRIMARYKEY where Z_NAME = 'BRTxMetadataEntity'", nil, nil, nil)
        sqlite3_exec(db, "insert into Z_PRIMARYKEY (Z_ENT, Z_NAME, Z_SUPER, Z_MAX) " +
            "select 2, 'BRMerkleBlockEntity', 0, 0 except " +
            "select 2, Z_NAME, 0, 0 from Z_PRIMARYKEY where Z_NAME = 'BRMerkleBlockEntity'", nil, nil, nil)
        sqlite3_exec(db, "insert into Z_PRIMARYKEY (Z_ENT, Z_NAME, Z_SUPER, Z_MAX) " +
            "select 3, 'BRPeerEntity', 0, 0 except " +
            "select 3, Z_NAME, 0, 0 from Z_PRIMARYKEY where Z_NAME = 'BRPeerEntity'", nil, nil, nil)
        if sqlite3_errcode(db) != SQLITE_OK { print(String(cString: sqlite3_errmsg(db))) }
        
        var sql: OpaquePointer? = nil
        sqlite3_prepare_v2(db, "select Z_ENT, Z_NAME from Z_PRIMARYKEY", -1, &sql, nil)
        defer { sqlite3_finalize(sql) }
        
        while sqlite3_step(sql) == SQLITE_ROW {
            let name = String(cString: sqlite3_column_text(sql, 1))
            if name == "BRTxMetadataEntity" { txEnt = sqlite3_column_int(sql, 0) }
            else if name == "BRMerkleBlockEntity" { blockEnt = sqlite3_column_int(sql, 0) }
            else if name == "BRPeerEntity" { peerEnt = sqlite3_column_int(sql, 0) }
        }
        
        if sqlite3_errcode(db) != SQLITE_DONE { print(String(cString: sqlite3_errmsg(db))) }
    }
    
    func txAdded(_ tx: BRTxRef) {
        queue.async {
            var buf = [UInt8](repeating: 0, count: BRTransactionSerialize(tx, nil, 0))
            let timestamp = (tx.pointee.timestamp > UInt32(NSTimeIntervalSince1970)) ? tx.pointee.timestamp - UInt32(NSTimeIntervalSince1970) : 0
            guard BRTransactionSerialize(tx, &buf, buf.count) == buf.count else { return }
            [tx.pointee.blockHeight.littleEndian, timestamp.littleEndian].withUnsafeBytes { buf.append(contentsOf: $0) }
            sqlite3_exec(self.db, "begin exclusive", nil, nil, nil)
            
            var sql: OpaquePointer? = nil
            sqlite3_prepare_v2(self.db, "select Z_MAX from Z_PRIMARYKEY where Z_ENT = \(self.txEnt)", -1, &sql, nil)
            defer { sqlite3_finalize(sql) }
            
            guard sqlite3_step(sql) == SQLITE_ROW else {
                print(String(cString: sqlite3_errmsg(self.db)))
                sqlite3_exec(self.db, "rollback", nil, nil, nil)
                return
            }
            
            let pk = sqlite3_column_int(sql, 0)
            var sql2: OpaquePointer? = nil
            sqlite3_prepare_v2(self.db, "insert or rollback into ZBRTXMETADATAENTITY " +
                "(Z_PK, Z_ENT, Z_OPT, ZTYPE, ZBLOB, ZTXHASH) " +
                "values (\(pk + 1), \(self.txEnt), 1, 1, ?, ?)", -1, &sql2, nil)
            defer { sqlite3_finalize(sql2) }
            sqlite3_bind_blob(sql2, 1, buf, Int32(buf.count), SQLITE_TRANSIENT)
            sqlite3_bind_blob(sql2, 2, [tx.pointee.txHash], Int32(MemoryLayout<UInt256>.size), SQLITE_TRANSIENT)
            
            guard sqlite3_step(sql2) == SQLITE_DONE else {
                print(String(cString: sqlite3_errmsg(self.db)))
                return
            }
            
            sqlite3_exec(self.db, "update or rollback Z_PRIMARYKEY set Z_MAX = \(pk + 1) " +
                "where Z_ENT = \(self.txEnt) and Z_MAX = \(pk)", nil, nil, nil)
            
            guard sqlite3_errcode(self.db) == SQLITE_OK else {
                print(String(cString: sqlite3_errmsg(self.db)))
                return
            }
            
            sqlite3_exec(self.db, "commit", nil, nil, nil)
            self.setDBFileAttributes()
        }
    }
    
    func assetAdded(_ tx: BRTxRef, walletManager:WalletManager) {
        queue.async {
            //add asset
            let rvnTx = RvnTransaction(tx, walletManager: walletManager, kvStore: walletManager.kvStore, rate: walletManager.currency.state.currentRate)

            let assetRef = tx.pointee.asset!
            var assetName = assetRef.pointee.nameString
            if (AssetValidator.shared.IsAssetNameAnOwner(name: assetName)) {
                assetName = String(assetName.dropLast())
            }
            
            var req = ""
            let (isExiste, asset) = self.isAssetExiste(assetName: assetName)
            if isExiste {
                if (AssetValidator.shared.IsAssetNameAnOwner(name: assetRef.pointee.nameString)) {
                    if(rvnTx?.direction == .received){
                        req = String(format: "update ZBRAsset set Z_OWNERSHIP = 1 where Z_NAME = '%@'", assetName)
                    }
                    else{
                        req = String(format: "update ZBRAsset set Z_OWNERSHIP = 0 where Z_NAME = '%@'", assetName)
                    }
                }else {
                    switch assetRef.pointee.type {
                    case TRANSFER:
                        var amount = (asset?.amount.rawValue)!
                        if(rvnTx?.direction == .received){
                            amount = amount + UInt64(assetRef.pointee.amount)
                        }
                        else{
                            amount = amount - UInt64(assetRef.pointee.amount)
                        }
                        req = String(format: "update ZBRAsset set Z_AMOUNT = '%@' where Z_NAME = '%@'", String(amount), assetName)
                        break
                    case REISSUE:
                        let amount = UInt64(assetRef.pointee.amount) + (asset?.amount.rawValue)!
                        req = String(format: "update ZBRAsset set Z_AMOUNT = '%@', Z_UNITS = '%@', Z_REISSUBALE = '%@', Z_HAS_IPFS = '%@', Z_IPFS_HASH = '%@' where Z_NAME = '%@'", String(amount), assetRef.pointee.unit.description, assetRef.pointee.reissuable.description, assetRef.pointee.hasIPFS.description, assetRef.pointee.ipfsHashString, assetName)
                        break
                    case OWNER:
                        req = String(format: "update ZBRAsset set Z_OWNERSHIP = 1 where Z_NAME = '%@'", assetName)
                        break
                    case NEW_ASSET:
                        req = String(format: "update ZBRAsset set Z_AMOUNT = '%@', Z_UNITS = '%@', Z_REISSUBALE = '%@', Z_HAS_IPFS = '%@', Z_IPFS_HASH = '%@' where Z_NAME = '%@'", assetRef.pointee.amount.description, assetRef.pointee.unit.description, assetRef.pointee.reissuable.description, assetRef.pointee.hasIPFS.description, assetRef.pointee.ipfsHashString, assetName)
                        break
                    default:
                        break
                    }
                }
            }
            else //should add new asset
            {
                //count assets
                self.getAssetsCount()
                //add new asset
                var amount = assetRef.pointee.amount.description
                if (AssetValidator.shared.IsAssetNameAnOwner(name: assetRef.pointee.nameString)) {
                    //if name has ! should amount = 0
                    amount = "0"
                }
                req = String(format: "insert or rollback into ZBRAsset " +
                    "(Z_NAME, Z_AMOUNT, Z_UNITS, Z_REISSUBALE, Z_HAS_IPFS, Z_IPFS_HASH, Z_OWNERSHIP, Z_SORT) values ('%@', '%@', '%@', '%@', '%@', '%@', '%d', '%d')", assetName, amount, assetRef.pointee.unit.description, assetRef.pointee.reissuable.description, assetRef.pointee.hasIPFS.description, assetRef.pointee.ipfsHashString, assetRef.pointee.ownerShip, self.assetsCount)
            }
            var sql: OpaquePointer? = nil
            sqlite3_prepare_v2(self.db, req, -1, &sql, nil)
            defer { sqlite3_finalize(sql) }
            guard sqlite3_step(sql) == SQLITE_DONE else {
                print("BMEX database assetAdded error")
                print(String(cString: sqlite3_errmsg(self.db)))
                return
            }
            //commit querys
            sqlite3_exec(self.db, "commit", nil, nil, nil)
            self.setDBFileAttributes()
        }
    }
    
    func rejectAssetTx(_ assetRef: BRAssetRef) {
        queue.async {
            var assetName = assetRef.pointee.nameString
            if (AssetValidator.shared.IsAssetNameAnOwner(name: assetName)) {
                assetName = String(assetName.dropLast())
            }
            let (isExiste, asset) = self.isAssetExiste(assetName: assetName)
            if isExiste {
                var req = ""
                var amount = (asset?.amount.rawValue)!
                amount = amount + assetRef.pointee.amount
                req = String(format: "update ZBRAsset set Z_AMOUNT = '%@' where Z_NAME = '%@'", String(amount), assetName)
                var sql: OpaquePointer? = nil
                sqlite3_prepare_v2(self.db, req, -1, &sql, nil)
                defer { sqlite3_finalize(sql) }
                guard sqlite3_step(sql) == SQLITE_DONE else {
                    print(String(cString: sqlite3_errmsg(self.db)))
                    return
                }
                //commit querys
                sqlite3_exec(self.db, "commit", nil, nil, nil)
                self.setDBFileAttributes()
            }
        }
    }
    
    func updateAssetData(_ assetRef: BRAssetRef) {
        queue.async {
            //add asset
            var req = ""
            var assetName = assetRef.pointee.nameString
            req = String(format: "update ZBRAsset set Z_UNITS = '%@', Z_REISSUBALE = '%@', Z_HAS_IPFS = '%@', Z_IPFS_HASH = '%@' where Z_NAME = '%@'", assetRef.pointee.unit.description, assetRef.pointee.reissuable.description, assetRef.pointee.hasIPFS.description, assetRef.pointee.ipfsHashString, assetName)
            var sql: OpaquePointer? = nil
            sqlite3_prepare_v2(self.db, req, -1, &sql, nil)
            defer { sqlite3_finalize(sql) }
            guard sqlite3_step(sql) == SQLITE_DONE else {
                print(String(cString: sqlite3_errmsg(self.db)))
                return
            }
            //commit querys
            sqlite3_exec(self.db, "commit", nil, nil, nil)
            self.setDBFileAttributes()
        }
    }
    
    func isAssetExiste(assetName: String) -> (Bool, Asset?) {
        var asset:Asset?
        var isExiste = false
        var sql: OpaquePointer? = nil
        let req = String(format: "select * from ZBRAsset where Z_NAME = '%@'", assetName)
        sqlite3_prepare_v2(self.db, req, -1, &sql, nil)
        defer { sqlite3_finalize(sql) }
        
        while sqlite3_step(sql) == SQLITE_ROW {
            let idAsset = Int(sqlite3_column_int(sql, 0))
            let name = String(cString: sqlite3_column_text(sql, 1))
            let amount = UInt64(sqlite3_column_int64(sql, 2))
            let units = UInt8(sqlite3_column_int(sql, 3))
            let reissubale = UInt8(sqlite3_column_int(sql, 4))
            let hasIpfs = UInt8(sqlite3_column_int(sql, 5))
            let ipfsHash = String(cString: sqlite3_column_text(sql, 6))
            let ownerShip = Int(sqlite3_column_int(sql, 7))
            let hidden = Int(sqlite3_column_int(sql, 8))
            let sort = Int(sqlite3_column_int(sql, 9))
            
            asset = Asset(idAsset: idAsset, name: name, amount: Satoshis(amount), units: units, reissubale: reissubale, hasIpfs: hasIpfs, ipfsHash: ipfsHash, ownerShip: ownerShip, hidden: hidden, sort: sort)
            isExiste = true
            break
        }
        
        if sqlite3_errcode(self.db) != SQLITE_DONE {
            print(String(cString: sqlite3_errmsg(self.db)))
        }
        return(isExiste, asset)
    }
    
    func setDBFileAttributes() {
        queue.async {
            let files = [self.dbPath, self.dbPath + "-shm", self.dbPath + "-wal"]
            files.forEach {
                if FileManager.default.fileExists(atPath: $0) {
                    do {
                        try FileManager.default.setAttributes([FileAttributeKey.protectionKey: FileProtectionType.none], ofItemAtPath: $0)
                    } catch let e {
                        print("Set db attributes error: \(e)")
                    }
                }
            }
        }
    }
    
    func txUpdated(_ txHashes: [UInt256], blockHeight: UInt32, timestamp: UInt32) {
        queue.async {
            guard txHashes.count > 0 else { return }
            let timestamp = (timestamp > UInt32(NSTimeIntervalSince1970)) ? timestamp - UInt32(NSTimeIntervalSince1970) : 0
            var sql: OpaquePointer? = nil, sql2: OpaquePointer? = nil, count = 0
            sqlite3_prepare_v2(self.db, "select ZTXHASH, ZBLOB from ZBRTXMETADATAENTITY where ZTYPE = 1 and " +
                "ZTXHASH in (" + String(repeating: "?, ", count: txHashes.count - 1) + "?)", -1, &sql, nil)
            defer { sqlite3_finalize(sql) }
            
            for i in 0..<txHashes.count {
                sqlite3_bind_blob(sql, Int32(i + 1), [txHashes[i]], Int32(MemoryLayout<UInt256>.size), SQLITE_TRANSIENT)
                
            }
            
            sqlite3_prepare_v2(self.db, "update ZBRTXMETADATAENTITY set ZBLOB = ? where ZTXHASH = ?", -1, &sql2, nil)
            defer { sqlite3_finalize(sql2) }
            
            while sqlite3_step(sql) == SQLITE_ROW {
                let hash = sqlite3_column_blob(sql, 0)
                let buf = sqlite3_column_blob(sql, 1).assumingMemoryBound(to: UInt8.self)
                var blob = [UInt8](UnsafeBufferPointer(start: buf, count: Int(sqlite3_column_bytes(sql, 1))))
                
                [blockHeight.littleEndian, timestamp.littleEndian].withUnsafeBytes {
                    if blob.count > $0.count {
                        blob.replaceSubrange(blob.count - $0.count..<blob.count, with: $0)
                        sqlite3_bind_blob(sql2, 1, blob, Int32(blob.count), SQLITE_TRANSIENT)
                        sqlite3_bind_blob(sql2, 2, hash, Int32(MemoryLayout<UInt256>.size), SQLITE_TRANSIENT)
                        sqlite3_step(sql2)
                        sqlite3_reset(sql2)
                    }
                }
                
                count = count + 1
            }
            
            if sqlite3_errcode(self.db) != SQLITE_DONE { print(String(cString: sqlite3_errmsg(self.db))) }
            
            if count != txHashes.count {
                print("Fewer tx records updated than hashes! This causes tx to go missing!")
                exit(0) // DIE!
            }
        }
    }
    
    func txDeleted(_ txHash: UInt256, notifyUser: Bool, recommendRescan: Bool) {
        queue.async {
            var sql: OpaquePointer? = nil
            sqlite3_prepare_v2(self.db, "delete from ZBRTXMETADATAENTITY where ZTYPE = 1 and ZTXHASH = ?", -1, &sql, nil)
            defer { sqlite3_finalize(sql) }
            sqlite3_bind_blob(sql, 1, [txHash], Int32(MemoryLayout<UInt256>.size), SQLITE_TRANSIENT)
            
            guard sqlite3_step(sql) == SQLITE_DONE else {
                print(String(cString: sqlite3_errmsg(self.db)))
                return
            }
        }
    }
    
    func saveBlocks(_ replace: Bool, _ blockRefs: [BRBlockRef?]) {
        // make a copy before crossing thread boundary
        let blocks: [BRBlockRef?] = blockRefs.map { blockRef in
            if let b = blockRef {
                return BRMerkleBlockCopy(&b.pointee)
            } else {
                return nil
            }
        }
        queue.async {
            var pk: Int32 = 0
            sqlite3_exec(self.db, "begin exclusive", nil, nil, nil)
            
            if replace { // delete existing blocks and replace
                sqlite3_exec(self.db, "delete from ZBRMERKLEBLOCKENTITY", nil, nil, nil)
            }
            else { // add to existing blocks
                var sql: OpaquePointer? = nil
                sqlite3_prepare_v2(self.db, "select Z_MAX from Z_PRIMARYKEY where Z_ENT = \(self.blockEnt)", -1, &sql, nil)
                defer { sqlite3_finalize(sql) }
                
                guard sqlite3_step(sql) == SQLITE_ROW else {
                    print(String(cString: sqlite3_errmsg(self.db)))
                    sqlite3_exec(self.db, "rollback", nil, nil, nil)
                    return
                }
                
                pk = sqlite3_column_int(sql, 0) // get last primary key
            }
            
            var sql2: OpaquePointer? = nil
            sqlite3_prepare_v2(self.db, "insert or rollback into ZBRMERKLEBLOCKENTITY (Z_PK, Z_ENT, Z_OPT, ZHEIGHT, " +
                "ZNONCE, ZTARGET, ZTOTALTRANSACTIONS, ZVERSION, ZTIMESTAMP, ZBLOCKHASH, ZFLAGS, ZHASHES, " +
                "ZMERKLEROOT, ZPREVBLOCK) values (?, \(self.blockEnt), 1, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", -1, &sql2, nil)
            defer { sqlite3_finalize(sql2) }
            
            for b in blocks {
                guard let b = b else {
                    sqlite3_exec(self.db, "rollback", nil, nil, nil)
                    return
                }
                
                let timestampResult = Int32(bitPattern: b.pointee.timestamp).subtractingReportingOverflow(Int32(NSTimeIntervalSince1970))
                guard !timestampResult.1 else { print("skipped block with overflowed timestamp"); continue }
                
                let height = Int32(bitPattern: b.pointee.height)
                guard height != BLOCK_UNKNOWN_HEIGHT else {
                    print("skipped block with invalid blockheight: \(height)")
                    continue
                }
                
                pk = pk + 1
                sqlite3_bind_int(sql2, 1, pk)
                sqlite3_bind_int(sql2, 2, Int32(bitPattern: b.pointee.height))
                sqlite3_bind_int(sql2, 3, Int32(bitPattern: b.pointee.nonce))
                sqlite3_bind_int(sql2, 4, Int32(bitPattern: b.pointee.target))
                sqlite3_bind_int(sql2, 5, Int32(bitPattern: b.pointee.totalTx))
                sqlite3_bind_int(sql2, 6, Int32(bitPattern: b.pointee.version))
                sqlite3_bind_int(sql2, 7, timestampResult.0)
                sqlite3_bind_blob(sql2, 8, [b.pointee.blockHash], Int32(MemoryLayout<UInt256>.size), SQLITE_TRANSIENT)
                sqlite3_bind_blob(sql2, 9, [b.pointee.flags], Int32(b.pointee.flagsLen), SQLITE_TRANSIENT)
                sqlite3_bind_blob(sql2, 10, [b.pointee.hashes], Int32(MemoryLayout<UInt256>.size*b.pointee.hashesCount),
                                  SQLITE_TRANSIENT)
                sqlite3_bind_blob(sql2, 11, [b.pointee.merkleRoot], Int32(MemoryLayout<UInt256>.size), SQLITE_TRANSIENT)
                sqlite3_bind_blob(sql2, 12, [b.pointee.prevBlock], Int32(MemoryLayout<UInt256>.size), SQLITE_TRANSIENT)
                
                guard sqlite3_step(sql2) == SQLITE_DONE else {
                    print(String(cString: sqlite3_errmsg(self.db)))
                    return
                }
                
                sqlite3_reset(sql2)
                
                BRMerkleBlockFree(b)
            }
            
            sqlite3_exec(self.db, "update or rollback Z_PRIMARYKEY set Z_MAX = \(pk) where Z_ENT = \(self.blockEnt)",
                nil, nil, nil)
            
            guard sqlite3_errcode(self.db) == SQLITE_OK else {
                print(String(cString: sqlite3_errmsg(self.db)))
                return
            }
            
            sqlite3_exec(self.db, "commit", nil, nil, nil)
        }
    }
    
    func savePeers(_ replace: Bool, _ peers: [BRPeer]) {
        queue.async {
            var pk: Int32 = 0
            sqlite3_exec(self.db, "begin exclusive", nil, nil, nil)
            
            if replace { // delete existing peers and replace
                sqlite3_exec(self.db, "delete from ZBRPEERENTITY", nil, nil, nil)
            }
            else { // add to existing peers
                var sql: OpaquePointer? = nil
                sqlite3_prepare_v2(self.db, "select Z_MAX from Z_PRIMARYKEY where Z_ENT = \(self.peerEnt)", -1, &sql, nil)
                defer { sqlite3_finalize(sql) }
                
                guard sqlite3_step(sql) == SQLITE_ROW else {
                    print(String(cString: sqlite3_errmsg(self.db)))
                    sqlite3_exec(self.db, "rollback", nil, nil, nil)
                    return
                }
                
                pk = sqlite3_column_int(sql, 0) // get last primary key
            }
            
            var sql2: OpaquePointer? = nil
            sqlite3_prepare_v2(self.db, "insert or rollback into ZBRPEERENTITY " +
                "(Z_PK, Z_ENT, Z_OPT, ZADDRESS, ZMISBEHAVIN, ZPORT, ZSERVICES, ZTIMESTAMP) " +
                "values (?, \(self.peerEnt), 1, ?, 0, ?, ?, ?)", -1, &sql2, nil)
            defer { sqlite3_finalize(sql2) }
            
            for p in peers {
                pk = pk + 1
                sqlite3_bind_int(sql2, 1, pk)
                sqlite3_bind_int(sql2, 2, Int32(bitPattern: p.address.u32.3.bigEndian))
                sqlite3_bind_int(sql2, 3, Int32(p.port))
                sqlite3_bind_int64(sql2, 4, Int64(bitPattern: p.services))
                sqlite3_bind_int64(sql2, 5, Int64(bitPattern: p.timestamp) - Int64(NSTimeIntervalSince1970))
                
                guard sqlite3_step(sql2) == SQLITE_DONE else {
                    print(String(cString: sqlite3_errmsg(self.db)))
                    return
                }
                
                sqlite3_reset(sql2)
            }
            
            sqlite3_exec(self.db, "update or rollback Z_PRIMARYKEY set Z_MAX = \(pk) where Z_ENT = \(self.peerEnt)",
                nil, nil, nil)
            
            guard sqlite3_errcode(self.db) == SQLITE_OK else {
                print(String(cString: sqlite3_errmsg(self.db)))
                return
            }
            
            sqlite3_exec(self.db, "commit", nil, nil, nil)
        }
    }
    
    
    func loadTransactions(callback: @escaping ([BRTxRef?])->Void) {
        queue.async {
            var transactions = [BRTxRef?]()
            var sql: OpaquePointer? = nil
            sqlite3_prepare_v2(self.db, "select ZBLOB from ZBRTXMETADATAENTITY where ZTYPE = 1", -1, &sql, nil)
            defer { sqlite3_finalize(sql) }
            
            while sqlite3_step(sql) == SQLITE_ROW {
                let len = Int(sqlite3_column_bytes(sql, 0))
                let buf = sqlite3_column_blob(sql, 0).assumingMemoryBound(to: UInt8.self)
                guard len >= MemoryLayout<UInt32>.size*2 else { return DispatchQueue.main.async { callback(transactions) }}
                var off = len - MemoryLayout<UInt32>.size*2
                guard let tx = BRTransactionParse(buf, off) else { return DispatchQueue.main.async { callback(transactions) }}
                tx.pointee.blockHeight =
                    UnsafeRawPointer(buf).advanced(by: off).assumingMemoryBound(to: UInt32.self).pointee.littleEndian
                off = off + MemoryLayout<UInt32>.size
                let timestamp = UnsafeRawPointer(buf).advanced(by: off).assumingMemoryBound(to: UInt32.self).pointee.littleEndian
                tx.pointee.timestamp = (timestamp == 0) ? timestamp : timestamp + UInt32(NSTimeIntervalSince1970)
                transactions.append(tx)
            }
            
            if sqlite3_errcode(self.db) != SQLITE_DONE {
                print("BMEX database loadTransactions error")
                print(String(cString: sqlite3_errmsg(self.db)))
            }
            
            DispatchQueue.main.async {
                callback(transactions)
            }
        }
    }
    
    func loadBlocks(callback: @escaping ([BRBlockRef?])->Void) {
        queue.async {
            var blocks = [BRBlockRef?]()
            var sql: OpaquePointer? = nil
            sqlite3_prepare_v2(self.db, "select ZHEIGHT, ZNONCE, ZTARGET, ZTOTALTRANSACTIONS, ZVERSION, ZTIMESTAMP, " +
                "ZBLOCKHASH, ZFLAGS, ZHASHES, ZMERKLEROOT, ZPREVBLOCK from ZBRMERKLEBLOCKENTITY", -1, &sql, nil)
            defer { sqlite3_finalize(sql) }
            
            while sqlite3_step(sql) == SQLITE_ROW {
                guard let b = BRMerkleBlockNew() else { return DispatchQueue.main.async { callback(blocks) }}
                b.pointee.height = UInt32(bitPattern: sqlite3_column_int(sql, 0))
                guard b.pointee.height != BLOCK_UNKNOWN_HEIGHT else {
                    print("skipped invalid blockheight: \(sqlite3_column_int(sql, 0))")
                    continue
                }
                b.pointee.nonce = UInt32(bitPattern: sqlite3_column_int(sql, 1))
                b.pointee.target = UInt32(bitPattern: sqlite3_column_int(sql, 2))
                b.pointee.totalTx = UInt32(bitPattern: sqlite3_column_int(sql, 3))
                b.pointee.version = UInt32(bitPattern: sqlite3_column_int(sql, 4))
                let result = UInt32(bitPattern: sqlite3_column_int(sql, 5)).addingReportingOverflow(UInt32(NSTimeIntervalSince1970))
                if result.1 {
                    print("skipped overflowed timestamp: \(sqlite3_column_int(sql, 5))")
                    continue
                } else {
                    b.pointee.timestamp = result.0
                }
                b.pointee.blockHash = sqlite3_column_blob(sql, 6).assumingMemoryBound(to: UInt256.self).pointee
                
                let flags: UnsafePointer<UInt8>? = SafeSqlite3ColumnBlob(statement: sql!, iCol: 7)
                let flagsLen = Int(sqlite3_column_bytes(sql, 7))
                let hashes: UnsafePointer<UInt256>? = SafeSqlite3ColumnBlob(statement: sql!, iCol: 8)
                let hashesCount = Int(sqlite3_column_bytes(sql, 8))/MemoryLayout<UInt256>.size
                BRMerkleBlockSetTxHashes(b, hashes, hashesCount, flags, flagsLen)
                b.pointee.merkleRoot = sqlite3_column_blob(sql, 9).assumingMemoryBound(to: UInt256.self).pointee
                b.pointee.prevBlock = sqlite3_column_blob(sql, 10).assumingMemoryBound(to: UInt256.self).pointee
                blocks.append(b)
            }
            
            if sqlite3_errcode(self.db) != SQLITE_DONE { print(String(cString: sqlite3_errmsg(self.db))) }
            DispatchQueue.main.async {
                callback(blocks)
            }
        }
    }
    
    func loadPeers(callback: @escaping ([BRPeer])->Void) {
        queue.async {
            var peers = [BRPeer]()
            var sql: OpaquePointer? = nil
            sqlite3_prepare_v2(self.db, "select ZADDRESS, ZPORT, ZSERVICES, ZTIMESTAMP from ZBRPEERENTITY", -1, &sql, nil)
            defer { sqlite3_finalize(sql) }
            
            while sqlite3_step(sql) == SQLITE_ROW {
                var p = BRPeer()
                p.address = UInt128(u32: (0, 0, UInt32(0xffff).bigEndian,
                                          UInt32(bitPattern: sqlite3_column_int(sql, 0)).bigEndian))
                p.port = UInt16(truncatingIfNeeded: sqlite3_column_int(sql, 1))
                p.services = UInt64(bitPattern: sqlite3_column_int64(sql, 2))
                
                let result = UInt64(bitPattern: sqlite3_column_int64(sql, 3)).addingReportingOverflow(UInt64(NSTimeIntervalSince1970))
                if result.1 {
                    print("skipped overflowed timestamp: \(sqlite3_column_int64(sql, 3))")
                    continue
                } else {
                    p.timestamp = result.0
                    peers.append(p)
                }
            }
            
            if sqlite3_errcode(self.db) != SQLITE_DONE { print(String(cString: sqlite3_errmsg(self.db))) }
            DispatchQueue.main.async {
                callback(peers)
            }
        }
    }
    
    //Asset
    
    func loadAssets(callback: @escaping ([Asset])->Void) {
        queue.async {
            var assets = [Asset]()
            var sql: OpaquePointer? = nil
            sqlite3_prepare_v2(self.db, "select Z_ID, Z_NAME, Z_AMOUNT, Z_UNITS, Z_REISSUBALE, Z_HAS_IPFS, Z_IPFS_HASH, Z_OWNERSHIP, Z_ISHIDDEN, Z_SORT from ZBRAsset  where (Z_AMOUNT != 0 OR (Z_AMOUNT == 0 AND Z_OWNERSHIP = 1) ) ORDER BY Z_SORT DESC", -1, &sql, nil)
            defer { sqlite3_finalize(sql) }
            
            while sqlite3_step(sql) == SQLITE_ROW {
                let idAsset = Int(sqlite3_column_int(sql, 0))
                let name = String(cString: sqlite3_column_text(sql, 1))
                let amount = UInt64(sqlite3_column_int64(sql, 2))
                let units = UInt8(sqlite3_column_int(sql, 3))
                let reissubale = UInt8(sqlite3_column_int(sql, 4))
                let hasIpfs = UInt8(sqlite3_column_int(sql, 5))
                let ipfsHash = String(cString: sqlite3_column_text(sql, 6))
                let ownerShip = Int(sqlite3_column_int(sql, 7))
                let hidden = Int(sqlite3_column_int(sql, 8))
                let sort = Int(sqlite3_column_int(sql, 9))
                
                let p = Asset(idAsset: idAsset, name: name, amount: Satoshis(amount), units: units, reissubale: reissubale, hasIpfs: hasIpfs, ipfsHash: ipfsHash, ownerShip: ownerShip, hidden: hidden, sort: sort)
                assets.append(p)
            }
            
            if sqlite3_errcode(self.db) != SQLITE_DONE {
                print("BMEX database loadAsset error")
                print(String(cString: sqlite3_errmsg(self.db)))
            }
            DispatchQueue.main.async {
                callback(assets)
            }
        }
    }
    
    func getAssetsCount() {
        var sql: OpaquePointer? = nil
        sqlite3_prepare_v2(self.db, "SELECT count() from ZBRAsset", -1, &sql, nil)
        defer { sqlite3_finalize(sql) }
        
        while sqlite3_step(sql) == SQLITE_ROW {
            self.assetsCount = Int(sqlite3_column_int(sql, 0))
        }
        
        if sqlite3_errcode(self.db) != SQLITE_DONE {
            print(String(cString: sqlite3_errmsg(self.db)))
        }
    }
    
    func updateSortAsset(_ newValue: Asset, where idOldValue:Int, callback: ((Bool)->Void)? = nil)
    {
        print("SORT name:", newValue.name, " sort: ", newValue.sort)
        queue.async {
            var sql: OpaquePointer? = nil
            let req = String(format: "update ZBRAsset set Z_SORT = %d where Z_ID = %d", newValue.sort, idOldValue)
            sqlite3_prepare_v2(self.db, req, -1, &sql, nil)
            defer { sqlite3_finalize(sql) }
            guard sqlite3_step(sql) == SQLITE_DONE else {
                print(String(cString: sqlite3_errmsg(self.db)))
                if callback != nil{
                    callback!(false)
                }
                return
            }
            if callback != nil{
                callback!(false)
            }
        }
    }
    
    func updateHideAsset(_ newValue: Asset, where idOldValue:Int, callback: ((Bool)->Void)? = nil)
    {
        queue.async {
            var sql: OpaquePointer? = nil
            let req = String(format: "update ZBRAsset set Z_ISHIDDEN = %d where Z_ID = %d", newValue.hidden, idOldValue)
            sqlite3_prepare_v2(self.db, req, -1, &sql, nil)
            defer { sqlite3_finalize(sql) }
            guard sqlite3_step(sql) == SQLITE_DONE else {
                print(String(cString: sqlite3_errmsg(self.db)))
                if callback != nil{
                    callback!(false)
                }
                return
            }
            if callback != nil{
                callback!(false)
            }
        }
    }
    
    func isAssetNameExiste(name:String, callback: @escaping (AssetName?, Bool)->Void) {
        queue.async {
            var isExiste = false
            var assetName:AssetName?
            var sql: OpaquePointer? = nil
            let req = String(format: "select * from ZBRAsset_NAME where Z_ASSET_NAME = '%@'", name)
            sqlite3_prepare_v2(self.db, req, -1, &sql, nil)
            defer { sqlite3_finalize(sql) }
            
            while sqlite3_step(sql) == SQLITE_ROW {
                let idAsset = Int(sqlite3_column_int(sql, 0))
                let name = String(cString: sqlite3_column_text(sql, 1))
                let ipfsHash = String(cString: sqlite3_column_text(sql, 2))
                let txHash = String(cString: sqlite3_column_text(sql, 3))
                let address = String(cString: sqlite3_column_text(sql, 4))
                let timeSpan = Int(sqlite3_column_int(sql, 5))
                assetName = AssetName(idAsset: idAsset, name: name, ipfsHash: ipfsHash, txHash: txHash, address: address, timespan: timeSpan)
                isExiste = true
            }
            
            if sqlite3_errcode(self.db) != SQLITE_DONE {
                print(String(cString: sqlite3_errmsg(self.db)))
            }
            DispatchQueue.main.async {
                callback(assetName, isExiste)
            }
        }
    }
    
    //AddressBook
    func loadAddressBook(callback: @escaping ([AddressBook])->Void) {
        queue.async {
            var addresses = [AddressBook]()
            var sql: OpaquePointer? = nil
            sqlite3_prepare_v2(self.db, "select Z_NAME, Z_ADDRESS from ZBRADDRESSBOOK", -1, &sql, nil)
            defer { sqlite3_finalize(sql) }
            
            while sqlite3_step(sql) == SQLITE_ROW {
                let name = String(cString: sqlite3_column_text(sql, 0))
                let address = String(cString: sqlite3_column_text(sql, 1))
                let p = AddressBook(name: name, address: address)
                addresses.append(p)
            }
            
            if sqlite3_errcode(self.db) != SQLITE_DONE {
                print(String(cString: sqlite3_errmsg(self.db)))
            }
            DispatchQueue.main.async {
                callback(addresses)
            }
        }
    }
    
    func isAddressBookExiste(address:String, callback: @escaping (AddressBook?, Bool)->Void) {
        queue.async {
            var isExiste = false
            var addressBook:AddressBook?
            var sql: OpaquePointer? = nil
            let req = String(format: "select Z_NAME, Z_ADDRESS from ZBRADDRESSBOOK where Z_ADDRESS = '%@'", address)
            sqlite3_prepare_v2(self.db, req, -1, &sql, nil)
            defer { sqlite3_finalize(sql) }
            
            while sqlite3_step(sql) == SQLITE_ROW {
                let name = String(cString: sqlite3_column_text(sql, 0))
                let address = String(cString: sqlite3_column_text(sql, 1))
                addressBook = AddressBook(name: name, address: address)
                isExiste = true
            }
            
            if sqlite3_errcode(self.db) != SQLITE_DONE {
                print(String(cString: sqlite3_errmsg(self.db)))
            }
            DispatchQueue.main.async {
                callback(addressBook, isExiste)
            }
        }
    }
    
    func addressBookAdded(_ newValue: AddressBook, callback: @escaping (Bool)->Void)
    {
        queue.async {
            var sql: OpaquePointer? = nil
            let req = String(format: "insert into ZBRADDRESSBOOK (Z_NAME, Z_ADDRESS) values ('%@', '%@')", newValue.name, newValue.address)
            sqlite3_prepare_v2(self.db, req, -1, &sql, nil)
            defer { sqlite3_finalize(sql) }
            guard sqlite3_step(sql) == SQLITE_DONE else {
                print(String(cString: sqlite3_errmsg(self.db)))
                callback(false)
                return
            }
            callback(true)
        }
    }
    
    func updateAddressBook(_ newValue: AddressBook, where oldValue:String, callback: @escaping (Bool)->Void)
    {
        queue.async {
            var sql: OpaquePointer? = nil
            let req = String(format: "update ZBRADDRESSBOOK set Z_NAME = '%@', Z_ADDRESS = '%@' where Z_ADDRESS = '%@'", newValue.name, newValue.address, oldValue)
            sqlite3_prepare_v2(self.db, req, -1, &sql, nil)
            defer { sqlite3_finalize(sql) }
            guard sqlite3_step(sql) == SQLITE_DONE else {
                print(String(cString: sqlite3_errmsg(self.db)))
                callback(false)
                return
            }
            callback(true)
        }
    }
    
    func deleteAddressBook(_ address: String, callback: @escaping (Bool)->Void)
    {
        queue.async {
            var sql: OpaquePointer? = nil
            let req = String(format: "delete from ZBRADDRESSBOOK where Z_ADDRESS = '%@'", address)
            sqlite3_prepare_v2(self.db, req, -1, &sql, nil)
            defer { sqlite3_finalize(sql) }
            guard sqlite3_step(sql) == SQLITE_DONE else {
                print(String(cString: sqlite3_errmsg(self.db)))
                callback(false)
                return
            }
            callback(true)
        }
    }
    
}
