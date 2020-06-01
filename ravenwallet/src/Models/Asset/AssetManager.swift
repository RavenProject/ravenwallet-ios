//
//  AssetManager.swift
//  ravenwallet
//
//  Created by Ben on 15/10/18.
//  Copyright (c) 2018 Ravenwallet Team


import Foundation
import UIKit
import SystemConfiguration

class AssetManager {
    
    enum AssetFilter: String, CaseIterable {
        case whitelist
        case blacklist
        
        var displayString: String {
            switch self {
            case .whitelist: return S.Asset.whitelist
            case .blacklist: return S.Asset.blacklist
            }
        }
    }
    
    static let shared = AssetManager()

    private var db: CoreDatabase?
    
    var assetList:[Asset] = []
    var showedAssetList:[Asset] {
        get {
            switch assetFilter {
                
            case .whitelist:
                return assetList.filter {
                    whitelist.contains($0.name)
                }
                
            case .blacklist:
                return assetList.filter {
                    !blacklist.contains($0.name)
                }
            }
        }
    }
    
    var assetFilter: AssetFilter {
        didSet {
            UserDefaults.assetFilter = assetFilter
        }
    }
    
    private(set) var whitelist: Set<String> = []
    private(set) var blacklist: Set<String> = []
    
    private init() {
        db = CoreDatabase()
        
        // From settings, restore the filter previously used
        if let filterFromSettings = UserDefaults.assetFilter {
            assetFilter = filterFromSettings
            loadAsset()
            loadWhitelist()
            loadBlacklist()
        }else {
            
            // If there is no previous filter then we will blacklist any previously hidden assets
            // as a blacklist is analogous to the previous hide/display by paradigm
            assetFilter = .blacklist
            UserDefaults.assetFilter = .blacklist // Need to manually do this as 'didSet' is not called during initialization
            
            loadAssetsBlocking()
            loadBlacklist()
            
            assetList.filter { $0.isHidden }.forEach { self.addToBlacklist(assetName: $0.name )}
            
            self.loadWhitelist()
        }
    }
    
    private func loadAssetsBlocking() {
        guard let assets = db?.blockingLoadAssets() else { return }
        assetList = assets
    }
    
    private func loadWhitelist() {
        guard let dbWhitelist = db?.loadWhitelistBlocking() else { return }
        
        for asset in dbWhitelist {
            whitelist.insert(asset)
        }
    }
    
    private func loadBlacklist() {
        guard let dbBlacklist = db?.loadBlacklistBlocking() else { return }
        
        for asset in dbBlacklist {
            blacklist.insert(asset)
        }
    }
    
    func loadAsset(callBack: (([Asset]) -> Void)? = nil) {
        db?.loadAssets(callback: { assets in
            self.assetList = assets
            
            callBack?(assets)
        })
    }
    
    func updateAssetOrder(assets:[Asset]) {
        var orderId = assets.count
        for var asset in assets {
            asset.sort = orderId
            db?.updateSortAsset(asset, where: asset.idAsset)
            orderId = orderId - 1
        }
    }
    
    @available(*, deprecated, message: "Will be removed in favor of using the blacklist/whitelist functionality" )
    func hideAsset(asset:Asset, where idOldValue:Int, callback: ((Bool)->Void)? = nil) {
        db?.updateHideAsset(asset, where: idOldValue, callback: callback)
    }
    
    func isAssetNameExiste(name:String, callback: @escaping (AssetName?, Bool)->Void) {
        db?.isAssetNameExiste(name: name, callback: { (assetName, isExiste) in
            callback(assetName, isExiste)
        })
    }
    
    //MARK: Asset Filter
    
    func setAssetFilter(_ assetFilter: AssetFilter) {
        self.assetFilter = assetFilter
    }
    
    //MARK: Asset Filter - Whitelist
    
    func addToWhitelist(assetName: String) {
        let result = whitelist.insert(assetName)
        
        guard result.0 else { return } // Check that the name was inserted
        
        db?.addToWhitelist(assetName: assetName) { [weak self] success in
            
            // Reload the whitelist if the transaction is not successful so that we stay in coordination with the db
            if !success {
                self?.loadWhitelist()
            }
        }
    }
    
    func removeFromWhitelist(assetName: String) {
        guard let _ = whitelist.remove(assetName) else { return }
            
        db?.removeFromWhitelist(assetName: assetName)
    }
    
    func clearWhitelist() {
        whitelist.removeAll()
        db?.clearWhitelist()
    }
    
    //MARK: Asset Filter - Blacklist
    
    func addToBlacklist(assetName: String) {
        let result = blacklist.insert(assetName)
        
        guard result.0 else { return } // Check that the name was inserted
        
        db?.addToBlacklist(assetName: assetName) { [weak self] success in
            
            // Reload the whitelist if the transaction is not successful so that we stay in coordination with the db
            if !success {
                self?.loadBlacklist()
            }
        }
    }
    
    func removeFromBlacklist(assetName: String) {
        guard let _ = blacklist.remove(assetName) else { return }
            
        db?.removeFromBlacklist(assetName: assetName)
    }
    
    func clearBlacklist() {
        blacklist.removeAll()
        db?.clearBlacklist()
    }
}
