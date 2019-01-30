//
//  AssetManager.swift
//  ravenwallet
//
//  Created by Bendnaiba on 15/10/18.
//  Copyright (c) 2018 Ravenwallet Team


import Foundation
import UIKit
import SystemConfiguration

class AssetManager {
    
    static let shared = AssetManager()

    var db: CoreDatabase?
    var assetList:[Asset] = []
    var showedAssetList:[Asset] {
        get {
            return assetList.filter({ $0.isHidden == false})
        }
    }
    
    private init() {
        db = CoreDatabase()
        loadAsset()
    }
    
    func loadAsset(callBack: (([Asset]) -> Void)? = nil) {
        db = CoreDatabase()
        db?.loadAssets(callback: { assets in
            self.assetList = assets
            if callBack != nil {
                callBack!(assets)
            }
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
    
    func hideAsset(asset:Asset, where idOldValue:Int, callback: ((Bool)->Void)? = nil) {
        db?.updateHideAsset(asset, where: idOldValue, callback: callback)
    }
    
    func isAssetNameExiste(name:String, callback: @escaping (AssetName?, Bool)->Void) {
        db?.isAssetNameExiste(name: name, callback: { (assetName, isExiste) in
            callback(assetName, isExiste)
        })
    }

}
