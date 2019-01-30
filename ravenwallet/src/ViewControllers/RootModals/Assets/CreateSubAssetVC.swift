//
//  SendViewController.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2016-11-30.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit
import LocalAuthentication
import Core

 class CreateSubAssetVC : CreateAssetVC {

    init(walletManager: WalletManager, rootAssetName: String, initialAddress: String? = nil, initialRequest: PaymentRequest? = nil) {
        self.rootAssetName = rootAssetName
        super.init(walletManager: walletManager, initialAddress: initialAddress, initialRequest: initialRequest)
        self.operationType = .subAsset
        self.sender = SenderAsset(walletManager: self.walletManager, currency: self.currency, operationType: self.operationType)
        self.feeView = FeeAmountVC(walletManager: self.walletManager, sender: self.sender, operationType: self.operationType)
    }

    let rootAssetName: String
    
    override func setInitialData() {
        super.setInitialData()
        nameCell.content = rootAssetName + "/"
    }
    
    override func addButtonActions() {
        super.addButtonActions()
        nameCell.didChange = { text in
            self.nameStatus = .notVerified
            if !text.hasPrefix(self.rootAssetName + "/") {
                self.nameCell.textField.text = self.rootAssetName + "/"
            }
        }
        
        nameCell.didReturn = { textField in
            textField.resignFirstResponder()
            guard AssetValidator.shared.IsAssetNameASubasset(name: self.nameCell.textField.text!) else {
                return self.showAlert(title: S.Alert.error, message: S.Asset.errorAssetNameMessage, buttonLabel: S.Button.ok)
            }
        }
        
        nameCell.didVerifyTapped = { assetName in
            guard AssetValidator.shared.IsAssetNameASubasset(name: self.nameCell.textField.text!) else {
                self.nameCell.activityView.stopAnimating()
                self.nameCell.verify.label.isHidden = false
                return self.showAlert(title: S.Alert.error, message: S.Asset.errorAssetNameMessage, buttonLabel: S.Button.ok)
            }
            self.getAssetData(assetName: assetName!, callback: { isFound in
                self.nameCell.checkAvailabilityResult(isFound: isFound)
            })
        }
    }
    
    override func createAsset(amount:Satoshis) -> (BRAssetRef, BRAssetRef?) {
        let assetToSend = BRAsset.createAssetRef(asset: asset!, type: NEW_ASSET, amount: amount)
        //root asset
        let rootAsset = Asset.init(idAsset: -1, name: rootAssetName, amount: Satoshis(C.oneAsset), units: asset!.units, reissubale: asset!.reissubale, hasIpfs: asset!.reissubale, ipfsHash: asset!.ipfsHash, ownerShip: -1, hidden: -1, sort: -1)
        let brRootAsset = BRAsset.createAssetRef(asset: rootAsset, type: TRANSFER, amount: Satoshis(C.oneAsset))
        return (assetToSend, brRootAsset)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

