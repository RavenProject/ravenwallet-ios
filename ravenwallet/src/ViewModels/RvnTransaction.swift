//
//  BtcTransaction.swift
//  ravenwallet
//
//  Created by Ehsan Rezaie on 2018-01-12.
//  Copyright © 2018 breadwallet LLC. All rights reserved.
//

import Foundation
import Core

/// Wrapper for BTC transaction model + metadata
struct RvnTransaction: Transaction {
    
    // MARK: Transaction Properties
    
    let currency: CurrencyDef
    let hash: String
    let status: TransactionStatus
    let direction: TransactionDirection
    let toAddress: String
    let timestamp: TimeInterval
    let blockHeight: UInt64
    let confirmations: UInt64
    let isValid: Bool
    let asset: BRAssetRef?
    
    // MARK: BTC-specific properties
    
    var rawTransaction: BRTransaction? {
        return tx.pointee
    }
    
    let amount: UInt64
    let fee: UInt64
    let startingBalance: UInt64
    let endingBalance: UInt64
    
    // MARK: Private
    
    private let tx: BRTxRef
    
    // MARK: - Init
    
    init?(_ tx: BRTxRef, walletManager: WalletManager, rate: Rate?) {
        guard let wallet = walletManager.wallet,
            let peerManager = walletManager.peerManager else { return nil }
        self.currency = walletManager.currency
        self.tx = tx
        
        let amountReceived = wallet.amountReceivedFromTx(tx)
        let amountSent = wallet.amountSentByTx(tx)
        
        let fee = wallet.feeForTx(tx) ?? 0
        self.fee = fee
        
        // addresses from outputs
        let myAddress = tx.outputs.filter({ output in
            wallet.containsAddress(output.swiftAddress)
        }).first?.swiftAddress ?? ""
        let otherAddress = tx.outputs.filter({ output in
            !wallet.containsAddress(output.swiftAddress)
        }).first?.swiftAddress ?? ""
        
        // direction
        var direction: TransactionDirection
        if (tx.pointee.asset == nil) && amountSent > 0 && (amountReceived + fee) == amountSent {
            direction = .moved
        } else if amountSent > 0 {
            direction = .sent
        } else {
            direction = .received
        }
        self.direction = direction
        
        let endingBalance: UInt64 = wallet.balanceAfterTx(tx)
        var startingBalance: UInt64
        var address: String
        switch direction {
        case .received:
            address = myAddress
            amount = amountReceived
            startingBalance = endingBalance.subtractingReportingOverflow(amount).0.subtractingReportingOverflow(fee).0
        case .sent:
            address = otherAddress
            amount = amountSent - amountReceived - fee
            startingBalance = endingBalance.addingReportingOverflow(amount).0.addingReportingOverflow(fee).0
        case .moved:
            address = myAddress
            amount = amountSent
            startingBalance = endingBalance.addingReportingOverflow(self.fee).0
        }
        self.startingBalance = startingBalance
        self.endingBalance = endingBalance
        
        toAddress = address
        
        hash = tx.pointee.txHash.description
        timestamp = TimeInterval(tx.pointee.timestamp)
        isValid = wallet.transactionIsValid(tx)
        blockHeight = (tx.pointee.blockHeight == UInt32.max) ? UInt64.max :  UInt64(tx.pointee.blockHeight)
        
        let lastBlockHeight = UInt64(peerManager.lastBlockHeight)
        confirmations = blockHeight > lastBlockHeight
            ? 0
            : (lastBlockHeight - blockHeight) + 1
        
        if isValid {
            switch confirmations {
            case C.Blocks.unconfirmed:
                status = .pending
            case C.Blocks.pendingStart..<C.Blocks.pendingEnd:
                status = .confirmed
            default:
                status = .complete
            }
        } else {
            status = .invalid
        }
        
        //Asset
        asset = tx.pointee.asset
    }
    
}
