//
//  ModalPresenter.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2016-10-25.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit
import LocalAuthentication

class ModalPresenter : Subscriber {

    //MARK: - Public
    let walletManager: WalletManager
    let supportCenter = SupportWebViewController()
    
    init(walletManager: WalletManager, window: UIWindow, apiClient: BRAPIClient) {
        self.window = window
        self.walletManager = walletManager
        self.modalTransitionDelegate = ModalTransitionDelegate(type: .regular)
        self.wipeNavigationDelegate = StartNavigationDelegate()
        self.noAuthApiClient = apiClient
        addSubscriptions()
    }

    deinit {
        Store.unsubscribe(self)
    }
    
    //MARK: - Private
    private let window: UIWindow
    private let alertHeight: CGFloat = 260.0
    private let modalTransitionDelegate: ModalTransitionDelegate
    private let messagePresenter = MessageUIPresenter()
    private let securityCenterNavigationDelegate = SecurityCenterNavigationDelegate()
    let verifyPinTransitionDelegate = PinTransitioningDelegate()
    private let noAuthApiClient: BRAPIClient
    private var currentRequest: PaymentRequest?
    private var reachability = ReachabilityMonitor()
    private var notReachableAlert: InAppAlert?
    private let wipeNavigationDelegate: StartNavigationDelegate

    private func addSubscriptions() {

        Store.lazySubscribe(self,
                        selector: { $0.rootModal != $1.rootModal},
                        callback: { [weak self] in self?.presentModal($0.rootModal) })
        
        Store.lazySubscribe(self,
                        selector: { $0.alert != $1.alert && $1.alert != .none },
                        callback: { [weak self] in self?.handleAlertChange($0.alert) })
        
        Store.subscribe(self, name: .presentFaq(""), callback: { [weak self] in
            guard let trigger = $0 else { return }
            if case .presentFaq(let articleId) = trigger {
                self?.presentFaq(articleId: articleId)
            }
        })

        //Subscribe to prompt actions
        Store.subscribe(self, name: .promptUpgradePin, callback: { [weak self] _ in
            self?.presentUpgradePin()
        })
        Store.subscribe(self, name: .promptRecoveryPhrase, callback: { [weak self] _ in
            self?.presentWriteRecoveryPhrase()
        })
        Store.subscribe(self, name: .promptBiometrics, callback: { [weak self] _ in
            self?.presentBiometricsSetting()
        })
        Store.subscribe(self, name: .promptShareData, callback: { [weak self] _ in
            self?.promptShareData()
        })
        Store.subscribe(self, name: .openFile(Data()), callback: { [weak self] in
            guard let trigger = $0 else { return }
            if case .openFile(let file) = trigger {
                self?.handleFile(file)
            }
        })
        
        Store.subscribe(self, name: .recommendRescan(walletManager.currency), callback: { [weak self] _ in
            guard let myself = self else { return }
            self?.presentRescan(currency: myself.walletManager.currency)
        })
        
        Store.subscribe(self, name: .recommendRescanAsset, callback: { [weak self] _ in
            self?.presentRescanAsset()
        })

        //URLs
        Store.subscribe(self, name: .receivedPaymentRequest(nil), callback: { [weak self] in
            guard let trigger = $0 else { return }
            if case let .receivedPaymentRequest(request) = trigger {
                if let request = request {
                    self?.handlePaymentRequest(request: request)
                }
            }
        })
        Store.subscribe(self, name: .scanQr, callback: { [weak self] _ in
            self?.handleScanQrURL()
        })
        Store.subscribe(self, name: .copyWalletAddresses(nil, nil), callback: { [weak self] in
            guard let trigger = $0 else { return }
            if case .copyWalletAddresses(let success, let error) = trigger {
                self?.handleCopyAddresses(success: success, error: error)
            }
        })
        Store.subscribe(self, name: .authenticateForBitId("", {_ in}), callback: { [weak self] in
            guard let trigger = $0 else { return }
            if case .authenticateForBitId(let prompt, let callback) = trigger {
                self?.authenticateForBitId(prompt: prompt, callback: callback)
            }
        })
        reachability.didChange = { [weak self] isReachable in
            if isReachable {
                self?.hideNotReachable()
            } else {
                self?.showNotReachable()
            }
        }
        Store.subscribe(self, name: .lightWeightAlert(""), callback: { [weak self] in
            guard let trigger = $0 else { return }
            if case let .lightWeightAlert(message) = trigger {
                self?.showLightWeightAlert(message: message)
            }  
        })
        Store.subscribe(self, name: .showAlert(nil), callback: { [weak self] in
            guard let trigger = $0 else { return }
            if case let .showAlert(alert) = trigger {
                if let alert = alert {
                    self?.topViewController?.present(alert, animated: true, completion: nil)
                }
            }
        })
        Store.subscribe(self, name: .wipeWalletNoPrompt, callback: { [weak self] _ in
            self?.wipeWalletNoPrompt()
        })
        
        Store.subscribe(self, name: .selectAddressBook(nil, nil), callback: { [weak self] in
            guard let trigger = $0 else { return }
            if case .selectAddressBook(let addressBookType, let callback) = trigger {
                self?.presentAddressBook(type: addressBookType, callback: callback)
            }
        })
        
        Store.subscribe(self, name: .haptic(.light)) { [unowned self] in
            guard let trigger = $0 else { return }
            if case let .haptic(style) = trigger {
                let impact = UIImpactFeedbackGenerator(style: style)
                impact.impactOccurred()
            }
        }
    }

    private func presentModal(_ type: RootModal, configuration: ((UIViewController) -> Void)? = nil) {
        guard type != .loginScan else { return presentLoginScan() }
        guard let vc = rootModalViewController(type) else {
            Store.perform(action: RootModalActions.Present(modal: .none))
            return
        }
        vc.transitioningDelegate = modalTransitionDelegate
        vc.modalPresentationStyle = .overFullScreen
        vc.modalPresentationCapturesStatusBarAppearance = true
        configuration?(vc)
        topViewController?.present(vc, animated: true) {
            Store.perform(action: RootModalActions.Present(modal: .none))
            Store.trigger(name: .hideStatusBar)
        }
    }

    private func handleAlertChange(_ type: AlertType) {
        guard type != .none else { return }
        presentAlert(type, completion: {
            Store.perform(action: Alert.Hide())
        })
    }

