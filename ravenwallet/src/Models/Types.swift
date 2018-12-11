//
//  Types.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2017-05-20.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import Foundation

//MARK: - Satishis
struct Satoshis {
    let rawValue: UInt64
}

extension Satoshis {

    init(_ rawValue: UInt64) {
        self.rawValue = rawValue
    }

    init(bits: Bits) {
        rawValue = UInt64((bits.rawValue * 100.0).rounded(.toNearestOrEven))
    }

    init(bitcoin: Ravencoins) {
        rawValue = UInt64((bitcoin.rawValue * Double(C.satoshis)).rounded(.toNearestOrEven))
    }

    init(value: Double, rate: Rate) {
        rawValue = UInt64((value / rate.rate * Double(C.satoshis)).rounded(.toNearestOrEven))
    }
    
    init(value: Double) {
        rawValue = UInt64((value * Double(C.satoshis)).rounded(.toNearestOrEven))
    }

    init?(btcString: String) {
        var decimal: Decimal = 0.0
        var amount: Decimal = 0.0
        guard Scanner(string: btcString).scanDecimal(&decimal) else { return nil }
        NSDecimalMultiplyByPowerOf10(&amount, &decimal, 8, .up)
        rawValue = NSDecimalNumber(decimal: amount).uint64Value
    }
    
    func description(minimumFractionDigits:Int) -> String {
        var decimal = Decimal(rawValue)
        var amount: Decimal = 0.0
        NSDecimalMultiplyByPowerOf10(&amount, &decimal, Int16(-8), .up)
        let number = NSDecimalNumber(decimal: amount)
        guard let string = satoshiFormat(minimumFractionDigits: minimumFractionDigits).string(from: number) else { return "" }
        return string
    }
    
    func satoshiFormat(minimumFractionDigits:Int) -> NumberFormatter {
        let format = NumberFormatter()
        format.isLenient = true
        format.generatesDecimalNumbers = true
        format.negativeFormat = "-\(format.positiveFormat!)"
        format.minimumFractionDigits = minimumFractionDigits
        return format
    }
    
    var doubleValue: Double {
        return (Double(rawValue) / Double(C.satoshis))
    }
}

extension Satoshis : Equatable {}

func ==(lhs: Satoshis, rhs: Satoshis) -> Bool {
    return lhs.rawValue == rhs.rawValue
}

func ==(lhs: Satoshis?, rhs: UInt64) -> Bool {
    return lhs?.rawValue == rhs
}

func +(lhs: Satoshis, rhs: UInt64) -> Satoshis {
    return Satoshis(lhs.rawValue + rhs)
}

func +(lhs: Satoshis, rhs: Satoshis) -> Satoshis {
    return Satoshis(lhs.rawValue + rhs.rawValue)
}

func +=(lhs: inout Satoshis, rhs: UInt64) {
    lhs = lhs + rhs
}

func >(lhs: Satoshis, rhs: UInt64) -> Bool {
    return lhs.rawValue > rhs
}

func <(lhs: Satoshis, rhs: UInt64) -> Bool {
    return lhs.rawValue < rhs
}

//MARK: - Bits
struct Bits {
    let rawValue: Double
}

extension Bits {

    init(satoshis: Satoshis) {
        rawValue = Double(satoshis.rawValue)/100.0
    }

    init?(string: String) {
        guard let value = Double(string) else { return nil }
        rawValue = value
    }
}

//MARK: - Ravencoins
struct Ravencoins {
    let rawValue: Double
}

extension Ravencoins {
    init?(string: String) {
        guard let value = Double(string) else { return nil }
        rawValue = value
    }
}

//MARK: Wei
struct Wei {
    let rawValue: UInt64
}

extension Wei {
    init?(ethString: String) {
        var decimal: Decimal = 0.0
        var amount: Decimal = 0.0
        guard Scanner(string: ethString).scanDecimal(&decimal) else { return nil }
        NSDecimalMultiplyByPowerOf10(&amount, &decimal, 18, .up)
        rawValue = NSDecimalNumber(decimal: amount).uint64Value
    }
}
