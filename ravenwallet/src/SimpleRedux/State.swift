//
//  State.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2016-10-24.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit
import Core

private let maxFeePerKB: UInt64 = ((1000100*1000 + 190)/191)

struct State {
    let isStartFlowVisible: Bool
    let isLoginRequired: Bool
    let rootModal: RootModal
    let isSwapped: Bool //move to CurrencyState
    let alert: AlertType
    let isBiometricsEnabled: Bool
    let defaultCurrencyCode: String
    let isPushNotificationsEnabled: Bool
    let isPromptingBiometrics: Bool
    let pinLength: Int
    let wallets: [String: WalletState]
    
    subscript(currency: CurrencyDef) -> WalletState {
        guard let walletState = wallets[currency.code] else {
            // this should never happen as long as all currencies in use are initialized in State.initial
            fatalError("unsupported currency!")
        }
        return walletState
    }
    
    var orderedWallets: [WalletState] {
        return wallets.values.sorted(by: { $0.displayOrder < $1.displayOrder })
    }
    
    var currencies: [CurrencyDef] {
        return orderedWallets.map { $0.currency }
    }
    
    var primaryWallet: WalletState {
        return wallets[Currencies.rvn.code]!
    }
}

extension State {
    static var initial: State {
        return State(   isStartFlowVisible: false,
                        isLoginRequired: true,
                        rootModal: .none,
                        isSwapped: UserDefaults.isBtcSwapped,
                        alert: .none,
                        isBiometricsEnabled: UserDefaults.isBiometricsEnabled,
                        defaultCurrencyCode: UserDefaults.defaultCurrencyCode,
                        isPushNotificationsEnabled: UserDefaults.pushToken != nil,
                        isPromptingBiometrics: false,
                        pinLength: 6,
                        wallets: [Currencies.rvn.code: WalletState.initial(Currencies.rvn, displayOrder: 0)])
    }
    
    func mutate(   isStartFlowVisible: Bool? = nil,
                   isLoginRequired: Bool? = nil,
                   rootModal: RootModal? = nil,
                   isBtcSwapped: Bool? = nil,
                   alert: AlertType? = nil,
                   isBiometricsEnabled: Bool? = nil,
                   defaultCurrencyCode: String? = nil,
                   isPushNotificationsEnabled: Bool? = nil,
                   isPromptingBiometrics: Bool? = nil,
                   pinLength: Int? = nil,
                   wallets: [String: WalletState]? = nil) -> State {
        return State(isStartFlowVisible: isStartFlowVisible ?? self.isStartFlowVisible,
                     isLoginRequired: isLoginRequired ?? self.isLoginRequired,
                     rootModal: rootModal ?? self.rootModal,
                     isSwapped: isBtcSwapped ?? self.isSwapped,
                     alert: alert ?? self.alert,
                     isBiometricsEnabled: isBiometricsEnabled ?? self.isBiometricsEnabled,
                     defaultCurrencyCode: defaultCurrencyCode ?? self.defaultCurrencyCode,
                     isPushNotificationsEnabled: isPushNotificationsEnabled ?? self.isPushNotificationsEnabled,
                     isPromptingBiometrics: isPromptingBiometrics ?? self.isPromptingBiometrics,
                     pinLength: pinLength ?? self.pinLength,
                     wallets: wallets ?? self.wallets)
    }
    
    func mutate(walletState: WalletState) -> State {
        var wallets = self.wallets
        wallets[walletState.currency.code] = walletState
        return mutate(wallets: wallets)
    }
}

// MARK: -

enum RootModal {
    case none
    case send(currency: CurrencyDef)
    case receive(currency: CurrencyDef, isRequestAmountVisible: Bool, initialAddress: String?)
    case selectAsset(asset: Asset)
    case loginAddress
    case loginScan
    case requestAmount(currency: CurrencyDef)
    case addressBook(currency: CurrencyDef, initialAddress: String?, type:ActionAddressType, callback: () -> Void)//BEMX
    case sendWithAddress(currency: CurrencyDef, initialAddress: String? )
    case transferAsset(asset: Asset, initialAddress: String?)
    case createAsset(initialAddress: String?)
    case subAsset(rootAssetName:String, initialAddress: String?)
    case uniqueAsset(rootAssetName:String, initialAddress: String?)
    case manageOwnedAsset(asset: Asset, initialAddress: String?)
    case burnAsset(asset: Asset)

}

enum SyncState {
    case syncing
    case connecting
    case success
}

// MARK: -

struct WalletState {
    let currency: CurrencyDef
    let displayOrder: Int
    let syncProgress: Double
    let syncState: SyncState
    let balance: UInt64?
    let transactions: [Transaction]
    let lastBlockTimestamp: UInt32
    let name: String
    let creationDate: Date
    let isRescanning: Bool
    let receiveAddress: String?
    let numSent: Int // ??
    let rates: [Rate]
    let currentRate: Rate?
    let fees: Fees?
    let recommendRescan: Bool
    let maxDigits: Int // this is bits vs bitcoin setting
    let connectionStatus: BRPeerStatus
    let isBtcSwapped: Bool // show amounts as fiat setting
    
    
    static func initial(_ currency: CurrencyDef, displayOrder: Int) -> WalletState {
        return WalletState(currency: currency,
                           displayOrder: displayOrder,
                           syncProgress: 0.0,
                           syncState: .success,
                           balance: nil,
                           transactions: [],
                           lastBlockTimestamp: 0,
                           name: S.AccountHeader.defaultWalletName,
                           creationDate: Date.zeroValue(),
                           isRescanning: false,
                           receiveAddress: nil,
                           numSent: 0,
                           rates: [],
                           currentRate: UserDefaults.currentRate(forCode: currency.code),
                           fees: nil,
                           recommendRescan: false,
                           maxDigits: UserDefaults.maxDigits,
                           connectionStatus: BRPeerStatusDisconnected,
                           isBtcSwapped: false)
    }