    func presentAlert(_ type: AlertType, completion: @escaping ()->Void) {
        let alertView = AlertView(type: type)
        let window = UIApplication.shared.keyWindow!
        let size = window.bounds.size
        window.addSubview(alertView)

        let topConstraint = alertView.constraint(.top, toView: window, constant: size.height)
        alertView.constrain([
            alertView.constraint(.width, constant: size.width),
            alertView.constraint(.height, constant: alertHeight + 25.0),
            alertView.constraint(.leading, toView: window, constant: nil),
            topConstraint ])
        window.layoutIfNeeded()

        UIView.spring(0.6, animations: {
            topConstraint?.constant = size.height - self.alertHeight
            window.layoutIfNeeded()
        }, completion: { _ in
            alertView.animate()
            UIView.spring(0.6, delay: 2.0, animations: {
                topConstraint?.constant = size.height
                window.layoutIfNeeded()
            }, completion: { _ in
                //TODO - Make these callbacks generic
                if case .recoveryPhraseSet(let callback) = type {
                    callback()
                }
                if case .pinSet(let callback) = type {
                    callback()
                }
                if case .sweepSuccess(let callback) = type {
                    callback()
                }
                completion()
                alertView.removeFromSuperview()
            })
        })
    }

    func presentFaq(articleId: String? = nil) {
        supportCenter.modalPresentationStyle = .overFullScreen
        supportCenter.modalPresentationCapturesStatusBarAppearance = true

        let url = articleId == nil ? "/support?" : "/support/\(articleId!)"

        supportCenter.navigate(to: url)
        topViewController?.presentFullScreen(supportCenter, animated: true, completion: {})
    }

    private func rootModalViewController(_ type: RootModal) -> UIViewController? {
        print("perform rootModalViewController %@ called", type)
        switch type {
        case .none:
            return nil
        case .send(let currency):
            return makeSendView(currency: currency)
        case .sendWithAddress(let currency, let initialAddress)://BMEX
            return makeSendView(currency: currency, initialAddress: initialAddress)
        case .transferAsset(let asset, let initialAddress)://BMEX
            return makeTransferAssetView(asset: asset, initialAddress: initialAddress)
        case .createAsset(let initialAddress)://BMEX
            return makeCreateAssetView(initialAddress: initialAddress)
        case .subAsset(let rootAssetName, let initialAddress)://BMEX
            return makeSubAssetView(rootAssetName: rootAssetName, initialAddress: initialAddress)
        case .uniqueAsset(let rootAssetName, let initialAddress)://BMEX
            return makeUniqueAssetView(rootAssetName: rootAssetName, initialAddress: initialAddress)
        case .manageOwnedAsset(let asset, let initialAddress)://BMEX
            return makeManageOwnedAssetView(asset: asset, initialAddress: initialAddress)
        case .burnAsset(let asset)://BMEX
            return makeBurnAssetView(asset: asset)
        case .receive(let currency, let isRequestAmountVisible, let initialAddress):
            return receiveView(currency: currency, isRequestAmountVisible: isRequestAmountVisible, initialAddress: initialAddress)
        case .selectAsset(let asset):
            return selectAssetView(asset: asset)//BMEX
        case .addressBook(let currency, let initialAddress, let actionAddressType, let callback):
            return makeAddAddressBookView(currency: currency, initialAddress: initialAddress, type: actionAddressType, callback: callback)
        case .loginScan:
            return nil //The scan view needs a custom presentation
        case .loginAddress:
            return receiveView(currency: Currencies.rvn, isRequestAmountVisible: false)
        case .requestAmount(let currency):
            guard let wallet = walletManager.wallet else { return nil }
            let requestVc = RequestAmountViewController(currency: currency, wallet: wallet)
            requestVc.presentEmail = { [weak self] bitcoinURL, image in
                self?.messagePresenter.presenter = self?.topViewController
                self?.messagePresenter.presentMailCompose(bitcoinURL: bitcoinURL, image: image)
            }
            requestVc.presentText = { [weak self] bitcoinURL, image in
                self?.messagePresenter.presenter = self?.topViewController
                self?.messagePresenter.presentMessageCompose(bitcoinURL: bitcoinURL, image: image)
            }
            return ModalViewController(childViewController: requestVc)
        case .updateIpfs:
            return showUpdateIpfs()
        }
        
    }
    
    private func showUpdateIpfs() -> UIViewController?{
        let updateIpfs = UpdateIPFSUrlVC()
        let root = ModalViewController(childViewController: updateIpfs)
        updateIpfs.parentView = root.view
        return root
    }

    private func makeSendView(currency: CurrencyDef, initialAddress: String? = nil) -> UIViewController? {
        guard !currency.state.isRescanning else {
            let alert = UIAlertController(title: S.Alert.error, message: S.Send.isRescanning, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: S.Button.ok, style: .cancel, handler: nil))
            topViewController?.present(alert, animated: true, completion: nil)
            return nil
        }
        let sendVC = SendViewController(sender: Sender(walletManager: walletManager, currency: currency),
                                        walletManager: walletManager,
                                        initialAddress: initialAddress,//BMEX
                                        initialRequest: currentRequest,
                                        currency: currency)
        currentRequest = nil

        if Store.state.isLoginRequired {
            sendVC.isPresentedFromLock = true
        }

