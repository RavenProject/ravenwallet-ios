//
//  UserDefaults+Additions.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2017-04-04.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import Foundation

private let defaults = UserDefaults.standard
private let isBiometricsEnabledKey = "istouchidenabled"
private let defaultCurrencyCodeKey = "defaultcurrency"
private let hasAquiredShareDataPermissionKey = "has_acquired_permission"
private let hasActivatedExpertModeKey = "has_activated_expert_mode"
private let legacyWalletNeedsBackupKey = "WALLET_NEEDS_BACKUP"
private let writePaperPhraseDateKey = "writepaperphrasedatekey"
private let hasPromptedBiometricsKey = "haspromptedtouched"
private let hasDismissedPromptKey = "hasDismissedPromptKey"
private let hasRescannedBlockChainKey = "hasRescannedBlockChain"
private let isBtcSwappedKey = "isBtcSwappedKey"
private let maxDigitsKey = "SETTINGS_MAX_DIGITS"
private let pushTokenKey = "pushTokenKey"
private let currentRateKey = "currentRateKey"
private let customNodeIPKey = "customNodeIPKey"
private let customNodePortKey = "customNodePortKey"
private let hasPromptedShareDataKey = "hasPromptedShareDataKey"
private let hasShownWelcomeKey = "hasShownWelcomeKey"
private let hasCompletedKYC = "hasCompletedKYCKey"
private let hasAgreedToCrowdsaleTermsKey = "hasAgreedToCrowdsaleTermsKey"
private let feesKey = "feesKey"
private let selectedCurrencyCodeKey = "selectedCurrencyCodeKey"
private let mostRecentSelectedCurrencyCodeKey = "mostRecentSelectedCurrencyCodeKey"
private let hasSetSelectedCurrencyKey = "hasSetSelectedCurrencyKey"
private let hasBchConnectedKey = "hasBchConnectedKey"
private let shouldReloadChartKey = "shouldReloadChartKey"

extension UserDefaults {

    static var isBiometricsEnabled: Bool {
        get {
            guard defaults.object(forKey: isBiometricsEnabledKey) != nil else {
                return false
            }
            return defaults.bool(forKey: isBiometricsEnabledKey)
        }
        set { defaults.set(newValue, forKey: isBiometricsEnabledKey) }
    }

    static var defaultCurrencyCode: String {
        get {
            guard defaults.object(forKey: defaultCurrencyCodeKey) != nil else {
                return Locale.current.currencyCode ?? "USD"
            }
            return defaults.string(forKey: defaultCurrencyCodeKey)!
        }
        set { defaults.set(newValue, forKey: defaultCurrencyCodeKey) }
    }

    static var hasAquiredShareDataPermission: Bool {
        get { return defaults.bool(forKey: hasAquiredShareDataPermissionKey) }
        set { defaults.set(newValue, forKey: hasAquiredShareDataPermissionKey) }
    }
    
    static var hasActivatedExpertMode: Bool {
        get { return defaults.bool(forKey: hasActivatedExpertModeKey) }
        set { defaults.set(newValue, forKey: hasActivatedExpertModeKey) }
    }

    static var isBtcSwapped: Bool {
        get { return defaults.bool(forKey: isBtcSwappedKey)
        }
        set { defaults.set(newValue, forKey: isBtcSwappedKey) }
    }

    //
    // 2 - bits
    // 5 - mRVN
    // 8 - RVN
    //
    static var maxDigits: Int {
        get {
            guard defaults.object(forKey: maxDigitsKey) != nil else {
                return 8
            }
            let maxDigits = defaults.integer(forKey: maxDigitsKey)
            if maxDigits == 5 {
                return 8 //Convert mRVN to RVN
            } else {
                return maxDigits
            }
        }
        set { defaults.set(newValue, forKey: maxDigitsKey) }
    }

    static var pushToken: Data? {
        get {
            guard defaults.object(forKey: pushTokenKey) != nil else {
                return nil
            }
            return defaults.data(forKey: pushTokenKey)
        }
        set { defaults.set(newValue, forKey: pushTokenKey) }
    }

    static func currentRate(forCode: String) -> Rate? {
        guard let data = defaults.object(forKey: currentRateKey + forCode) as? [String: Any] else {
            return nil
        }
        return Rate(data: data)
    }

    static func currentRateData(forCode: String) -> [String: Any]? {
        guard let data = defaults.object(forKey: currentRateKey + forCode) as? [String: Any] else {
            return nil
        }
        return data
    }

    static func setCurrentRateData(newValue: [String: Any], forCode: String) {
        defaults.set(newValue, forKey: currentRateKey + forCode)
    }

    static var customNodeIP: Int? {
        get {
            guard defaults.object(forKey: customNodeIPKey) != nil else { return nil }
            return defaults.integer(forKey: customNodeIPKey)
        }
        set { defaults.set(newValue, forKey: customNodeIPKey) }
    }

    static var customNodePort: Int? {
        get {
            guard defaults.object(forKey: customNodePortKey) != nil else { return nil }
            return defaults.integer(forKey: customNodePortKey)
        }
        set { defaults.set(newValue, forKey: customNodePortKey) }
    }

    static var hasPromptedShareData: Bool {
        get { return defaults.bool(forKey: hasPromptedBiometricsKey) }
        set { defaults.set(newValue, forKey: hasPromptedBiometricsKey) }
    }
    
