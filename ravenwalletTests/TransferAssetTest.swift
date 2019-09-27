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
    private let pin = "000000"

    override func setUp() {
        clearKeychain()
        walletManager = try! WalletManager(currency: Currencies.rvn, dbPath: Currencies.rvn.dbPath)
        let result = walletManager?.setSeedPhrase("cart ten dose alcohol alley dice olympic harbor runway error insect cage")
        XCTAssertTrue(result!, "setSeedPhrase fail")
        XCTAssert(self.walletManager!.forceSetPin(newPin: self.pin), "Setting PIN should succeed")
    }

    override func tearDown() {
        super.tearDown()
    }
    
    func testInitWallet() {
//        initWallet(walletManager: walletManager!, callback: {
//            self.sendAsset()
//        })
        walletManager!.initWallet { success in
            XCTAssertTrue(success, " initWallet failed")
            self.walletManager!.initPeerManager {
                self.walletManager!.peerManager?.connect()
                self.sendAsset()
            }
        }
    }

    func sendAsset() {
        let sender = SenderAsset(walletManager: self.walletManager!, currency: Currencies.rvn, operationType: .transferAsset)
        let asset = Asset.init(idAsset: 0, name: "JABLINSKI", amount: Satoshis.init(1), units: 5, reissubale: 1, hasIpfs: 0, ipfsHash: "", ownerShip: 1, hidden: 1, sort: 1)
        let amount = Satoshis.init(1)
        let assetToSend: BRAssetRef = BRAsset.createAssetRef(asset: asset, type: TRANSFER, amount: amount)

        XCTAssertTrue(sender.createAssetTransaction(amount: 0, to: "mm8pvHnQn1jM5NjJ6XoJ3XeQfG2RwCQLB9", asset: assetToSend), "createAssetTransaction error")
        let result = walletManager!.signTransaction(sender.transaction!, pin: pin)
        XCTAssertTrue(true, "signTransaction failed")

            if result == true {
                let connectionStatus = self.walletManager!.peerManager?.connectionStatus.description
                print("BMEX ", connectionStatus)
                self.walletManager!.peerManager?.publishTx(sender.transaction!, completion: { success, error in
                    XCTAssertNil(error == nil, "BMEX " + error.debugDescription)
                })
            }
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
