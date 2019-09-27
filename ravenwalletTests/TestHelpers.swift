//
//  TestHelpers.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2017-02-26.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import Foundation
import XCTest
@testable import Ravencoin

func clearKeychain() {
    let classes = [kSecClassGenericPassword as String,
                   kSecClassInternetPassword as String,
                   kSecClassCertificate as String,
                   kSecClassKey as String,
                   kSecClassIdentity as String]
    classes.forEach { className in
        SecItemDelete([kSecClass as String: className]  as CFDictionary)
    }
}

func initWallet(walletManager: WalletManager) {
    initWallet(walletManager: walletManager, callback: {
    })
}

func initWallet(walletManager: WalletManager, callback: @escaping (() -> Void)) {
    //guard walletManager.wallet == nil else { return }
    walletManager.initWallet { success in
        guard success else {
            return
        }
        walletManager.initPeerManager {
            walletManager.peerManager?.connect()
            let connectionStatus = walletManager.peerManager?.connectionStatus.description
            print("BMEX ", connectionStatus)
            callback()
        }
    }
}