        let root = ModalViewController(childViewController: sendVC)
        sendVC.presentScan = presentScan(parent: root, currency: currency)
        sendVC.presentVerifyPin = { [weak self, weak root] bodyText, success in
            guard let myself = self else { return }
            let vc = VerifyPinViewController(bodyText: bodyText, pinLength: Store.state.pinLength, walletManager: myself.walletManager, success: success)
            vc.transitioningDelegate = self?.verifyPinTransitionDelegate
            vc.modalPresentationStyle = .overFullScreen
            vc.modalPresentationCapturesStatusBarAppearance = true
            root?.view.isFrameChangeBlocked = true
            root?.present(vc, animated: true, completion: nil)
        }
        sendVC.onPublishSuccess = { [weak self] in
            self?.presentAlert(.sendSuccess, completion: {})
        }
        return root
    }
    
    
    private func makeTransferAssetView(asset: Asset, initialAddress: String? = nil) -> UIViewController? {
        guard !Currencies.rvn.state.isRescanning else {
            let alert = UIAlertController(title: S.Alert.error, message: S.Send.isRescanning, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: S.Button.ok, style: .cancel, handler: nil))
            topViewController?.present(alert, animated: true, completion: nil)
            return nil
        }
        let transferAssetVC = TransferAssetVC(asset: asset, walletManager: walletManager, initialAddress: initialAddress, initialRequest: currentRequest)
        currentRequest = nil
        
        if Store.state.isLoginRequired {
            transferAssetVC.isPresentedFromLock = true
        }
        
        let root = ModalViewController(childViewController: transferAssetVC)
        transferAssetVC.presentScan = presentScan(parent: root, currency: Currencies.rvn)
        transferAssetVC.presentVerifyPin = { [weak self, weak root] bodyText, success in
            guard let myself = self else { return }
            let vc = VerifyPinViewController(bodyText: bodyText, pinLength: Store.state.pinLength, walletManager: myself.walletManager, success: success)
            vc.transitioningDelegate = self?.verifyPinTransitionDelegate
            vc.modalPresentationStyle = .overFullScreen
            vc.modalPresentationCapturesStatusBarAppearance = true
            root?.view.isFrameChangeBlocked = true
            root?.present(vc, animated: true, completion: nil)
        }
        transferAssetVC.onPublishSuccess = { [weak self] in
            guard let myself = self else { return }
            self?.presentAlert(.sendAssetSuccess, completion: {
                if let allAssetVC = myself.topViewController as? AllAssetVC {
                    self?.pushAccountView(currency: Currencies.rvn, animated: true, nc: allAssetVC.navigationController!)
                }
                else {
                    self?.showAccountView(currency: Currencies.rvn, animated: true)
                }
            })
        }
        return root
    }
    
    private func makeCreateAssetView(initialAddress: String? = nil) -> UIViewController? {
        guard !Currencies.rvn.state.isRescanning else {
            let alert = UIAlertController(title: S.Alert.error, message: S.Send.isRescanning, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: S.Button.ok, style: .cancel, handler: nil))
            topViewController?.present(alert, animated: true, completion: nil)
            return nil
        }
        let createAssetVC = CreateAssetVC(walletManager: walletManager, initialAddress: initialAddress, initialRequest: currentRequest)
        currentRequest = nil
        
        if Store.state.isLoginRequired {
            createAssetVC.isPresentedFromLock = true
        }
        
        let root = ModalViewController(childViewController: createAssetVC)
        createAssetVC.presentScan = presentScan(parent: root, currency: Currencies.rvn)
        createAssetVC.presentVerifyPin = { [weak self, weak root] bodyText, success in
            guard let myself = self else { return }
            let vc = VerifyPinViewController(bodyText: bodyText, pinLength: Store.state.pinLength, walletManager: myself.walletManager, success: success)
            vc.transitioningDelegate = self?.verifyPinTransitionDelegate
            vc.modalPresentationStyle = .overFullScreen
            vc.modalPresentationCapturesStatusBarAppearance = true
            root?.view.isFrameChangeBlocked = true
            root?.present(vc, animated: true, completion: nil)
        }
        createAssetVC.onPublishSuccess = { txHash in
            let qrImage = UIImage.qrCode(data: txHash.data(using: .utf8)!, color: CIColor(color: .black))?.resize(CGSize(width: 186, height: 186))!
            self.topViewController?.showImageAlert(title: S.Alerts.createSuccess, message: S.Alerts.createSuccessSubheader + txHash + S.Alerts.assetAppearance, image: qrImage!, buttonLabel: S.Button.copy, callback: { _ in
                Store.trigger(name: .lightWeightAlert(S.Receive.copied))
                UIPasteboard.general.string = txHash
            })
        }
        return root
    }
    
    private func makeSubAssetView(rootAssetName:String, initialAddress: String? = nil) -> UIViewController? {
        guard !Currencies.rvn.state.isRescanning else {
            let alert = UIAlertController(title: S.Alert.error, message: S.Send.isRescanning, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: S.Button.ok, style: .cancel, handler: nil))
            topViewController?.present(alert, animated: true, completion: nil)
            return nil
        }
        let createAssetVC = CreateSubAssetVC(walletManager: walletManager, rootAssetName: rootAssetName, initialAddress: initialAddress, initialRequest: currentRequest)
        currentRequest = nil
        
        if Store.state.isLoginRequired {
            createAssetVC.isPresentedFromLock = true
        }
        
        let root = ModalViewController(childViewController: createAssetVC)
        createAssetVC.presentScan = presentScan(parent: root, currency: Currencies.rvn)
        createAssetVC.presentVerifyPin = { [weak self, weak root] bodyText, success in
            guard let myself = self else { return }
            let vc = VerifyPinViewController(bodyText: bodyText, pinLength: Store.state.pinLength, walletManager: myself.walletManager, success: success)
            vc.transitioningDelegate = self?.verifyPinTransitionDelegate
            vc.modalPresentationStyle = .overFullScreen
            vc.modalPresentationCapturesStatusBarAppearance = true
            root?.view.isFrameChangeBlocked = true
            root?.present(vc, animated: true, completion: nil)
        }
        createAssetVC.onPublishSuccess = { txHash in
            let qrImage = UIImage.qrCode(data: txHash.data(using: .utf8)!, color: CIColor(color: .black))?.resize(CGSize(width: 186, height: 186))!
            self.topViewController?.showImageAlert(title: S.Alerts.createSuccess, message: S.Alerts.createSuccessSubheader + txHash + S.Alerts.assetAppearance, image: qrImage!, buttonLabel: S.Button.copy, callback: { _ in
                Store.trigger(name: .lightWeightAlert(S.Receive.copied))
                UIPasteboard.general.string = txHash
            })

        }
        return root
    }
    
    private func makeUniqueAssetView(rootAssetName:String, initialAddress: String? = nil) -> UIViewController? {
        guard !Currencies.rvn.state.isRescanning else {
            let alert = UIAlertController(title: S.Alert.error, message: S.Send.isRescanning, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: S.Button.ok, style: .cancel, handler: nil))
            topViewController?.present(alert, animated: true, completion: nil)
            return nil
        }
        let createAssetVC = CreateUniqueAssetVC(walletManager: walletManager, rootAssetName: rootAssetName, initialAddress: initialAddress, initialRequest: currentRequest)
        currentRequest = nil
        
        if Store.state.isLoginRequired {
            createAssetVC.isPresentedFromLock = true
        }
        
        let root = ModalViewController(childViewController: createAssetVC)
        createAssetVC.presentScan = presentScan(parent: root, currency: Currencies.rvn)
        createAssetVC.presentVerifyPin = { [weak self, weak root] bodyText, success in
            guard let myself = self else { return }
            let vc = VerifyPinViewController(bodyText: bodyText, pinLength: Store.state.pinLength, walletManager: myself.walletManager, success: success)
            vc.transitioningDelegate = self?.verifyPinTransitionDelegate
            vc.modalPresentationStyle = .overFullScreen
            vc.modalPresentationCapturesStatusBarAppearance = true
            root?.view.isFrameChangeBlocked = true
            root?.present(vc, animated: true, completion: nil)
        }
        createAssetVC.onPublishSuccess = { txHash in
            let qrImage = UIImage.qrCode(data: txHash.data(using: .utf8)!, color: CIColor(color: .black))?.resize(CGSize(width: 186, height: 186))!
            self.topViewController?.showImageAlert(title: S.Alerts.createSuccess, message: S.Alerts.createSuccessSubheader + txHash + S.Alerts.assetAppearance, image: qrImage!, buttonLabel: S.Button.copy, callback: { _ in
                Store.trigger(name: .lightWeightAlert(S.Receive.copied))
                UIPasteboard.general.string = txHash
            })
        }
        return root
    }
    
    private func makeManageOwnedAssetView(asset: Asset, initialAddress: String? = nil) -> UIViewController? {
        guard !Currencies.rvn.state.isRescanning else {
            let alert = UIAlertController(title: S.Alert.error, message: S.Send.isRescanning, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: S.Button.ok, style: .cancel, handler: nil))
            topViewController?.present(alert, animated: true, completion: nil)
            return nil
        }
        let manageOwnedAssetVC = ManageOwnedAssetVC(asset: asset, walletManager: walletManager, initialAddress: initialAddress, initialRequest: currentRequest)
        currentRequest = nil
        
        if Store.state.isLoginRequired {
            manageOwnedAssetVC.isPresentedFromLock = true
        }
        
        let root = ModalViewController(childViewController: manageOwnedAssetVC)
        manageOwnedAssetVC.presentScan = presentScan(parent: root, currency: Currencies.rvn)
        manageOwnedAssetVC.presentVerifyPin = { [weak self, weak root] bodyText, success in
            guard let myself = self else { return }
            let vc = VerifyPinViewController(bodyText: bodyText, pinLength: Store.state.pinLength, walletManager: myself.walletManager, success: success)
            vc.transitioningDelegate = self?.verifyPinTransitionDelegate
            vc.modalPresentationStyle = .overFullScreen
            vc.modalPresentationCapturesStatusBarAppearance = true
            root?.view.isFrameChangeBlocked = true
            root?.present(vc, animated: true, completion: nil)
        }
        manageOwnedAssetVC.onPublishSuccess = { [weak self] in
            self?.presentAlert(.reissueAssetSuccess, completion: {})
        }
        return root
    }
    
    private func makeBurnAssetView(asset: Asset) -> UIViewController? {
        guard !Currencies.rvn.state.isRescanning else {
            let alert = UIAlertController(title: S.Alert.error, message: S.Send.isRescanning, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: S.Button.ok, style: .cancel, handler: nil))
            topViewController?.present(alert, animated: true, completion: nil)
            return nil
        }
        let burnAssetVC = BurnAssetVC(asset: asset, walletManager: walletManager)
        currentRequest = nil
        
        if Store.state.isLoginRequired {
            burnAssetVC.isPresentedFromLock = true
        }
        
        let root = ModalViewController(childViewController: burnAssetVC)
        burnAssetVC.presentVerifyPin = { [weak self, weak root] bodyText, success in
            guard let myself = self else { return }
            let vc = VerifyPinViewController(bodyText: bodyText, pinLength: Store.state.pinLength, walletManager: myself.walletManager, success: success)
            vc.didCancel = {
                DispatchQueue.main.async {
                    burnAssetVC.dismiss(animated: true, completion: nil)
                }
            }
            vc.transitioningDelegate = self?.verifyPinTransitionDelegate
            vc.modalPresentationStyle = .overFullScreen
            vc.modalPresentationCapturesStatusBarAppearance = true
            root?.view.isFrameChangeBlocked = true
            root?.present(vc, animated: true, completion: nil)
        }
        burnAssetVC.onPublishSuccess = { [weak self] in
            guard let myself = self else { return }
            self?.presentAlert(.burnAssetSuccess, completion: {
                if let allAssetVC = myself.topViewController as? AllAssetVC {
                    self?.pushAccountView(currency: Currencies.rvn, animated: true, nc: allAssetVC.navigationController!)
                }
                else {
                    self?.showAccountView(currency: Currencies.rvn, animated: true)
                }
            })
        }
        return root
    }

    private func receiveView(currency: CurrencyDef, isRequestAmountVisible: Bool, initialAddress: String? = nil) -> UIViewController? {
        let receiveVC = ReceiveViewController(currency: currency, isRequestAmountVisible: isRequestAmountVisible, initialAddress: initialAddress)
        let root = ModalViewController(childViewController: receiveVC)
        receiveVC.presentEmail = { [weak self, weak root] address, image in
            guard let root = root, let uri = currency.addressURI(address) else { return }
            self?.messagePresenter.presenter = root
            self?.messagePresenter.presentMailCompose(uri: uri, image: image)
        }
        receiveVC.presentText = { [weak self, weak root] address, image in
            guard let root = root, let uri = currency.addressURI(address) else { return }
            self?.messagePresenter.presenter = root
            self?.messagePresenter.presentMessageCompose(uri: uri, image: image)
        }
        return root
    }
    
    private func selectAssetView(asset: Asset) -> UIViewController? {
        let assetPopUpVC = AssetPopUpVC(walletManager: walletManager, asset: asset)
        let root = ModalViewController(childViewController: assetPopUpVC)
        assetPopUpVC.parentVC = root
        assetPopUpVC.modalPresenter = self
        return root
    }
    
    private func makeAddAddressBookView(currency: CurrencyDef, initialAddress: String? = nil, type:ActionAddressType, callback: @escaping () -> Void) -> UIViewController? {//BMEX
        let addAddressVC = AddAddressBookVC(currency: currency, initialAddress: initialAddress, type: type, callback: callback)
        let root = ModalViewController(childViewController: addAddressVC)
        addAddressVC.presentScan = presentScan(parent: root, currency: currency)
        return root
    }


    private func presentLoginScan() {
        guard let top = topViewController else { return }
        let present = presentScan(parent: top, currency: Currencies.rvn)
        Store.perform(action: RootModalActions.Present(modal: .none))
        present({ paymentRequest in
            guard let request = paymentRequest else { return }
            self.currentRequest = request
            self.presentModal(.send(currency: Currencies.rvn))
        })
    }
    
    func presentSettings() {
        guard let top = topViewController else { return }
        let settingsNav = UINavigationController()
        settingsNav.setGrayStyle()
        let sections: [SettingsSections] = [.wallet, .preferences, .currencies, .assets, .other]
                
        let rows = [
            SettingsSections.wallet: [
                Setting(title: S.Settings.wipe, callback: { [weak self] in
                    guard let `self` = self else { return }
                    let nc = ModalNavigationController()
                    nc.setClearNavbar()
                    nc.setWhiteStyle()
                    nc.delegate = self.wipeNavigationDelegate
                    let start = StartWipeWalletViewController { [weak self] in
                        guard let myself = self else { return }
                        let recover = EnterPhraseViewController(walletManager: myself.walletManager, reason: .validateForWipingWallet( {
                            self?.wipeWallet()
                        }))
                        nc.pushViewController(recover, animated: true)
                    }
                    start.addCloseNavigationItem(tintColor: .white)
                    start.navigationItem.title = S.WipeWallet.title
                    let faqButton = UIButton.buildFaqButton(articleId: ArticleIds.wipeWallet)
                    faqButton.tintColor = .white
                    start.navigationItem.rightBarButtonItems = [UIBarButtonItem.negativePadding, UIBarButtonItem(customView: faqButton)]
                    nc.viewControllers = [start]
                    settingsNav.dismiss(animated: true, completion: { [weak self] in
                        self?.topViewController?.presentFullScreen(nc, animated: true, completion: nil)
                    })
                })
            ],
            SettingsSections.preferences: [
                Setting(title: LAContext.biometricType() == .face ? S.Settings.faceIdLimit : S.Settings.touchIdLimit, accessoryText: {
                    guard let rate = Currencies.rvn.state.currentRate else { return "" }
                    let amount = Amount(amount: self.walletManager.spendingLimit, rate: rate, maxDigits: Currencies.rvn.state.maxDigits, currency: Currencies.rvn)
                    return amount.localCurrency
                }, callback: { [weak self] in
                    self?.pushBiometricsSpendingLimit(onNc: settingsNav)
                }),
                Setting(title: S.UpdatePin.updateTitle, callback: strongify(self) { myself in
                    let updatePin = UpdatePinViewController(walletManager: self.walletManager, type: .update)
                    settingsNav.pushViewController(updatePin, animated: true)
                }),
                Setting(title: S.Settings.currency, accessoryText: {
                    let code = Store.state.defaultCurrencyCode
                    let components: [String : String] = [NSLocale.Key.currencyCode.rawValue : code]
                    let identifier = Locale.identifier(fromComponents: components)
                    return Locale(identifier: identifier).currencyCode ?? ""
                }, callback: {
                    settingsNav.pushViewController(DefaultCurrencyViewController(walletManager: self.walletManager), animated: true)
                }),
            ],
            SettingsSections.currencies: [
                Setting(title: S.Settings.importTile, callback: {
                    settingsNav.dismiss(animated: true, completion: { [weak self] in
                        guard let myself = self else { return }
                        self?.presentKeyImport(walletManager: myself.walletManager)
                    })
                }),
                Setting(title: S.Settings.sync, callback: {
                    settingsNav.pushViewController(ReScanViewController(currency: Currencies.rvn), animated: true)
                }),
            ],
            SettingsSections.assets: [
                Setting(title: S.Asset.settingTitle, callback: { [weak self] in
                    guard let `self` = self else { return }
                    let nc = ModalNavigationController()
                    nc.setClearNavbar()
                    nc.setWhiteStyle()
                    nc.delegate = self.wipeNavigationDelegate
                    let start = ManageAssetDisplayVC ()
                    start.addCloseNavigationItem(tintColor: .white)
                    start.navigationItem.rightBarButtonItems = [UIBarButtonItem.negativePadding]
                    nc.viewControllers = [start]
                    settingsNav.dismiss(animated: true, completion: { [weak self] in
                        self?.topViewController?.presentFullScreen(nc, animated: true, completion: nil)
                    })
                }),
            ],
            SettingsSections.other: [
                Setting(title: S.Settings.shareData, callback: {
                    settingsNav.pushViewController(ShareDataViewController(), animated: true)
                }),
                Setting(title: S.Settings.review, callback: { [weak self] in
                    guard let `self` = self else { return }
                    let alert = UIAlertController(title: S.Settings.review, message: S.Settings.enjoying, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: S.Button.no, style: .default, handler: { _ in
                        self.messagePresenter.presenter = self.topViewController
                        self.messagePresenter.presentFeedbackCompose()
                    }))
                    alert.addAction(UIAlertAction(title: S.Button.yes, style: .default, handler: { _ in
                        if let url = URL(string: C.reviewLink) {
                            UIApplication.shared.open(url)
                        }
                    }))
                    self.topViewController?.present(alert, animated: true, completion: nil)
                }),
                Setting(title: S.Settings.about, callback: {
                    settingsNav.pushViewController(AboutViewController(), animated: true)
                }),
                Setting(title: "Update Ipfs Url", callback: {
                    Store.perform(action: RootModalActions.Present(modal: .updateIpfs))
                }),
                Setting(title: S.Settings.advanced, callback: {
                    var sections = [SettingsSections.network]
                    var advancedSettings = [
                        SettingsSections.network: [
                            Setting(title: S.NodeSelector.title, callback: {
                                let nodeSelector = NodeSelectorViewController(walletManager: self.walletManager)
                                settingsNav.pushViewController(nodeSelector, animated: true)
                            }),
                            Setting(title: S.Settings.usedAddresses, isHidden: !UserDefaults.hasActivatedExpertMode, callback: { [weak self] in
                                guard let `self` = self else { return }
                                let nc = ModalNavigationController()
                                nc.setClearNavbar()
                                nc.setWhiteStyle()
                                nc.delegate = self.wipeNavigationDelegate
                                let start = AllAddressesVC(walletManager: self.walletManager)
                                start.addCloseNavigationItem(tintColor: .white)
                                start.navigationItem.rightBarButtonItems = [UIBarButtonItem.negativePadding]
                                nc.viewControllers = [start]
                                settingsNav.dismiss(animated: true, completion: { [weak self] in
                                    self?.topViewController?.presentFullScreen(nc, animated: true, completion: nil)
                                })
                            }),
                            Setting(title: S.WipeSetting.title, isHidden: !UserDefaults.hasActivatedExpertMode, callback: {
                                self.wipeWallet()
                            }),
                            Setting(title: S.Settings.expertMode, toggle: UISwitch(), toggleDefaultValue: UserDefaults.hasActivatedExpertMode, toggleCallback: { isOn in
                                UserDefaults.hasActivatedExpertMode = isOn
                                Store.trigger(name: .reloadSettings)
                            })
                        ],
                    ]

                    if E.isTestFlight {
                        advancedSettings[SettingsSections.other] = [
                            Setting(title: S.Settings.sendLogs, callback: { [weak self] in
                                self?.showEmailLogsModal()
                            })
                        ]
                        sections.append(SettingsSections.other)
                    }
                    
                    let advancedSettingsVC = SettingsViewController(sections: sections, rows: advancedSettings, optionalTitle: S.Settings.advancedTitle)
                    settingsNav.pushViewController(advancedSettingsVC, animated: true)
                })
            ]
        ]
        
        let settings = SettingsViewController(sections: sections, rows: rows)
        settings.addCloseNavigationItem(tintColor: .mediumGray, side: .right)
        settingsNav.viewControllers = [settings]
        top.presentFullScreen(settingsNav, animated: true, completion: nil)
    }
        
    private func presentScan(parent: UIViewController, currency: CurrencyDef) -> PresentScan {
        return { [weak parent] scanCompletion in
            guard ScanViewController.isCameraAllowed else {
                if let parent = parent {
                    ScanViewController.presentCameraUnavailableAlert(fromRoot: parent)
                }
                return
            }
            let vc = ScanViewController(currency: currency, completion: { paymentRequest in
                scanCompletion(paymentRequest)
                parent?.view.isFrameChangeBlocked = false
            })
            parent?.view.isFrameChangeBlocked = true
            parent?.presentFullScreen(vc, animated: true, completion: {})
        }
    }

    func presentSecurityCenter() {
        let securityCenter = SecurityCenterViewController(walletManager: walletManager)
        let nc = ModalNavigationController(rootViewController: securityCenter)
        nc.setDefaultStyle()
        nc.isNavigationBarHidden = true
        nc.delegate = securityCenterNavigationDelegate
        securityCenter.didTapPin = {
            let updatePin = UpdatePinViewController(walletManager: self.walletManager, type: .update)
            nc.pushViewController(updatePin, animated: true)
        }
        securityCenter.didTapBiometrics = strongify(self) { myself in
            let biometricsSettings = BiometricsSettingsViewController(walletManager: self.walletManager)
            biometricsSettings.presentSpendingLimit = {
                myself.pushBiometricsSpendingLimit(onNc: nc)
            }
            nc.pushViewController(biometricsSettings, animated: true)
        }
        securityCenter.didTapRecoveryPhrase = { [weak self] in
            self?.presentWriteRecoveryPhrase(fromViewController: nc)
        }

        window.rootViewController?.presentFullScreen(nc, animated: true, completion: nil)
    }
    
    func presentAddressBook(type: AddressBookType? = .normal, callback: ((String) -> Void)? = nil) {
        let addressBookVC = AddressBookVC(walletManager: walletManager, addressBookType: type, callback: callback)
        let nc = ModalNavigationController(rootViewController: addressBookVC)
        nc.setClearNavbar()
        addressBookVC.addCloseNavigationItem(tintColor: .white)
        topViewController?.presentFullScreen(nc, animated: true, completion: nil)
    }
    
    func presentTutorial() {
        let tutorialVC = TutorialVC()
        let nc = ModalNavigationController(rootViewController: tutorialVC)
        nc.setNavigationBarHidden(false, animated: false)
        nc.setClearNavbar()
        tutorialVC.addCloseNavigationItem(tintColor: .white)
        window.rootViewController?.present(nc, animated: true, completion: nil)
    }

    private func pushBiometricsSpendingLimit(onNc: UINavigationController) {
        let verify = VerifyPinViewController(bodyText: S.VerifyPin.continueBody, pinLength: Store.state.pinLength, walletManager: walletManager, success: { pin in
            let spendingLimit = BiometricsSpendingLimitViewController(walletManager: self.walletManager)
            onNc.pushViewController(spendingLimit, animated: true)
        })
        verify.transitioningDelegate = verifyPinTransitionDelegate
        verify.modalPresentationStyle = .overFullScreen
        verify.modalPresentationCapturesStatusBarAppearance = true
        onNc.presentFullScreen(verify, animated: true, completion: nil)
    }

    private func presentWriteRecoveryPhrase(fromViewController vc: UIViewController) {
        let paperPhraseNavigationController = UINavigationController()
        paperPhraseNavigationController.setClearNavbar()
        paperPhraseNavigationController.setWhiteStyle()
        paperPhraseNavigationController.modalPresentationStyle = .overFullScreen
        let start = StartPaperPhraseViewController(callback: { [weak self] in
            guard let `self` = self else { return }
            let verify = VerifyPinViewController(bodyText: S.VerifyPin.continueBody, pinLength: Store.state.pinLength, walletManager: self.walletManager, success: { pin in
                self.pushWritePaperPhrase(navigationController: paperPhraseNavigationController, pin: pin)
            })
            verify.transitioningDelegate = self.verifyPinTransitionDelegate
            verify.modalPresentationStyle = .overFullScreen
            verify.modalPresentationCapturesStatusBarAppearance = true
            paperPhraseNavigationController.presentFullScreen(verify, animated: true, completion: nil)
        })
        start.addCloseNavigationItem(tintColor: .white)
        start.navigationItem.title = S.SecurityCenter.Cells.recoveryPhraseTitle
        let faqButton = UIButton.buildFaqButton(articleId: ArticleIds.recoveryPhrase)
        faqButton.tintColor = .white
        start.navigationItem.rightBarButtonItems = [UIBarButtonItem.negativePadding, UIBarButtonItem(customView: faqButton)]
        paperPhraseNavigationController.viewControllers = [start]
        vc.presentFullScreen(paperPhraseNavigationController, animated: true, completion: nil)
    }

    private func pushWritePaperPhrase(navigationController: UINavigationController, pin: String) {
        var writeViewController: WritePaperPhraseViewController?
        writeViewController = WritePaperPhraseViewController(walletManager: walletManager, pin: pin, callback: {
            var confirm: ConfirmPaperPhraseViewController?
            confirm = ConfirmPaperPhraseViewController(walletManager: self.walletManager, pin: pin, callback: {
                confirm?.dismiss(animated: true, completion: {
                    Store.perform(action: Alert.Show(.recoveryPhraseSet(callback: {
                        Store.perform(action: HideStartFlow())
                    })))
                })
            })
            writeViewController?.navigationItem.title = S.SecurityCenter.Cells.recoveryPhraseTitle
            if let confirm = confirm {
                navigationController.pushViewController(confirm, animated: true)
            }
        })
        writeViewController?.addCloseNavigationItem(tintColor: .white)
        writeViewController?.navigationItem.title = S.SecurityCenter.Cells.recoveryPhraseTitle
        guard let writeVC = writeViewController else { return }
        navigationController.pushViewController(writeVC, animated: true)
    }

    private func presentBuyController(_ mountPoint: String) {
        let vc: BRWebViewController
        #if Debug || Testflight
            vc = BRWebViewController(bundleName: "bread-frontend-staging", mountPoint: mountPoint, walletManager: walletManager)
        #else
            vc = BRWebViewController(bundleName: "bread-frontend", mountPoint: mountPoint, walletManager: walletManager)
        #endif
        vc.startServer()
        vc.preload()
        self.topViewController?.presentFullScreen(vc, animated: true, completion: nil)
    }

    private func presentRescan(currency: CurrencyDef) {
        let vc = ReScanViewController(currency: currency)
        let nc = UINavigationController(rootViewController: vc)
        nc.setClearNavbar()
        vc.addCloseNavigationItem()
        topViewController?.presentFullScreen(nc, animated: true, completion: nil)
    }
    
    private func presentRescanAsset() {
        let vc = ReScanAssetVC(currency: Currencies.rvn)
        let nc = UINavigationController(rootViewController: vc)
        nc.setClearNavbar()
        vc.addCloseNavigationItem()
        topViewController?.presentFullScreen(nc, animated: true, completion: nil)
    }

    public func wipeWallet() {
        let alert = UIAlertController(title: S.WipeWallet.alertTitle, message: S.WipeWallet.alertMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: S.Button.cancel, style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: S.WipeWallet.wipe, style: .destructive, handler: { _ in
//            self.topViewController?.dismiss(animated: true, completion: {
                Store.trigger(name: .wipeWalletNoPrompt)
//            })
        }))
        topViewController?.present(alert, animated: true, completion: nil)
    }

    public func wipeWalletNoPrompt() {
        let activity = BRActivityViewController(message: S.WipeWallet.wiping)
        self.topViewController?.presentFullScreen(activity, animated: true, completion: nil)
        DispatchQueue.walletQueue.async {
            self.walletManager.peerManager?.disconnect()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
                activity.dismiss(animated: true, completion: {
                    if self.walletManager.wipeWallet(pin: "forceWipe") {
                        Store.trigger(name: .reinitWalletManager({}))
                    } else {
                        let failure = UIAlertController(title: S.WipeWallet.failedTitle, message: S.WipeWallet.failedMessage, preferredStyle: .alert)
                        failure.addAction(UIAlertAction(title: S.Button.ok, style: .default, handler: nil))
                        self.topViewController?.present(failure, animated: true, completion: nil)
                    }
                })
            })
        }
    }
    
    private func presentKeyImport(walletManager: WalletManager) {
        let nc = ModalNavigationController()
        nc.setClearNavbar()
        nc.setWhiteStyle()
        let start = StartImportViewController(walletManager: walletManager)
        start.addCloseNavigationItem(tintColor: .white)
        start.navigationItem.title = S.Import.title
        let faqButton = UIButton.buildFaqButton(articleId: ArticleIds.importWallet)
        faqButton.tintColor = .white
        start.navigationItem.rightBarButtonItems = [UIBarButtonItem.negativePadding, UIBarButtonItem(customView: faqButton)]
        nc.viewControllers = [start]
        topViewController?.presentFullScreen(nc, animated: true, completion: nil)
    }

    //MARK: - Prompts
    func presentBiometricsSetting() {
        let biometricsSettings = BiometricsSettingsViewController(walletManager: walletManager)
        biometricsSettings.addCloseNavigationItem(tintColor: .white)
        let nc = ModalNavigationController(rootViewController: biometricsSettings)
        biometricsSettings.presentSpendingLimit = strongify(self) { myself in
            myself.pushBiometricsSpendingLimit(onNc: nc)
        }
        nc.setDefaultStyle()
        nc.isNavigationBarHidden = true
        nc.delegate = securityCenterNavigationDelegate
        topViewController?.presentFullScreen(nc, animated: true, completion: nil)
    }

    private func promptShareData() {
        let shareData = ShareDataViewController()
        let nc = ModalNavigationController(rootViewController: shareData)
        nc.setDefaultStyle()
        nc.isNavigationBarHidden = true
        nc.delegate = securityCenterNavigationDelegate
        shareData.addCloseNavigationItem()
        topViewController?.presentFullScreen(nc, animated: true, completion: nil)
    }

    func presentWriteRecoveryPhrase() {
        guard let vc = topViewController else { return }
        presentWriteRecoveryPhrase(fromViewController: vc)
    }

    func presentUpgradePin() {
        let updatePin = UpdatePinViewController(walletManager: walletManager, type: .update)
        let nc = ModalNavigationController(rootViewController: updatePin)
        nc.setDefaultStyle()
        nc.isNavigationBarHidden = true
        nc.delegate = securityCenterNavigationDelegate
        updatePin.addCloseNavigationItem()
        topViewController?.presentFullScreen(nc, animated: true, completion: nil)
    }

    private func handleFile(_ file: Data) {
        let alert = UIAlertController(title: S.Alert.error, message: S.PaymentProtocol.Errors.corruptedDocument, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: S.Button.ok, style: .cancel, handler: nil))
        topViewController?.present(alert, animated: true, completion: nil)
    }

    private func handlePaymentRequest(request: PaymentRequest) {
        self.currentRequest = request
        guard !Store.state.isLoginRequired else { presentModal(.send(currency: request.currency)); return }

        if let accountVC = topViewController as? AccountViewController {
            if accountVC.currency.matches(request.currency) {
                presentModal(.send(currency: request.currency))
            } else {
                // switch currencies
                accountVC.navigationController?.popToRootViewController(animated: false)
                showAccountView(currency: request.currency, animated: false)
                presentModal(.send(currency: request.currency))
            }
        } else if topViewController is HomeScreenViewController {
            showAccountView(currency: request.currency, animated: false)
            presentModal(.send(currency: request.currency))
        } else {
            if let presented = UIApplication.shared.keyWindow?.rootViewController?.presentedViewController {
                presented.dismiss(animated: true, completion: {
                    self.showAccountView(currency: request.currency, animated: false)
                    self.presentModal(.send(currency: request.currency))
                })
            }
        }
    }
    
    func showAccountView(currency: CurrencyDef, animated: Bool) {
        guard let nc = topViewController?.navigationController as? RootNavigationController,
            nc.viewControllers.count == 1 else { return }
        let accountViewController = AccountViewController(walletManager: walletManager)
        nc.pushViewController(accountViewController, animated: animated)
    }
    
    func pushAccountView(currency: CurrencyDef, animated: Bool, nc:UINavigationController) {
        let accountViewController = AccountViewController(walletManager: walletManager)
        nc.pushViewController(accountViewController, animated: animated)
    }

    private func handleScanQrURL() {
        guard !Store.state.isLoginRequired else { presentLoginScan(); return }
        if topViewController is AccountViewController || topViewController is LoginViewController {
            presentLoginScan()
        } else {
            if let presented = UIApplication.shared.keyWindow?.rootViewController?.presentedViewController {
                presented.dismiss(animated: true, completion: {
                    self.presentLoginScan()
                })
            }
        }
    }

    private func handleCopyAddresses(success: String?, error: String?) {
        let alert = UIAlertController(title: S.URLHandling.addressListAlertTitle, message: S.URLHandling.addressListAlertMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: S.Button.cancel, style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: S.URLHandling.copy, style: .default, handler: { [weak self] _ in
            guard let myself = self else { return }
            let verify = VerifyPinViewController(bodyText: S.URLHandling.addressListVerifyPrompt, pinLength: Store.state.pinLength, walletManager: myself.walletManager, success: { [weak self] pin in
                self?.copyAllAddressesToClipboard()
                Store.perform(action: Alert.Show(.addressesCopied))
                if let success = success, let url = URL(string: success) {
                    UIApplication.shared.open(url)
                }
            })
            verify.transitioningDelegate = self?.verifyPinTransitionDelegate
            verify.modalPresentationStyle = .overFullScreen
            verify.modalPresentationCapturesStatusBarAppearance = true
            self?.topViewController?.presentFullScreen(verify, animated: true, completion: nil)
        }))
        topViewController?.present(alert, animated: true, completion: nil)
    }

    private func authenticateForBitId(prompt: String, callback: @escaping (BitIdAuthResult) -> Void) {
        if UserDefaults.isBiometricsEnabled {
            walletManager.authenticate(biometricsPrompt: prompt, completion: { result in
                switch result {
                case .success:
                    return callback(.success)
                case .cancel:
                    return callback(.cancelled)
                case .failure:
                    self.verifyPinForBitId(prompt: prompt, callback: callback)
                case .fallback:
                    self.verifyPinForBitId(prompt: prompt, callback: callback)
                }
            })
        } else {
            self.verifyPinForBitId(prompt: prompt, callback: callback)
        }
    }

    private func verifyPinForBitId(prompt: String, callback: @escaping (BitIdAuthResult) -> Void) {
        let verify = VerifyPinViewController(bodyText: prompt, pinLength: Store.state.pinLength, walletManager: walletManager, success: { pin in
                callback(.success)
        })
        verify.didCancel = { callback(.cancelled) }
        verify.transitioningDelegate = verifyPinTransitionDelegate
        verify.modalPresentationStyle = .overFullScreen
        verify.modalPresentationCapturesStatusBarAppearance = true
        topViewController?.presentFullScreen(verify, animated: true, completion: nil)
    }

    private func copyAllAddressesToClipboard() {
        guard let wallet = walletManager.wallet else { return }
        let addresses = wallet.allAddresses.filter({wallet.addressIsUsed($0)})
        UIPasteboard.general.string = addresses.joined(separator: "\n")
    }

    var topViewController: UIViewController? {
        var viewController = window.rootViewController
        if let nc = viewController as? UINavigationController {
            viewController = nc.topViewController
        }
        while viewController?.presentedViewController != nil {
            viewController = viewController?.presentedViewController
        }
        return viewController
    }

    private func showNotReachable() {
        guard notReachableAlert == nil else { return }
        let alert = InAppAlert(message: S.Alert.noInternet, image: #imageLiteral(resourceName: "BrokenCloud"))
        notReachableAlert = alert
        let window = UIApplication.shared.keyWindow!
        let size = window.bounds.size
        window.addSubview(alert)
        let bottomConstraint = alert.bottomAnchor.constraint(equalTo: window.topAnchor, constant: 0.0)
        alert.constrain([
            alert.constraint(.width, constant: size.width),
            alert.constraint(.height, constant: InAppAlert.height),
            alert.constraint(.leading, toView: window, constant: nil),
            bottomConstraint ])
        window.layoutIfNeeded()
        alert.bottomConstraint = bottomConstraint
        alert.hide = {
            self.hideNotReachable()
        }
        UIView.spring(C.animationDuration, animations: {
            alert.bottomConstraint?.constant = InAppAlert.height
            window.layoutIfNeeded()
        }, completion: {_ in})
    }

    private func hideNotReachable() {
        UIView.animate(withDuration: C.animationDuration, animations: {
            self.notReachableAlert?.bottomConstraint?.constant = 0.0
            self.notReachableAlert?.superview?.layoutIfNeeded()
        }, completion: { _ in
            self.notReachableAlert?.removeFromSuperview()
            self.notReachableAlert = nil
        })
    }

    private func showLightWeightAlert(message: String) {
        let alert = LightWeightAlert(message: message)
        let view = UIApplication.shared.keyWindow!
        view.addSubview(alert)
        alert.constrain([
            alert.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            alert.centerYAnchor.constraint(equalTo: view.centerYAnchor) ])
        alert.background.effect = nil
        UIView.animate(withDuration: 0.6, animations: {
            alert.background.effect = alert.effect
        }, completion: { _ in
            UIView.animate(withDuration: 0.6, delay: 1.0, options: [], animations: {
                alert.background.effect = nil
            }, completion: { _ in
                alert.removeFromSuperview()
            })
        })
    }

    private func showEmailLogsModal() {
        self.messagePresenter.presenter = self.topViewController
        self.messagePresenter.presentEmailLogs()
    }
}

class SecurityCenterNavigationDelegate : NSObject, UINavigationControllerDelegate {

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {

        guard let coordinator = navigationController.topViewController?.transitionCoordinator else { return }

        if coordinator.isInteractive {
            coordinator.notifyWhenInteractionChanges { context in
                //We only want to style the view controller if the
                //pop animation wasn't cancelled
                if !context.isCancelled {
                    self.setStyle(navigationController: navigationController, viewController: viewController)
                }
            }
        } else {
            setStyle(navigationController: navigationController, viewController: viewController)
        }
    }

    func setStyle(navigationController: UINavigationController, viewController: UIViewController) {
        if viewController is SecurityCenterViewController {
            navigationController.isNavigationBarHidden = true
        } else {
            navigationController.isNavigationBarHidden = false
        }

        if viewController is BiometricsSettingsViewController {
            navigationController.setWhiteStyle()
        } else {
            navigationController.setDefaultStyle()
        }
    }
}
