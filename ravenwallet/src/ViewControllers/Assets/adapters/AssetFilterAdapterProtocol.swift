//
//  AssetFilterAdapterProtocol.swift
//  Ravencoin
//
//  Created by Austin Hill on 5/18/20.
//  Copyright © 2020 Medici Ventures. All rights reserved.
//

import Foundation

protocol AssetFilterAdapterProtocol {
    
    var includedList: [String] {get}
    var excludedList: [String] {get}
    
    func addToList(_ assetName: String)
    func removeFromList(_ assetName: String)
    func titleForList() -> String
    func emptyListText() -> String
}
