//
//  Transaction.swift
//  ravenwallet
//
//  Created by Ehsan Rezaie on 2018-01-13.
//  Copyright © 2018 breadwallet LLC. All rights reserved.
//

import Foundation

/// Transacton status
enum TransactionStatus {
    /// Zero confirmations
    case pending
    /// One or more confirmations
    case confirmed
    /// Sufficient confirmations to deem complete (coin-specific)
    case complete
    /// Invalid / error
    case invalid
}

/// Coin-agnostic transaction model wrapper
protocol Transaction {
    var currency: CurrencyDef { get }
    var hash: String { get }
    var blockHeight: UInt64 { get }
    var confirmations: UInt64 { get }
    var status: TransactionStatus { get }
    var direction: TransactionDirection { get }
    var timestamp: TimeInterval { get }
    var toAddress: String { get }
    
    var isPending: Bool { get }
    var isValid: Bool { get }
}

// MARK: Default Values
extension Transaction {
    var isPending: Bool {
        return status == .pending
    }
}

// MARK: - Equatable support

extension Equatable where Self: Transaction {}

func ==(lhs: Transaction, rhs: Transaction) -> Bool {
    return lhs.hash == rhs.hash &&
        lhs.status == rhs.status
}

func ==(lhs: [Transaction], rhs: [Transaction]) -> Bool {
    return lhs.elementsEqual(rhs, by: ==)
}

func !=(lhs: [Transaction], rhs: [Transaction]) -> Bool {
    return !lhs.elementsEqual(rhs, by: ==)
}
