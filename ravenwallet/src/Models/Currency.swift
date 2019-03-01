//
//  Currency.swift
//  ravenwallet
//
//  Created by Ehsan Rezaie on 2018-01-10.
//  Copyright © 2018 Raven Team LLC. All rights reserved.
//

import Foundation
import Core
import UIKit

// MARK: - Protocols

/// Represents common properties of cryptocurrency types
protocol CurrencyDef {
    /// Ticker code -- assumed to be unique
    var code: String { get }
    /// Primary unit symbol
    var symbol: String { get }
    var name: String { get }
    /// Base unit to primary unit multiplier
    var baseUnit: Double { get }
    /// Primary + secondary color
    var colors: (UIColor, UIColor) { get }
    /// URL scheme for payment requests
    var urlScheme: String? { get }
    /// Returns true if the currency ticker codes match
    func matches(_ other: CurrencyDef) -> Bool
    /// Checks address validity in currency-specific format
    func isValidAddress(_ address: String) -> Bool
    /// Returns a URI with the given address
    func addressURI(_ address: String) -> String?
    /// Returns the unit name for given denomination or empty string
    func unitName(maxDigits: Int) -> String
    /// Returns the unit symbol for given denomination or empty string
    func unitSymbol(maxDigits: Int) -> String
}

extension CurrencyDef {
    var urlScheme: String? {
        return nil
    }
    
    func matches(_ other: CurrencyDef) -> Bool {
        return self.code == other.code
    }
    
    func addressURI(_ address: String) -> String? {
        guard let scheme = urlScheme, isValidAddress(address) else { return nil }
        return "\(scheme):\(address)"
    }
    
    func unitName(maxDigits: Int) -> String {
        return ""
    }
    
    func unitSymbol(maxDigits: Int) -> String {
        return ""
    }
}

/// MARK: - Currency Definitions

/// Bitcoin-compatible currency type
struct Raven: CurrencyDef {
    let baseUnit = 100000.0
    let name: String
    let code: String
    let symbol: String
    let colors: (UIColor, UIColor)
    let dbPath: String
    let urlScheme: String?
    
    func isValidAddress(_ address: String) -> Bool {
            return address.isValidAddress
        }
    
    func addressURI(_ address: String) -> String? {
        guard let scheme = urlScheme, isValidAddress(address) else { return nil }
            return "\(scheme):\(address)"
        }
    
    func unitName(maxDigits: Int) -> String {
        switch maxDigits {
        case 2:
            return "Microraven\(S.Symbols.narrowSpace)(\(S.Symbols.uRvn))"
        case 5:
            return "Milliraven\(S.Symbols.narrowSpace)(m\(S.Symbols.rvn))"
        case 8:
            return "(\(S.Symbols.rvn))\(S.Symbols.narrowSpace)RVN"
        default:
            return "\(S.Symbols.uRvn)"
        }
    }
    
    func unitSymbol(maxDigits: Int) -> String {
        switch maxDigits {
        case 2:
            return S.Symbols.uRvn
        case 5:
            return "m\(S.Symbols.rvn)"
        case 8:
            return S.Symbols.rvn
        default:
//            return S.Symbols.uRvn
            return S.Symbols.rvn
        }
    }
}

// MARK: Instances

struct Currencies {
    static let rvn = Raven(name: "Ravencoin",
                             code: "RVN",
                             symbol: S.Symbols.rvn,
                             colors: (UIColor(red: 46.0/255.0, green: 62.0/255.0, blue: 128.0/255.0, alpha: 1.0),
                                      UIColor(red: 34.0/255.0, green: 45.0/255.0, blue: 105.0/255.0, alpha: 1.0)),
                             // TODO change this to new path
                             dbPath: "RavenWallet.sqlite",//"BreadWallet.sqlite",
                             urlScheme: "Raven")
}
