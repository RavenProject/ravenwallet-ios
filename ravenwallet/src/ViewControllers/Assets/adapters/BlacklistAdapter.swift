//
//  BlacklistAdapter.swift
//  Ravencoin
//
//  Created by Austin Hill on 5/19/20.
//  Copyright © 2020 Medici Ventures. All rights reserved.
//

import Foundation

class BlacklistAdapter: AssetFilterAdapterProtocol {
    
    private var assetManager: AssetManager
    
    var includedList: [String] = []
    var excludedList: [String] = []
    
    init(assetManager: AssetManager) {
        self.assetManager = assetManager
        
        updateLists()
    }
    
    private func updateLists() {
        includedList = assetManager.blacklist.sorted()
        
        excludedList = assetManager.assetList
            .map {$0.name}
            .filter {!assetManager.blacklist.contains($0)}
            .sorted()
    }
    
    func addToList(_ assetName: String) {
        assetManager.addToBlacklist(assetName: assetName)
        updateLists()
    }
    
    func removeFromList(_ assetName: String) {
        assetManager.removeFromBlacklist(assetName: assetName)
        updateLists()
    }
    
    func titleForList() -> String {
        S.Asset.blacklistTitle
    }
    
    func emptyListText() -> String {
        S.Asset.blacklistEmpty
    }
}
