//
//  Sender.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2017-01-16.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import Foundation
import UIKit
import Core

enum SendAssetResult {
    case success
    case creationError(String)
    case publishFailure(BRPeerManagerError)
}

private let protocolPaymentTimeout: TimeInterval = 20.0

class SenderAsset {

    init(walletManager: WalletManager, currency: CurrencyDef, operationType: OperationType) {
        self.walletManager = walletManager
        self.currency = currency
        self.operationType = operationType
    }

    private let walletManager: WalletManager
    private let currency: CurrencyDef
    var transaction: BRTxRef?
    var protocolRequest: PaymentProtocolRequest?
    var rate: Rate?
    var comment: String?
    var feePerKb: UInt64?
    var operationType: OperationType

    func createAssetTransaction(amount: UInt64, to: String, asset: BRAssetRef) -> Bool {
        switch operationType {
        case .transferAsset:
            transaction = walletManager.wallet?.createAssetTransaction(forAmount: amount, toAddress: to, asset: asset)
            break
        case .transferOwnerShipAsset:
            transaction = walletManager.wallet?.createAssetTransactionOwnerShip(forAmount: amount, toAddress: to, asset: asset)
            break
        case .burnAsset:
            transaction = walletManager.wallet?.burnAssetTransaction(asset: asset)
            break
        case .createAsset:
            transaction = walletManager.wallet?.createTxForRootAssetCreation(forAmount: amount, toAddress: to, asset: asset)
            break
        case .manageAsset:
            transaction = nil
            break
        case .transferRvn: //never called in this class
            transaction = nil
            break
        }
        return transaction != nil
    }

    func createTransaction(forPaymentProtocol: PaymentProtocolRequest) {
        protocolRequest = forPaymentProtocol
        transaction = walletManager.wallet?.createTxForOutputs(forPaymentProtocol.details.outputs)
    }

    var fee: UInt64 {
        guard let tx = transaction else { return 0 }
        return walletManager.wallet?.feeForTx(tx) ?? 0
    }

    var canUseBiometrics: Bool {
        guard let tx = transaction else  { return false }
        return walletManager.canUseBiometrics(forTx: tx)
    }

    func feeForTx(amount: UInt64) -> UInt64? {
        let fee = walletManager.wallet?.feeForTx(amount:amount)
        return fee == 0 ? nil : fee
    }
    
    func send(biometricsMessage: String, rate: Rate?, comment: String?, feePerKb: UInt64, verifyPinFunction: @escaping (@escaping(String) -> Void) -> Void, completion:@escaping (SendResult) -> Void) {
        guard let tx = transaction else { return completion(.creationError(S.Send.createTransactionError)) }
        
        self.rate = rate
        self.comment = comment
        self.feePerKb = feePerKb
        
        if UserDefaults.isBiometricsEnabled && walletManager.canUseBiometrics(forTx:tx) {
            DispatchQueue.walletQueue.async { [weak self] in
                guard let myself = self else { return }
                myself.walletManager.signTransaction(tx, forkId: (myself.currency as! Raven).forkId, biometricsPrompt: biometricsMessage, completion: { result in
                    if result == .success {
                        myself.publish(completion: completion)
                    } else {
                        if result == .failure || result == .fallback {
                            myself.verifyPin(tx: tx, verifyPinFunction: verifyPinFunction, completion: completion)
                        }
                    }
                })
            }
        } else {
            self.verifyPin(tx: tx, verifyPinFunction: verifyPinFunction, completion: completion)
        }
    }
    
    private func verifyPin(tx: BRTxRef,
                           verifyPinFunction: (@escaping(String) -> Void) -> Void,
                           completion:@escaping (SendResult) -> Void) {
        verifyPinFunction({ pin in
            let group = DispatchGroup()
            group.enter()
            DispatchQueue.walletQueue.async {
                if self.walletManager.signTransaction(tx, forkId: (self.currency as! Raven).forkId, pin: pin) {
                    self.publish(completion: completion)
                }
                group.leave()
            }
            let result = group.wait(timeout: .now() + 4.0)
            if result == .timedOut {
                fatalError("send-tx-timeout")
            }
        })
    }
    
    private func publish(completion: @escaping (SendResult) -> Void) {
        guard let tx = transaction else { assert(false, "publish failure"); return }
        DispatchQueue.walletQueue.async { [weak self] in
            guard let myself = self else { assert(false, "myelf didn't exist"); return }
            myself.walletManager.peerManager?.publishTx(tx, completion: { success, error in
                DispatchQueue.main.async {
                    if let error = error {
                        completion(.publishFailure(error))
                    } else {
                        myself.setMetaData()
                        completion(.success)
                    }
                }
            })
        }
    }
    
    private func setMetaData() {
        guard let rate = rate, let tx = transaction, let feePerKb = feePerKb else { print("Incomplete tx metadata"); return }
        let metaData = TxMetaData(transaction: tx.pointee,
                                  exchangeRate: rate.rate,
                                  exchangeRateCurrency: rate.code,
                                  feeRate: Double(feePerKb),
                                  deviceId: UserDefaults.standard.deviceID,
                                  comment: comment)
        Store.trigger(name: .txMemoUpdated(tx.pointee.txHash.description))
    }
}
