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
    
    var assetAmount: String {
        return asset.amount.description(minimumFractionDigits: asset.units)
    }
}
