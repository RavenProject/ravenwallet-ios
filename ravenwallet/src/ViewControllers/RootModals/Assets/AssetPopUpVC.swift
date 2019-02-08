//
//  AssetPopUpVC.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2016-11-30.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit
import Core

class AssetPopUpVC : UIViewController, Subscriber {

    //MARK - Public

    init(walletManager:WalletManager , asset: Asset) {
        self.walletManager = walletManager
        self.asset = asset
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK - Private
    private let walletManager: WalletManager
    private let asset: Asset
    var parentVC: UIViewController?
    var modalPresenter:ModalPresenter? //ModalPresentable
    private let ipfs = ShadowButton(title: S.Asset.ipfs, type: .secondary)
    private let transfer = ShadowButton(title: S.Asset.transfer, type: .secondary)
    private let manage = ShadowButton(title: S.Asset.manageAsset, type: .secondary)
    private let burn = ShadowButton(title: S.Asset.burnAsset, type: .burn)
    private let getAssetData = ShadowActivityButton(title: S.Asset.getDataAsset, type: .secondary)
    private var getAssetDataHeight: NSLayoutConstraint?
    var group: DispatchGroup?
    private let subAsset = ShadowButton(title: S.Asset.subAsset, type: .secondary)
    private let uniqueAsset = ShadowButton(title: S.Asset.uniqueAsset, type: .secondary)

    override func viewDidLoad() {
        addSubviews()
        addConstraints()
        setStyle()
        addActions()
        setInitialData()
        addSubscriptions()
    }

    private func addSubviews() {
        view.addSubview(ipfs)
        view.addSubview(manage)
        view.addSubview(transfer)
        view.addSubview(burn)
        view.addSubview(getAssetData)
        view.addSubview(subAsset)
        view.addSubview(uniqueAsset)
    }

    private func addConstraints() {
        subAsset.constrain([
            subAsset.topAnchor.constraint(equalTo: view.topAnchor, constant: C.padding[2]),
            subAsset.constraint(.leading, toView: view, constant: C.padding[2]),
            subAsset.constraint(.trailing, toView: view, constant: -C.padding[2]),
            subAsset.constraint(.height, constant: C.Sizes.buttonHeight)
            ])
        uniqueAsset.constrain([
            uniqueAsset.topAnchor.constraint(equalTo: subAsset.bottomAnchor, constant: C.padding[2]),
            uniqueAsset.constraint(.leading, toView: view, constant: C.padding[2]),
            uniqueAsset.constraint(.trailing, toView: view, constant: -C.padding[2]),
            uniqueAsset.constraint(.height, constant: C.Sizes.buttonHeight)
            ])
        ipfs.constrain([
            ipfs.topAnchor.constraint(equalTo: uniqueAsset.bottomAnchor, constant: C.padding[2]),
            ipfs.constraint(.leading, toView: view, constant: C.padding[2]),
            ipfs.constraint(.trailing, toView: view, constant: -C.padding[2]),
            ipfs.constraint(.height, constant: C.Sizes.buttonHeight)
            ])
        transfer.constrain([
            transfer.topAnchor.constraint(equalTo: ipfs.bottomAnchor, constant: C.padding[2]),
            transfer.constraint(.leading, toView: view, constant: C.padding[2]),
            transfer.constraint(.trailing, toView: view, constant: -C.padding[2]),
            transfer.constraint(.height, constant: C.Sizes.buttonHeight)
            ])
        manage.constrain([
            manage.topAnchor.constraint(equalTo: transfer.bottomAnchor, constant: C.padding[2]),
            manage.constraint(.leading, toView: view, constant: C.padding[2]),
            manage.constraint(.trailing, toView: view, constant: -C.padding[2]),
            manage.constraint(.height, constant: C.Sizes.buttonHeight)
            ])
        burn.constrain([
            burn.topAnchor.constraint(equalTo: manage.bottomAnchor, constant: C.padding[2]),
            burn.constraint(.leading, toView: view, constant: C.padding[2]),
            burn.constraint(.trailing, toView: view, constant: -C.padding[2]),
            burn.heightAnchor.constraint(equalToConstant: C.Sizes.buttonHeight)
            ])
        getAssetDataHeight = getAssetData.heightAnchor.constraint(equalToConstant: 0)
        getAssetData.constrain([
            getAssetData.topAnchor.constraint(equalTo: burn.bottomAnchor, constant: C.padding[2]),
            getAssetData.constraint(.leading, toView: view, constant: C.padding[2]),
            getAssetData.constraint(.trailing, toView: view, constant: -C.padding[2]),
            getAssetDataHeight,
            getAssetData.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: E.isIPhoneXOrLater ? -C.padding[5] : -C.padding[2])
            ])
    }
    
