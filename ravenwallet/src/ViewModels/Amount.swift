//
//  Amount.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2017-01-15.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import Foundation

struct Amount {

    //MARK: - Public
    let amount: UInt64 //amount in satoshis
    let rate: Rate
    let maxDigits: Int
    let currency: CurrencyDef
    
    var amountForRvnFormat: Double {
        var decimal = Decimal(self.amount)
        var amount: Decimal = 0.0
        NSDecimalMultiplyByPowerOf10(&amount, &decimal, Int16(-maxDigits), .up)
        return NSDecimalNumber(decimal: amount).doubleValue
    }

    var localAmount: Double {
        return Double(amount)/100000000.0*rate.rate
    }

    var bits: String {
        var decimal = Decimal(self.amount)
        var amount: Decimal = 0.0
        NSDecimalMultiplyByPowerOf10(&amount, &decimal, Int16(-maxDigits), .up)
        let number = NSDecimalNumber(decimal: amount)
        guard let string = rvnFormat.string(from: number) else { return "" }
        return string
    }

    var localCurrency: String {
        guard let string = localFormat.string(from: Double(amount)/100000000.0*rate.rate as NSNumber) else { return "" }
        return string
    }

    func string(forLocal local: Locale) -> String {
        let format = NumberFormatter()
        format.locale = local
        format.isLenient = true
        format.numberStyle = .currency
        format.generatesDecimalNumbers = true
        format.negativeFormat = format.positiveFormat.replacingCharacters(in: format.positiveFormat.range(of: "#")!, with: "-#")
        guard let string = format.string(from: Double(amount)/100000000.0*rate.rate as NSNumber) else { return "" }
        return string
    }

    func string(isBtcSwapped: Bool) -> String {
        return isBtcSwapped ? localCurrency : bits
    }

    var rvnFormat: NumberFormatter {
        let format = NumberFormatter()
        format.isLenient = true
        format.numberStyle = .currency
        format.generatesDecimalNumbers = true
        format.negativeFormat = format.positiveFormat.replacingCharacters(in: format.positiveFormat.range(of: "#")!, with: "-#")
        format.currencyCode = "RVN"

        switch maxDigits {
        case 2:
            format.currencySymbol = "\(S.Symbols.uRvn)\(S.Symbols.narrowSpace)"
            format.maximum = (C.maxMoney/C.satoshis)*100000 as NSNumber
        case 5:
            format.currencySymbol = "m\(S.Symbols.rvn)\(S.Symbols.narrowSpace)"
            format.maximum = (C.maxMoney/C.satoshis)*1000 as NSNumber
        case 8:
            format.currencySymbol = "\(S.Symbols.rvn)\(S.Symbols.narrowSpace)"
            format.maximum = C.maxMoney/C.satoshis as NSNumber
        default:
            format.currencySymbol = "\(S.Symbols.uRvn)\(S.Symbols.narrowSpace)"
        }

        format.maximumFractionDigits = maxDigits
        format.minimumFractionDigits = 0 // iOS 8 bug, minimumFractionDigits now has to be set after currencySymbol
        format.maximum = Decimal(C.maxMoney)/(pow(10.0, maxDigits)) as NSNumber

        return format
    }

    var localFormat: NumberFormatter {
        let format = NumberFormatter()
        format.isLenient = true
        format.numberStyle = .currency
        format.generatesDecimalNumbers = true
        format.negativeFormat = format.positiveFormat.replacingCharacters(in: format.positiveFormat.range(of: "#")!, with: "-#")
        format.currencySymbol = rate.currencySymbol
        return format
    }
}

struct DisplayAmount {
    let amount: Satoshis
    let selectedRate: Rate?
    let minimumFractionDigits: Int?
    let currency: CurrencyDef
    let negative: Bool
    let asset:BRAssetRef?
    let locale:Locale?
    
    init(amount: Satoshis, selectedRate: Rate?, minimumFractionDigits: Int?, currency: CurrencyDef, negative: Bool, locale:Locale? = nil, asset:BRAssetRef? = nil) {
        self.amount = amount
        self.selectedRate = selectedRate
        self.minimumFractionDigits = minimumFractionDigits
        self.currency = currency
        self.negative = negative
        self.asset = asset
        self.locale = locale
    }
    
