//
//  TransferAssetTest.swift
//  RavencoinTests
//
//  Created by Ben on 2/11/19.
//  Copyright © 2019 Medici Ventures. All rights reserved.
//

import XCTest
@testable import Ravencoin
@testable import Core

class TransferAssetTest: XCTestCase {

    private var walletManager: WalletManager?
    private let pin = "00000"

    override func setUp() {
        walletManager = try! WalletManager(currency: Currencies.rvn, dbPath: Currencies.rvn.dbPath)
        let _ = walletManager?.setSeedPhrase("cart ten dose alcohol alley dice olympic harbor runway error insect cage")
        initWallet(walletManager: walletManager!)
    }

    override func tearDown() {
        super.tearDown()
    }

    func sendAsset() {
        let sender = SenderAsset(walletManager: self.walletManager!, currency: Currencies.rvn, operationType: .transferAsset)
        let asset = Asset.init(idAsset: 0, name: "TIANOJP", amount: Satoshis.init(1), units: 5, reissubale: 1, hasIpfs: 0, ipfsHash: "", ownerShip: 1, hidden: 1, sort: 1)
        let amount = Satoshis.init(1)
        let assetToSend: BRAssetRef = BRAsset.createAssetRef(asset: asset, type: TRANSFER, amount: amount)
        
        if !sender.createAssetTransaction(amount: 0, to: "mm8pvHnQn1jM5NjJ6XoJ3XeQfG2RwCQLB9", asset: assetToSend) {
            print("createAssetTransaction error")
        }
        
        walletManager!.signTransaction(sender.transaction!, forkId: (walletManager?.currency as! Raven).forkId, biometricsPrompt: S.VerifyPin.touchIdMessage, completion: { result in
            if result == .success {
                self.walletManager!.peerManager?.publishTx(sender.transaction!, completion: { success, error in
                    if error != nil {
                        print("tx error")
                    } else {
                        print("tx success")
                    }
                })
            }
        })
        
        XCTAssertTrue(UserDefaults.defaultCurrencyCode == "CAD", "Actions should persist new value")

    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        sendAsset()
        //self.measure {
            // Put the code you want to measure the time of here.
        //}
    }

}
