//
//  AssetListViewModel.swift
//  ravenwallet
//
//  Created by Ehsan Rezaie on 2018-01-31.
//  Copyright © 2018 breadwallet LLC. All rights reserved.
//

import Foundation

struct AssetListViewModel {
    
    var asset: Asset
    
    var assetName: String {
        get{
            if asset.name.contains("#") {
                let index = asset.name.lastIndex(of: "#")!
                let result = String(String(asset.name[index...]).dropFirst())
                return result
            }
            else if asset.name.contains("/") {
                let index = asset.name.lastIndex(of: "/")!
                let result = String(String(asset.name[index...]).dropFirst())
                return result
            }
            else{
                return asset.name
            }
        }
    }
    
    var assetRootName: String{
        get{
            if asset.name.contains("#") {
                let index = asset.name.lastIndex(of: "#")!
                let result = String(asset.name[...index])
                return result
            }
            else if asset.name.contains("/") {
                let index = asset.name.lastIndex(of: "/")!
                let result = String(asset.name[...index])
                return result
            }
            else{
                return ""
            }
        }
    }
    
    var assetAmount: String {
        return asset.amount.description(minimumFractionDigits: Int(asset.units))
    }
}
