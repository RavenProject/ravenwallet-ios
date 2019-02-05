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

class BurnAssetVC : UIViewController, Subscriber, ModalPresentable, Trackable {
    
    //MARK - Public
    var presentVerifyPin: ((String, @escaping ((String) -> Void))->Void)?
    var onPublishSuccess: (()->Void)?
    var parentView: UIView? //ModalPresentable
    var isPresentedFromLock = false

    init(asset: Asset, walletManager: WalletManager) {
        self.asset = asset
        self.walletManager = walletManager
        self.sender = SenderAsset(walletManager: self.walletManager, currency: self.currency, operationType: .burnAsset)
        super.init(nibName: nil, bundle: nil)
    }

    private let asset: Asset
    private let sender: SenderAsset
    private let walletManager: WalletManager
    private let confirmTransitioningDelegate = PinTransitioningDelegate()
    private let currency: CurrencyDef = Currencies.rvn //BMEX
    private var balance: UInt64 = 0

    override func viewDidLoad() {
        self.parent?.view.isHidden = true
        addSubscriptions()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let feeAmount = self.sender.feeForTx(amount: UInt64(100000000))
        if feeAmount == nil {
            showError()
            return
        }
        if feeAmount! > balance {
            showError()
            return
        }
        let alert = UIAlertController(title: S.Alerts.BurnAsset.title, message: S.Alerts.BurnAsset.body, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: S.Button.cancel, style: .default, handler: { _ in
            self.dismiss(animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: S.Button.ok, style: .destructive, handler: { _ in
            DispatchQueue.main.async {
                self.sendTapped()
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func addSubscriptions() {
        Store.subscribe(self, selector: { $0[self.currency].balance != $1[self.currency].balance },
                        callback: { [unowned self] in
                            if let balance = $0[self.currency].balance {
                                self.balance = balance
                            }
        })
    }
    
    func showError() {
        self.dismiss(animated: true, completion: nil)
        showAlert(title: S.Alert.error, message: S.Send.insufficientFunds, buttonLabel: S.Button.ok)
    }

    func sendTapped() {
        if sender.transaction == nil {
            //sender
            let assetToBurn: BRAssetRef = BRAsset.createAssetRef(asset: asset, type: TRANSFER, amount: asset.amount)
            guard sender.createAssetTransaction(amount: 0, to: "", asset: assetToBurn) else {
                return showAlert(title: S.Alert.error, message: S.Send.createTransactionError, buttonLabel: S.Button.ok)
            }
        }
        self.send()
        return
    }

    private func send() {
        guard let rate = currency.state.currentRate else { return }
        guard let feePerKb = walletManager.wallet?.feePerKb else { return }
        
        sender.send(biometricsMessage: S.VerifyPin.touchIdMessage,
                    rate: rate,
                    comment: "",
                    feePerKb: feePerKb,
                    verifyPinFunction: { [weak self] pinValidationCallback in
                        self?.presentVerifyPin?(S.VerifyPin.authorize) { [weak self] pin in
                            self!.parent?.view.isFrameChangeBlocked = false
                            pinValidationCallback(pin)
                        }
            }, completion: { [weak self] result in
                switch result {
                case .success:
                    self!.dismiss(animated: true, completion: {
                        guard let myself = self else { return }
                        Store.trigger(name: .showStatusBar)
                        if myself.isPresentedFromLock {
                            Store.trigger(name: .loginFromSend)
                        }
                        myself.onPublishSuccess?()
                    })
                    self?.saveEvent("send.success")
                case .creationError(let message):
                    self!.showAlert(title: S.Send.createTransactionError, message: message, buttonLabel: S.Button.ok)
                    self?.saveEvent("send.publishFailed", attributes: ["errorMessage": message])
                case .publishFailure(let error):
                    if case .posixError(let code, let description) = error {
                        self!.showAlert(title: S.Alerts.sendFailure, message: "\(description) (\(code))", buttonLabel: S.Button.ok)
                        self?.saveEvent("send.publishFailed", attributes: ["errorMessage": "\(description) (\(code))"])
                    }
                }
        })

    }

    private func showError(title: String, message: String, ignore: @escaping () -> Void) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: S.Button.ignore, style: .default, handler: { _ in
            ignore()
        }))
        alertController.addAction(UIAlertAction(title: S.Button.cancel, style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


extension BurnAssetVC : ModalDisplayable {
    var faqArticleId: String? {
        return nil
    }
    
    var modalTitle: String {
        return ""
    }
}

