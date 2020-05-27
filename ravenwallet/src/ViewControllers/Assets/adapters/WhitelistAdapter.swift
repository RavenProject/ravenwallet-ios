//
//  WhitelistAdapter.swift
//  Ravencoin
//
//  Created by Austin Hill on 5/18/20.
//  Copyright © 2020 Medici Ventures. All rights reserved.
//

import Foundation

class WhitelistAdapter: AssetFilterAdapterProtocol {
    
    private var assetManager: AssetManager
    
    var includedList: [String] = []
    var excludedList: [String] = []
    
    init(assetManager: AssetManager) {
        self.assetManager = assetManager
        
        updateLists()
    }
    
    private func updateLists() {
        includedList = assetManager.whitelist.sorted()
        
        excludedList = assetManager.assetList
            .map {$0.name}
            .filter {!assetManager.whitelist.contains($0)}
            .sorted()
    }
    
    func addToList(_ assetName: String) {
        assetManager.addToWhitelist(assetName: assetName)
        updateLists()
    }
    
    func removeFromList(_ assetName: String) {
        assetManager.removeFromWhitelist(assetName: assetName)
        updateLists()
    }
    
    func titleForList() -> String {
        S.Asset.whitelistTitle
    }
    
    func emptyListText() -> String {
        S.Asset.whitelistEmpty
    }
}