    private func addSubscriptions() {
        //disable send button if isSyncing
        Store.subscribe(self, selector: { $0[Currencies.rvn].syncState != $1[Currencies.rvn].syncState },
                        callback: { state in
                            switch state[Currencies.rvn].syncState {
                            case .connecting:
                                self.enableButtons(enable: false)
                            case .syncing:
                                self.enableButtons(enable: !self.walletManager.isSyncing())
                            case .success:
                                self.enableButtons(enable: true)
                            }
        })
    }

    private func setStyle() {
        view.backgroundColor = .white
    }

    private func addActions() {
        subAsset.tap = { [weak self] in
            guard let `self` = self, let modalTransitionDelegate = self.parent?.transitioningDelegate as? ModalTransitionDelegate else { return }
            modalTransitionDelegate.reset()
            self.dismiss(animated: true, completion: {
                Store.perform(action: RootModalActions.Present(modal: .subAsset(rootAssetName: self.asset.name, initialAddress: nil)))
            })
        }
        uniqueAsset.tap = { [weak self] in
            guard let `self` = self, let modalTransitionDelegate = self.parent?.transitioningDelegate as? ModalTransitionDelegate else { return }
            modalTransitionDelegate.reset()
            self.dismiss(animated: true, completion: {
                Store.perform(action: RootModalActions.Present(modal: .uniqueAsset(rootAssetName: self.asset.name, initialAddress: nil)))
            })
        }
        transfer.tap = { [weak self] in
            guard let `self` = self, let modalTransitionDelegate = self.parent?.transitioningDelegate as? ModalTransitionDelegate else { return }
            modalTransitionDelegate.reset()
            self.dismiss(animated: true, completion: {
                Store.perform(action: RootModalActions.Present(modal: .transferAsset(asset: self.asset, initialAddress: nil)))
            })
        }
        manage.tap = { [weak self] in
            guard let `self` = self, let modalTransitionDelegate = self.parent?.transitioningDelegate as? ModalTransitionDelegate else { return }
            modalTransitionDelegate.reset()
            self.dismiss(animated: true, completion: {
                Store.perform(action: RootModalActions.Present(modal: .manageOwnedAsset(asset: self.asset, initialAddress: nil)))
            })
        }
        ipfs.tap = { [weak self] in
            DispatchQueue.main.async {
                let browser = BRBrowserViewController()
                let ipfsUrl = C.ipfsHost + (self?.asset.ipfsHash)!
                let req = URLRequest(url: URL.init(string: ipfsUrl)!)
                browser.load(req)
                self?.present(browser, animated: true, completion: nil)
            }
        }
        
        burn.tap = { [weak self] in
            guard let `self` = self, let modalTransitionDelegate = self.parent?.transitioningDelegate as? ModalTransitionDelegate else { return }
            modalTransitionDelegate.reset()
            self.dismiss(animated: false, completion: {
                Store.perform(action: RootModalActions.Present(modal: .burnAsset(asset: self.asset)))
            })
        }
        
        getAssetData.tap = { [weak self] in
            guard let `self` = self else {return}
            DispatchQueue.main.async {
                self.getAssetData.activityView.startAnimating()
            }
            self.group = DispatchGroup()
            self.group!.enter()
            DispatchQueue.walletQueue.async {//BMEX TODO : need optimisation
                let asssetNamePointer = UnsafeMutablePointer<Int8>(mutating: (self.asset.name as NSString).utf8String)
                PeerManagerGetAssetData(self.walletManager.peerManager?.cPtr, Unmanaged.passUnretained(self).toOpaque(), asssetNamePointer, self.asset.name.count, {(info, assetRef) in
                    guard let info = info else { return }
                    let mySelf = Unmanaged<AssetPopUpVC>.fromOpaque(info).takeUnretainedValue()
                    DispatchQueue.main.async {
                        mySelf.getAssetData.activityView.stopAnimating()
                    }
                    if(assetRef != nil){
                        mySelf.walletManager.db!.updateAssetData(assetRef!)
                        DispatchQueue.main.async {
                            let amount = Double(assetRef!.pointee.amount / C.oneAsset)
                            let message = "\nname: " + mySelf.asset.name +  "\ntotal amount: " + String(amount) + "\nunits: "
                                + assetRef!.pointee.unit.description + "\nis-reissuable: " + assetRef!.pointee.reissuable.description + "\nhas-IPFS: "
                                + assetRef!.pointee.hasIPFS.description + "\nIPFS Hash: "
                                + assetRef!.pointee.ipfsHashString + ""
                            let paragraphStyle = NSMutableParagraphStyle()
                            paragraphStyle.alignment = NSTextAlignment.left
                            let attributeMessage = NSMutableAttributedString(
                                string: message,
                                attributes: [
                                    NSAttributedString.Key.paragraphStyle: paragraphStyle,
                                    NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body),
                                    NSAttributedString.Key.foregroundColor: UIColor.black
                            ])
                            mySelf.showAttributedAlert(title: S.Alerts.getDataAssetSuccessHeader, message:attributeMessage, buttonLabel: S.Button.ok)
                        }
                    }
                    else{
                        DispatchQueue.main.async {
                            mySelf.showAlert(title: S.Alert.error, message:String(format: S.Alerts.getDataAssetError, mySelf.asset.name), buttonLabel: S.Button.ok)
                        }
                    }
                    if(mySelf.group != nil){
                        mySelf.group?.leave()
                        mySelf.group = nil
                    }
                })
                let result = self.group!.wait(timeout: .now() + 2.0)
                if result == .timedOut {
                    self.group = nil
                    DispatchQueue.main.async {
                        self.getAssetData.activityView.stopAnimating()
                        self.showAlert(title: S.Alert.error, message:String(format: S.Alerts.getDataAssetError, self.asset.name), buttonLabel: S.Button.ok)
                    }
                }
            }
        }
    }
    
    private func setInitialData() {
        subAsset.isEnabled = true
        uniqueAsset.isEnabled = true
        ipfs.isEnabled = true
        transfer.isEnabled = true
        manage.isEnabled = true
        if !asset.isHasIpfs {
            ipfs.isEnabled = false
        }
        if !asset.isOwnerShip || !asset.isReissuable {//enable manage asset only if is owner and is resissubale
            manage.isEnabled = false
        }
        if !asset.isOwnerShip {//enable subAsset/uniqueAsset only if is owner
            subAsset.isEnabled = false
            uniqueAsset.isEnabled = false
        }
        if UserDefaults.hasActivatedExpertMode {
            getAssetDataHeight?.constant = C.Sizes.buttonHeight
            self.view.layoutIfNeeded()
        }
        if asset.amount == Satoshis.zero {
            burn.isEnabled = false
        }
        if AssetValidator.shared.IsAssetNameValid(name: asset.name).1 == .UNIQUE {
            subAsset.heightAnchor.constraint(equalToConstant: 0).isActive = true
            uniqueAsset.heightAnchor.constraint(equalToConstant: 0).isActive = true
            manage.heightAnchor.constraint(equalToConstant: 0).isActive = true
            ipfs.topAnchor.constraint(equalTo: view.topAnchor, constant: C.padding[2]).isActive = true
            transfer.bottomAnchor.constraint(equalTo: burn.topAnchor, constant: -C.padding[2]).isActive = true
            view.layoutIfNeeded()
        }
    }
    
    func enableButtons(enable:Bool) {
        self.subAsset.isEnabled = enable
        self.uniqueAsset.isEnabled = enable
        self.transfer.isEnabled = enable
        self.manage.isEnabled = enable
        self.burn.isEnabled = enable
        self.getAssetData.isEnabled = enable
        if enable {
            manage.isEnabled = true
            subAsset.isEnabled = true
            uniqueAsset.isEnabled = true
            if !asset.isOwnerShip || !asset.isReissuable {//enable manage asset only if is owner and is resissubale
                manage.isEnabled = false
            }
            if !asset.isOwnerShip {//enable subAsset/uniqueAsset only if is owner
                subAsset.isEnabled = false
                uniqueAsset.isEnabled = false
            }
            if asset.amount == Satoshis.zero {
                burn.isEnabled = false
            }
        }
    }
}

extension AssetPopUpVC : ModalDisplayable {
    var faqArticleId: String? {
        return nil
    }

    var modalTitle: String {
        return "\(asset.name)"
    }
}
