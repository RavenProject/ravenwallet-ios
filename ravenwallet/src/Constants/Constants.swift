//
//  Constants.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2016-10-24.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit
import Core

let π: CGFloat = .pi

struct Padding {
    subscript(multiplier: Int) -> CGFloat {
        get {
            return CGFloat(multiplier) * 8.0
        }
    }
}

struct C {
    static let padding = Padding()
    struct Sizes {
        static let buttonHeight: CGFloat = 48.0
        static let headerHeight: CGFloat = 48.0
        static let largeHeaderHeight: CGFloat = 220.0
        static let logoAspectRatio: CGFloat = 125.0/417.0
        static let roundedCornerRadius: CGFloat = 6.0
    }
    static var defaultTintColor: UIColor = {
        return UIView().tintColor
    }()
    static let animationDuration: TimeInterval = 0.3
    static let secondsInDay: TimeInterval = 86400
    static let maxMoney: UInt64 = 21000000000*100000000
    static let maxAsset: UInt64 = 21000000000*100000000
    static let satoshis: UInt64 = 100000000
    // TODO Ravenize: check if it can be changed without affecting anything
    static let walletQueue = "com.breadwallet.walletqueue"
    static let rvnCurrencyCode = "RVN"
    static let null = "(null)"
    static let maxMemoLength = 250
    static let feedbackEmail = "feedback@ravenwallet.org"
    static let iosEmail = "ios@ravenwallet.org"
    static let reviewLink = "https://itunes.apple.com/us/app/rvn-wallet/id1371751946?action=write-review"
    
    static var standardPort: Int {
        return E.isTestnet ? 18770 : 8767
    }
    static let feeCacheTimeout: TimeInterval = C.secondsInDay*3
    
    // TODO: Remove bCash
    static let bCashForkBlockHeight: UInt32 = E.isTestnet ? 1155876 : 478559
    static let bCashForkTimeStamp: TimeInterval = E.isTestnet ? (1501597117 - NSTimeIntervalSince1970) : (1501568580 - NSTimeIntervalSince1970)
    static let txUnconfirmedHeight = Int32.max
    static var logFilePath: URL {
        let cachesDirectory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
        return URL(fileURLWithPath: cachesDirectory).appendingPathComponent("log.txt")
    }
    
    //Asset
    static let OWNER_TAG = "!"
    
    //Asset Fee
    static let creatAssetFee = UInt64(Int(500) * 100000000)
    static let manageAssetFee = UInt64(Int(100) * 100000000)
    static let ownerShipAsset = UInt64(Int(1) * 100000000)
    static let uniqueAsset = UInt64(Int(1) * 100000000)
    static let subAssetFee = UInt64(Int(100) * 100000000)
    static let uniqueAssetFee = UInt64(Int(5) * 100000000)
    static let oneAsset = UInt64(Int(1) * 100000000)

    //Burn Addresses
    static var strIssueAssetBurnAddress: String {
        return E.isTestnet ? "n1issueAssetXXXXXXXXXXXXXXXXWdnemQ" : "RXissueAssetXXXXXXXXXXXXXXXXXhhZGt"
    }
    static var strReissueAssetBurnAddress: String {
        return E.isTestnet ? "n1ReissueAssetXXXXXXXXXXXXXXWG9NLd" : "RXReissueAssetXXXXXXXXXXXXXXVEFAWu"
    }
    static var strIssueSubAssetBurnAddress: String {
        return E.isTestnet ? "n1issueSubAssetXXXXXXXXXXXXXbNiH6v" : "RXissueSubAssetXXXXXXXXXXXXXWcwhwL"
    }
    static var strIssueUniqueAssetBurnAddress: String {
        return E.isTestnet ? "n1issueUniqueAssetXXXXXXXXXXS4695i" : "RXissueUniqueAssetXXXXXXXXXXWEAe58"
    }
    static var strGlobalBurnAddress: String {
        return E.isTestnet ? "n1BurnXXXXXXXXXXXXXXXXXXXXXXU1qejP" : "RXBurnXXXXXXXXXXXXXXXXXXXXXXWUo9FV"
    }
    
    static var setBurnAddresses: Set = Set.init(arrayLiteral: strIssueAssetBurnAddress, strReissueAssetBurnAddress, strIssueSubAssetBurnAddress, strIssueUniqueAssetBurnAddress, strGlobalBurnAddress)
    
    //TX confirmation numbers
    struct Blocks {
        static let unconfirmed: UInt64 = 0
        static let pendingStart: UInt64 = 1
        static let pendingEnd: UInt64 = 6
    }
    
    static let diffBlocks:Int = 100
    
    //ipfs URL
    static let ipfsHost = "http://ipfs.io/ipfs/"
    
    //AddressBook
    static let MAX_ADDRESSBOOK_NAME_LENGTH = 30;
    
    
    //fetch Utxos urls
    static var fetchRvnUtxosPath: String {
        return E.isTestnet ? "https://vinx.mediciventures.com/api/addr/%@/utxo" : "https://api.ravencoin.com/api/addr/%@/utxo"
        //return E.isTestnet ? "https://testnet.ravencoin.network/api/addrs/utxo" : "https://ravencoin.network/api/addrs/utxo"
    }
    
    static var fetchAssetUtxosPath:String {
        return E.isTestnet ? "https://vinx.mediciventures.com/api/addr/%@/asset/*/utxo" : "https://vinx.mediciventures.com/api/addr/%@/asset/*/utxo"
    }
    
    static var fetchTxsPath:String {
        return E.isTestnet ? "https://vinx.mediciventures.com/api/addr/%@" : "https://api.ravencoin.com/api/addr/%@"
    }
    
}
