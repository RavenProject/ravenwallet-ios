//
//  BitIdTests.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2017-06-01.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import XCTest
@testable import Ravencoin

class BitIdTests : XCTestCase {

    private let walletManager: WalletManager = try! WalletManager(currency: Currencies.rvn, dbPath: nil)

    override func setUp() {
        super.setUp()
        clearKeychain()
        guard walletManager.noWallet else { XCTFail("Wallet should not exist"); return }
        guard walletManager.setSeedPhrase("famous gesture ladder armor must taste afraid search stove panda grab deer") else { XCTFail("Setting seed should work"); return  }
    }

    override func tearDown() {
        super.tearDown()
        clearKeychain()
    }

}
