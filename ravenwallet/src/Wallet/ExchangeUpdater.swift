//
//  ExchangeUpdater.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2017-01-27.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import Foundation

class ExchangeUpdater : Subscriber {

    let currency: CurrencyDef
    
    //MARK: - Public
    init(currency: CurrencyDef, walletManager: WalletManager) {
        self.currency = currency
        self.walletManager = walletManager
        Store.subscribe(self,
                        selector: { $0.defaultCurrencyCode != $1.defaultCurrencyCode },
                        callback: { state in
                            guard let currentRate = state[self.currency].rates.first( where: { $0.code == state.defaultCurrencyCode }) else { return }
                            Store.perform(action: WalletChange(self.currency).setExchangeRate(currentRate))
        })
    }
    
    func refresh(completion: @escaping () -> Void) {
        
        walletManager.apiClient?.ravenMultiplier{multiplier, error in
            guard let ratio_to_btc : Double = multiplier else { completion(); return }
            self.walletManager.apiClient?.exchangeRates(code: self.currency.code, isFallback: false, ratio_to_btc, { rates,
                ratio_to_btc, error in
                
                guard let currentRate = rates.first( where: { $0.code == Store.state.defaultCurrencyCode }) else { completion(); return }
                let aRate = Rate(code: currentRate.code, name: currentRate.name, rate: currentRate.rate * ratio_to_btc);
                
                Store.perform(action: WalletChange(self.currency).setExchangeRates(currentRate: aRate, rates: rates))

                completion()
            })
        }
    }

    //MARK: - Private
    let walletManager: WalletManager
}
