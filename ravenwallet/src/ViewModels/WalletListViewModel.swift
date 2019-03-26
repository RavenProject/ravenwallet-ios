//
//  WalletListViewModel.swift
//  ravenwallet
//
//  Created by Ehsan Rezaie on 2018-01-31.
//  Copyright © 2018 breadwallet LLC. All rights reserved.
//

import Foundation

struct WalletListViewModel {
    let currency: CurrencyDef
    
    var exchangeRate: String {
        guard let rate = currency.state.currentRate else { return "" }
        if rate.rate != 0 {
            let placeholderAmount = Amount(amount: 0, rate: rate, maxDigits: 4, currency: currency)
            return placeholderAmount.homeScreenFormat.string(from: NSNumber(value: rate.rate)) ?? ""
        }
        return S.ErrorMessages.noRates
    }
    
    var fiatBalance: String {
        guard let rate = currency.state.currentRate else { return "" }
        return balanceString(inFiatWithRate: rate)
    }
    
    var tokenBalance: String {
        return balanceString()
    }
    
    /// Returns balance string in fiat if rate specified or token amount otherwise
    private func balanceString(inFiatWithRate rate: Rate? = nil) -> String {
        guard let balance = currency.state.balance else { return "" }
        return DisplayAmount(amount: Satoshis(rawValue: balance),
                             selectedRate: rate,
                             minimumFractionDigits: nil,
                             currency: currency).description
    }
}
