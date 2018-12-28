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

    //MARK - Private
    private let walletManager: WalletManager
    private let asset: Asset
    var parentVC: UIViewController?
    var modalPresenter:ModalPresenter? //ModalPresentable
    private let ipfs = ShadowButton(title: S.Asset.ipfs, type: .secondary)
    private let transfer = ShadowButton(title: S.Asset.transfer, type: .secondary)
    private let manage = ShadowButton(title: S.Asset.manageAsset, type: .secondary)
    private let burn = ShadowButton(title: S.Asset.burnAsset, type: .burn)

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
    }

    private func addConstraints() {
        ipfs.constrain([
            ipfs.topAnchor.constraint(equalTo: view.topAnchor, constant: C.padding[2]),
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
            burn.heightAnchor.constraint(equalToConstant: C.Sizes.buttonHeight),
            burn.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: E.isIPhoneXOrLater ? -C.padding[5] : -C.padding[2])
            ])
    }
    
    private func addSubscriptions() {
        //disable send button if isSyncing
        Store.subscribe(self, selector: { $0[Currencies.rvn].syncState != $1[Currencies.rvn].syncState },
                        callback: { state in
                            switch state[Currencies.rvn].syncState {
                            case .connecting, .syncing:
                                self.transfer.isEnabled = false
                                self.burn.isEnabled = false
                                self.manage.isEnabled = false
                            case .success:
                                self.transfer.isEnabled = true
                                self.burn.isEnabled = true
                                self.manage.isEnabled = true
                                self.setInitialData()//check if manage btn is enabled
                            }
        })
    }

    private func setStyle() {
        view.backgroundColor = .white
    }

    private func addActions() {
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
                let req = URLRequest(url: URL.init(string: "http://www.google.com")!)
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
    }
    
    private func setInitialData() {
        ipfs.isEnabled = true
        manage.isEnabled = true
        if !asset.isHasIpfs {
            ipfs.isEnabled = false
        }
        if !asset.isOwnerShip || !asset.isReissubale {//enable manage asset only if is owner and is resissubale
            manage.isEnabled = false
        }
    }
    

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