    init(amount: Satoshis, selectedRate: Rate?, minimumFractionDigits: Int?, currency: CurrencyDef) {
        self.init(amount: amount, selectedRate: selectedRate, minimumFractionDigits: minimumFractionDigits, currency: currency, negative: false)
    }
    
    var description: String {
        if asset != nil {
            return assetDescription
        }
        return selectedRate != nil ? fiatDescription : bitcoinDescription
    }

    var combinedDescription: String {
        return Store.state.isSwapped ? "\(fiatDescription) (\(bitcoinDescription))" : "\(bitcoinDescription) (\(fiatDescription))"
    }

    private var fiatDescription: String {
        guard let rate = selectedRate ?? currency.state.currentRate else { return "" }
        let tokenAmount = Double(amount.rawValue) * (negative ? -1.0 : 1.0)
        guard let string = localFormat.string(from: tokenAmount/100000000.0*rate.rate as NSNumber) else { return "" }
        return string
    }
    
    private var assetDescription: String {
        let amountSatoshi: Satoshis = Satoshis.init(UInt64(asset!.pointee.amount))
        var decimal = Decimal(amountSatoshi.rawValue)
        var amount: Decimal = 0.0
        NSDecimalMultiplyByPowerOf10(&amount, &decimal, Int16(-8), .up)
        let number = NSDecimalNumber(decimal: amount * (negative ? -1.0 : 1.0))
        guard var string = assetFormat.string(from: number) else { return "" }
        string = string + " " + asset!.pointee.nameString
        return string
    }

    private var bitcoinDescription: String {
        var decimal = Decimal(self.amount.rawValue)
        var amount: Decimal = 0.0
        NSDecimalMultiplyByPowerOf10(&amount, &decimal, Int16(-currency.state.maxDigits), .up)
        let number = NSDecimalNumber(decimal: amount * (negative ? -1.0 : 1.0))
        guard let string = rvnFormat.string(from: number) else { return "" }
        return string
    }

    var localFormat: NumberFormatter {
        let format = NumberFormatter()
        format.isLenient = true
        format.numberStyle = .currency
        format.generatesDecimalNumbers = true
        format.negativeFormat = "-\(format.positiveFormat!)"
        if let rate = selectedRate {
            format.currencySymbol = rate.currencySymbol
        } else if let rate = currency.state.currentRate {
            format.currencySymbol = rate.currencySymbol
        }
        if let minimumFractionDigits = minimumFractionDigits {
            format.minimumFractionDigits = minimumFractionDigits
        }
        return format
    }

    var rvnFormat: NumberFormatter {
        let format = NumberFormatter()
        if locale != nil {
            format.locale = locale
        }
        format.isLenient = true
        format.numberStyle = .currency
        format.generatesDecimalNumbers = true
        format.negativeFormat = "-\(format.positiveFormat!)"
        format.currencyCode = currency.code
        switch currency.state.maxDigits {
        case 2:
            format.currencySymbol = "\((locale != nil) ? S.Symbols.ulRvn : S.Symbols.uRvn)\(S.Symbols.narrowSpace)"
            format.maximum = (C.maxMoney/C.satoshis)*100000 as NSNumber
        case 5:
            format.currencySymbol = "m\((locale != nil) ? S.Symbols.lRvn : S.Symbols.rvn)\(S.Symbols.narrowSpace)"
            format.maximum = (C.maxMoney/C.satoshis)*1000 as NSNumber
        case 8:
            format.currencySymbol = "\((locale != nil) ? S.Symbols.lRvn : S.Symbols.rvn)\(S.Symbols.narrowSpace)"
            format.maximum = C.maxMoney/C.satoshis as NSNumber
        default:
            format.currencySymbol = "\((locale != nil) ? S.Symbols.ulRvn : S.Symbols.uRvn)\(S.Symbols.narrowSpace)"
        }

        format.maximumFractionDigits = currency.state.maxDigits
        format.maximum = Decimal(C.maxMoney)/(pow(10.0, currency.state.maxDigits)) as NSNumber

        if let minimumFractionDigits = minimumFractionDigits {
            format.minimumFractionDigits = minimumFractionDigits
        }

        return format
    }
    
    var assetFormat: NumberFormatter {
        let format = NumberFormatter()
        format.isLenient = true
        format.generatesDecimalNumbers = true
        format.negativeFormat = "-\(format.positiveFormat!)"
        format.minimumFractionDigits = Int(asset!.pointee.unit)

        return format
    }
}