    static var hasDismissedPrompt: Bool {
        get { return defaults.bool(forKey: hasDismissedPromptKey) }
        set { defaults.set(newValue, forKey: hasDismissedPromptKey) }
    }
    
    static var hasRescannedBlockChain: Bool {
        get { return defaults.bool(forKey: hasRescannedBlockChainKey) }
        set { defaults.set(newValue, forKey: hasRescannedBlockChainKey) }
    }

    static var hasShownWelcome: Bool {
        get { return defaults.bool(forKey: hasShownWelcomeKey) }
        set { defaults.set(newValue, forKey: hasShownWelcomeKey) }
    }

    static var fees: Fees? {
        //Returns nil if feeCacheTimeout exceeded
        get {
            if let feeData = defaults.data(forKey: feesKey), let fees = try? JSONDecoder().decode(Fees.self, from: feeData){
                return (Date().timeIntervalSince1970 - fees.timestamp) <= C.feeCacheTimeout ? fees : nil
            } else {
                return nil
            }
        }
        set {
            if let fees = newValue, let data = try? JSONEncoder().encode(fees){
                defaults.set(data, forKey: feesKey)
            }
        }
    }
}

//MARK: - Wallet Requires Backup
extension UserDefaults {
    static var legacyWalletNeedsBackup: Bool? {
        guard defaults.object(forKey: legacyWalletNeedsBackupKey) != nil else {
            return nil
        }
        return defaults.bool(forKey: legacyWalletNeedsBackupKey)
    }

    static func removeLegacyWalletNeedsBackupKey() {
        defaults.removeObject(forKey: legacyWalletNeedsBackupKey)
    }

    static var writePaperPhraseDate: Date? {
        get { return defaults.object(forKey: writePaperPhraseDateKey) as! Date? }
        set { defaults.set(newValue, forKey: writePaperPhraseDateKey) }
    }

    static var walletRequiresBackup: Bool {
        if UserDefaults.writePaperPhraseDate != nil {
            return false
        }
        if let legacyWalletNeedsBackup = UserDefaults.legacyWalletNeedsBackup, legacyWalletNeedsBackup == true {
            return true
        }
        if UserDefaults.writePaperPhraseDate == nil {
            return true
        }
        return false
    }
}

//MARK: - Prompts
extension UserDefaults {
    static var hasPromptedBiometrics: Bool {
        get { return defaults.bool(forKey: hasPromptedBiometricsKey) }
        set { defaults.set(newValue, forKey: hasPromptedBiometricsKey) }
    }
}

//MARK: - KYC
extension UserDefaults {
    static func hasCompletedKYC(forContractAddress: String) -> Bool {
        return defaults.bool(forKey: "\(hasCompletedKYC)\(forContractAddress)")
    }

    static func setHasCompletedKYC(_ hasCompleted: Bool, contractAddress: String) {
        defaults.set(hasCompleted, forKey: "\(hasCompletedKYC)\(contractAddress)")
    }

    static var hasAgreedToCrowdsaleTerms: Bool {
        get { return defaults.bool(forKey: hasAgreedToCrowdsaleTermsKey) }
        set { defaults.set(newValue, forKey: hasAgreedToCrowdsaleTermsKey) }
    }
}

//MARK: - State Restoration
extension UserDefaults {
    static var selectedCurrencyCode: String? {
        get {
            if UserDefaults.hasSetSelectedCurrency {
                return defaults.string(forKey: selectedCurrencyCodeKey)
            } else {
                return Currencies.rvn.code
            }
        }
        set {
            UserDefaults.hasSetSelectedCurrency = true
            defaults.setValue(newValue, forKey: selectedCurrencyCodeKey)
        }
    }

    static var hasSetSelectedCurrency: Bool {
        get { return defaults.bool(forKey: hasSetSelectedCurrencyKey) }
        set { defaults.setValue(newValue, forKey: hasSetSelectedCurrencyKey) }
    }

    static var mostRecentSelectedCurrencyCode: String {
        get {
            return defaults.string(forKey: mostRecentSelectedCurrencyCodeKey) ?? Currencies.rvn.code
        }
        set {
            defaults.setValue(newValue, forKey: mostRecentSelectedCurrencyCodeKey)
        }
    }

    static var hasBchConnected: Bool {
        get { return defaults.bool(forKey: hasBchConnectedKey) }
        set { defaults.set(newValue, forKey: hasBchConnectedKey) }
    }
}

//MARK: - Chart Data
extension UserDefaults {
    
    static var isChartDrawed:Bool = false
    
    static var shouldReloadChart: Bool {
        get {
            let lastTimeIntervale = defaults.integer(forKey: shouldReloadChartKey)
            let lastDate:Date = Date(timeIntervalSince1970: TimeInterval(lastTimeIntervale))
            let difference = abs(lastDate.timeIntervalSince(Date()))
            let hoursDiff = Int(difference) / 3600
            if(hoursDiff > 1)
            {
                return true
            }
            return false
        }
        set { defaults.set(Date().timeIntervalSince1970, forKey: shouldReloadChartKey) }
    }
    
    static func initChartDate()
    {
        //BMEX reinit dataChart
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.date(from: "1970-01-01")
        defaults.set(date, forKey: shouldReloadChartKey)
    }
}
