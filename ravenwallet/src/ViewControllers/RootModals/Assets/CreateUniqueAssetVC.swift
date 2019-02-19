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

 class CreateUniqueAssetVC : CreateAssetVC {

    init(walletManager: WalletManager, rootAssetName: String, initialAddress: String? = nil, initialRequest: PaymentRequest? = nil) {
        self.rootAssetName = rootAssetName
        super.init(walletManager: walletManager, initialAddress: initialAddress, initialRequest: initialRequest)
        self.operationType = .uniqueAsset
        self.sender = SenderAsset(walletManager: self.walletManager, currency: self.currency, operationType: self.operationType)
        self.feeView = FeeAmountVC(walletManager: self.walletManager, sender: self.sender, operationType: self.operationType)
    }

    let rootAssetName: String
    
    override func setInitialData() {
        super.setInitialData()
        nameCell.content = rootAssetName + "#"
    }
    
    override func addSubviews() {
        view.backgroundColor = .white
        view.addSubview(nameCell)
        view.addSubview(addressCell)
        view.addSubview(ipfsCell)
        view.addSubview(createButton)
        createButton.addSubview(activityView)
    }
    
    override func addConstraints() {
        nameCell.constrainTopCorners(height: createNameAssetHeight)
        addressCell.constrain([
            addressCell.widthAnchor.constraint(equalTo: nameCell.widthAnchor),
            addressCell.topAnchor.constraint(equalTo: nameCell.bottomAnchor),
            addressCell.leadingAnchor.constraint(equalTo: nameCell.leadingAnchor),
            addressCell.heightAnchor.constraint(equalToConstant: !UserDefaults.hasActivatedExpertMode ? 0.0 : createAddressHeight) ])

        ipfsCell.constrain([
            ipfsCell.widthAnchor.constraint(equalTo: addressCell.widthAnchor),
            ipfsCell.topAnchor.constraint(equalTo: addressCell.bottomAnchor),
            ipfsCell.leadingAnchor.constraint(equalTo: addressCell.leadingAnchor),
            ipfsCell.heightAnchor.constraint(equalToConstant: SendCell.defaultHeight - C.padding[2]) ])
        
        addChild(feeView, layout: {
            feeView.view.constrain([
                feeView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                feeView.view.topAnchor.constraint(equalTo: ipfsCell.bottomAnchor),
                feeView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor) ])
        })
        
        createButton.constrain([
            createButton.constraint(.leading, toView: view, constant: C.padding[2]),
            createButton.constraint(.trailing, toView: view, constant: -C.padding[2]),
            createButton.constraint(toBottom: feeView.view, constant: verticalButtonPadding),
            createButton.constraint(.height, constant: C.Sizes.buttonHeight),
            createButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: E.isIPhoneXOrLater ? -C.padding[5] : -C.padding[2]) ])
        
        activityView.constrain([
            activityView.constraint(.trailing, toView: createButton, constant: -C.padding[2]),
            activityView.centerYAnchor.constraint(equalTo: createButton.centerYAnchor) ])
    }
    
    override func addButtonActions() {
        super.addButtonActions()
        nameCell.didChange = { text in
            self.nameStatus = .notVerified
            if !text.hasPrefix(self.rootAssetName + "#") {
                self.nameCell.textField.text = self.rootAssetName + "#"
            }
        }
    }
    
    override func sendTapped() {
        if addressCell.textField.isFirstResponder {
            addressCell.textField.resignFirstResponder()
        }
        
        guard self.nameCell.textField.text != nil else {
            return showAlert(title: S.Alert.error, message: S.Asset.noName, buttonLabel: S.Button.ok)
        }
        
        guard self.nameCell.textField.text?.isEmpty == false else {
            return showAlert(title: S.Alert.error, message: S.Asset.noName, buttonLabel: S.Button.ok)
        }
        
        guard AssetValidator.shared.validateName(name: self.nameCell.textField.text!, forType: .UNIQUE) else {
            return showAlert(title: S.Alert.error, message: S.Asset.errorAssetNameMessage, buttonLabel: S.Button.ok)
        }
        
        if self.nameStatus == .notAvailable {
            return showAlert(title: S.Alert.error, message: S.Asset.noAvailable, buttonLabel: S.Button.ok)
        }
        
        guard let address = addressCell.address else {
            return showAlert(title: S.Alert.error, message: S.Send.noAddress, buttonLabel: S.Button.ok)
        }
        
        guard currency.state.fees != nil else {
            return showAlert(title: S.Alert.error, message: S.Send.noFeesError, buttonLabel: S.Button.ok)
        }
        guard address.isValidAddress else {
            let message = String.init(format: S.Send.invalidAddressMessage, currency.name)
            return showAlert(title: S.Send.invalidAddressTitle, message: message, buttonLabel: S.Button.ok)
        }
        
        //BMEX Todo : manage maxOutputAmount and minOutputAmount
        guard feeAmount <= balance else {
            return showAlert(title: S.Alert.error, message: S.Send.insufficientFunds, buttonLabel: S.Button.ok)
        }
        
        if ipfsCell.hasIpfs {
            guard let ipfsHash = ipfsCell.ipfsHash else {
                return showAlert(title: S.Alert.error, message: S.Asset.noIpfsHash, buttonLabel: S.Button.ok)
            }
            guard AssetValidator.shared.IsIpfsHashValid(ipfsHash: ipfsHash) else {
                let message = String.init(format: S.Asset.invalidIpfsHashMessage, currency.name)
                return showAlert(title: S.Send.invalidAddressTitle, message: message, buttonLabel: S.Button.ok)
            }
        }
        let amount = Satoshis(C.uniqueAsset)
        //if all ok check name availability if not checked
        if nameStatus == .notVerified {
            createButton.label.text = S.Asset.availability
            activityView.startAnimating()
            getAssetData(assetName: self.nameCell.textField.text!) { nameStatus in
                DispatchQueue.main.async {
                    self.activityView.stopAnimating()
                    self.createButton.label.text = S.Asset.create
                    self.nameCell.checkAvailabilityResult(nameStatus: nameStatus)
                    if(nameStatus == .notAvailable){
                        return self.showAlert(title: S.Alert.error, message: S.Asset.noAvailable, buttonLabel: S.Button.ok)
                    }
                    else if(nameStatus == .notVerified){
                        return self.showAlert(title: S.Alert.error, message: S.Asset.notVerifiedName, buttonLabel: S.Button.ok)
                    }
                    else {
                        self.showConfirmationView(amount: amount, address: address, units: UInt8(exactly: self.unitsCell.amount!.rawValue / 100000000)!, reissubale:self.reissubaleCell.btnCheckBox.isSelected ? 1 : 0)
                    }
                }
            }
        }
        else
        {
            showConfirmationView(amount: amount, address: address, units: 0, reissubale: 0)
        }
        return
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