    func mutate(    displayOrder: Int? = nil,
                    syncProgress: Double? = nil,
                    syncState: SyncState? = nil,
                    balance: UInt64? = nil,
                    transactions: [Transaction]? = nil,
                    lastBlockTimestamp: UInt32? = nil,
                    name: String? = nil,
                    creationDate: Date? = nil,
                    isRescanning: Bool? = nil,
                    receiveAddress: String? = nil,
                    numSent: Int? = nil,
                    currentRate: Rate? = nil,
                    rates: [Rate]? = nil,
                    fees: Fees? = nil,
                    recommendRescan: Bool? = nil,
                    maxDigits: Int? = nil,
                    connectionStatus: BRPeerStatus? = nil) -> WalletState {

        return WalletState(currency: self.currency,
                           displayOrder: displayOrder ?? self.displayOrder,
                           syncProgress: syncProgress ?? self.syncProgress,
                           syncState: syncState ?? self.syncState,
                           balance: balance ?? self.balance,
                           transactions: transactions ?? self.transactions,
                           lastBlockTimestamp: lastBlockTimestamp ?? self.lastBlockTimestamp,
                           name: name ?? self.name,
                           creationDate: creationDate ?? self.creationDate,
                           isRescanning: isRescanning ?? self.isRescanning,
                           receiveAddress: receiveAddress ?? self.receiveAddress,
                           numSent: numSent ?? self.numSent,
                           rates: rates ?? self.rates,
                           currentRate: currentRate ?? self.currentRate,
                           fees: fees ?? self.fees,
                           recommendRescan: recommendRescan ?? self.recommendRescan,
                           maxDigits: maxDigits ?? self.maxDigits,
                           connectionStatus: connectionStatus ?? self.connectionStatus,
                           isBtcSwapped: false)
    }
}

extension WalletState : Equatable {}

func ==(lhs: WalletState, rhs: WalletState) -> Bool {
    return lhs.currency.code == rhs.currency.code &&
        lhs.syncProgress == rhs.syncProgress &&
        lhs.syncState == rhs.syncState &&
        lhs.balance == rhs.balance &&
        lhs.transactions == rhs.transactions &&
        lhs.name == rhs.name &&
        lhs.creationDate == rhs.creationDate &&
        lhs.isRescanning == rhs.isRescanning &&
        lhs.numSent == rhs.numSent &&
        lhs.rates == rhs.rates &&
        lhs.currentRate == rhs.currentRate &&
        lhs.fees == rhs.fees &&
        lhs.recommendRescan == rhs.recommendRescan &&
        lhs.maxDigits == rhs.maxDigits &&
        lhs.connectionStatus == rhs.connectionStatus
}

extension RootModal : Equatable {} //BMEX

func ==(lhs: RootModal, rhs: RootModal) -> Bool {
    switch(lhs, rhs) {
    case (.none, .none):
        return true
    case (.send(let lhsCurrency), .send(let rhsCurrency)):
        return lhsCurrency.code == rhsCurrency.code
    case (.addressBook(let lhsCurrency, _, _, _), .addressBook(let rhsCurrency, _, _, _)):
        return lhsCurrency.code == rhsCurrency.code
    case (.sendWithAddress(let lhsCurrency, _), .sendWithAddress(let rhsCurrency, _)):
        return lhsCurrency.code == rhsCurrency.code
    case (.transferAsset(let lhsAsset, _), .transferAsset(let rhsAsset, _)):
        return lhsAsset.name == rhsAsset.name
    case (.createAsset(_), .createAsset(_)):
        return true
    case (.subAsset(let lhsRootAssetName, _), .subAsset(let rhsRootAssetName, _)):
        return lhsRootAssetName == rhsRootAssetName
    case (.uniqueAsset(let lhsRootAssetName, _), .uniqueAsset(let rhsRootAssetName, _)):
        return lhsRootAssetName == rhsRootAssetName
    case (.manageOwnedAsset(let lhsAsset, _), .manageOwnedAsset(let rhsAsset, _)):
        return lhsAsset.name == rhsAsset.name
    case (.burnAsset(let lhsAsset), .burnAsset(let rhsAsset)):
        return lhsAsset.name == rhsAsset.name
    case (.receive(let lhsCurrency, _, _), .receive(let rhsCurrency, _, _)):
        return lhsCurrency.code == rhsCurrency.code
    case (.selectAsset(let lhsAsset), .selectAsset(let rhsAsset)):
        return lhsAsset.name == rhsAsset.name
    case (.loginAddress, .loginAddress):
        return true
    case (.loginScan, .loginScan):
        return true
    case (.requestAmount(let lhsCurrency), .requestAmount(let rhsCurrency)):
        return lhsCurrency.code == rhsCurrency.code
    default:
        return false
    }
}


extension CurrencyDef {
    var state: WalletState {
        return Store.state[self]
    }
}
