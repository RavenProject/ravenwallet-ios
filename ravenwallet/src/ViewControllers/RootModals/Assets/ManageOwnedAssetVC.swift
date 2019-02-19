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

private let manageAddressHeight: CGFloat = 110.0

class ManageOwnedAssetVC : UIViewController, Subscriber, ModalPresentable, Trackable {

    //MARK - Public
    var presentScan: PresentScan?
    var presentVerifyPin: ((String, @escaping ((String) -> Void))->Void)?
    var onPublishSuccess: (()->Void)?
    var parentView: UIView? //ModalPresentable
    var initialAddress: String?
    var isPresentedFromLock = false

    init(asset: Asset, walletManager: WalletManager, initialAddress: String? = nil, initialRequest: PaymentRequest? = nil) {
        self.asset = asset
        self.initialAddress = initialAddress
        self.initialRequest = initialRequest
        self.walletManager = walletManager
        self.sender = SenderAsset(walletManager: self.walletManager, currency: self.currency, operationType: .manageAsset)
        self.addressCell = AddressCreateAssetCell(currency: self.currency, type: .create)
        self.feeView = FeeAmountVC(walletManager: walletManager, sender: self.sender, operationType: .manageAsset)
        self.quantityView = QuantityCell(placeholder: S.Asset.quantity, keyboardType: .quantityPad)
        super.init(nibName: nil, bundle: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    //MARK - Private
    deinit {
        Store.unsubscribe(self)
        NotificationCenter.default.removeObserver(self)
    }

    private var asset: Asset
    private var qtAmountAsset: Satoshis? = nil
    private let sender: SenderAsset
    private let walletManager: WalletManager
    private let addressCell: AddressCreateAssetCell
    private let quantityView: QuantityCell
    private let feeView: FeeAmountVC
    private let unitsCell = UnitsCell(placeholder: S.Asset.unitsLabel, isEnabled: true)
    private let reissubaleCell = CheckBoxCell(labelCheckBox: S.Asset.isReissuableLabel)
    private let ipfsCell = IPFSCell(labelCheckBox: S.Asset.hasIpfsLabel, placeholder: S.Asset.ipfsHashLabel)
    private let createButton = ShadowButton(title: S.Asset.create, type: .tertiary)
    private let currencyBorder = UIView(color: .secondaryShadow)
    private var currencySwitcherHeightConstraint: NSLayoutConstraint?
    private var pinPadHeightConstraint: NSLayoutConstraint?
    private var balance: UInt64 = 0
    private var quantity: Satoshis?
    private var feeAmount: UInt64 = 0
    private var amount: Satoshis?
    private var didIgnoreUsedAddressWarning = false
    private var didIgnoreIdentityNotCertified = false
    private let initialRequest: PaymentRequest?
    private let confirmTransitioningDelegate = PinTransitioningDelegate()
    private var feeType: Fee?
    private let currency: CurrencyDef = Currencies.rvn //BMEX

    override func viewDidLoad() {
        addSubviews()
        addConstraints()
        addSubscriptions()
        addButtonActions()
        setInitialData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    private func addSubviews() {
        view.backgroundColor = .white
        view.addSubview(addressCell)
        view.addSubview(reissubaleCell)
        view.addSubview(ipfsCell)
        view.addSubview(createButton)
    }
    
    private func addConstraints() {
        addressCell.constrain([
            addressCell.widthAnchor.constraint(equalTo: view.widthAnchor),
            addressCell.topAnchor.constraint(equalTo: view.topAnchor),
            addressCell.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            addressCell.heightAnchor.constraint(equalToConstant: !UserDefaults.hasActivatedExpertMode ? 0.0 : manageAddressHeight) ])

        
        addChild(quantityView, layout: {
            quantityView.view.constrain([
                quantityView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                quantityView.view.topAnchor.constraint(equalTo: addressCell.bottomAnchor),
                quantityView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor) ])
        })
        
        addChild(unitsCell, layout: {
            unitsCell.view.constrain([
                unitsCell.view.widthAnchor.constraint(equalTo: quantityView.view.widthAnchor),
                unitsCell.view.topAnchor.constraint(equalTo: quantityView.view.bottomAnchor),
                unitsCell.view.leadingAnchor.constraint(equalTo: quantityView.view.leadingAnchor) ])
        })
        
        reissubaleCell.constrain([
            reissubaleCell.widthAnchor.constraint(equalTo: unitsCell.view.widthAnchor),
            reissubaleCell.topAnchor.constraint(equalTo: unitsCell.view.bottomAnchor),
            reissubaleCell.leadingAnchor.constraint(equalTo: unitsCell.view.leadingAnchor),
            reissubaleCell.heightAnchor.constraint(equalToConstant: SendCell.defaultHeight - C.padding[2]) ])

        ipfsCell.constrain([
            ipfsCell.widthAnchor.constraint(equalTo: reissubaleCell.widthAnchor),
            ipfsCell.topAnchor.constraint(equalTo: reissubaleCell.bottomAnchor),
            ipfsCell.leadingAnchor.constraint(equalTo: reissubaleCell.leadingAnchor),
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
    }
    
    private func setInitialData() {
        if initialAddress != nil {
            addressCell.setContent(initialAddress)
        }
        if !UserDefaults.hasActivatedExpertMode {
            self.generateTapped()
        }
        self.unitsCell.amount = Satoshis(UInt64(self.asset.units) * C.satoshis)
        //reissuable is true by default
        reissubaleCell.btnCheckBox.isSelected = true
        //get Asset Data
        getAssetData(assetName: asset.name)
    }
    
    private func addSubscriptions() {
        Store.subscribe(self, selector: { $0[self.currency].balance != $1[self.currency].balance },
                        callback: { [unowned self] in
                            if let balance = $0[self.currency].balance {
                                self.balance = balance
                            }
        })
        
        Store.subscribe(self, selector: { $0[self.currency].fees != $1[self.currency].fees }, callback: { [unowned self] in
            if let fees = $0[self.currency].fees {
                if let feeType = self.feeType {
                    switch feeType {
                    case .regular :
                        self.walletManager.wallet?.feePerKb = fees.regular
                    case .economy:
                        self.walletManager.wallet?.feePerKb = fees.economy
                    }
                } else {
                    self.walletManager.wallet?.feePerKb = fees.regular
                }
            }
        })
    }

    private func addButtonActions() {
        addressCell.paste.addTarget(self, action: #selector(ManageOwnedAssetVC.pasteTapped), for: .touchUpInside)
        addressCell.scan.addTarget(self, action: #selector(ManageOwnedAssetVC.scanTapped), for: .touchUpInside)
        addressCell.addressBook.addTarget(self, action: #selector(ManageOwnedAssetVC.addressBookTapped), for: .touchUpInside)
        addressCell.generate.addTarget(self, action: #selector(ManageOwnedAssetVC.generateTapped), for: .touchUpInside)
        
        ipfsCell.paste.addTarget(self, action: #selector(ManageOwnedAssetVC.pasteTapped), for: .touchUpInside)
        ipfsCell.scan.addTarget(self, action: #selector(ManageOwnedAssetVC.scanTapped), for: .touchUpInside)
        
        createButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        
        ipfsCell.didBeginEditing = { [weak self] in
            self?.quantityView.closePinPad()
            self?.unitsCell.closePinPad()
        }
        
        ipfsCell.didReturn = { textField in
            textField.resignFirstResponder()
        }
        
        addressCell.didBeginEditing = strongify(self) { myself in
            myself.quantityView.closePinPad()
        }

        quantityView.didChangeFirstResponder = { [weak self] isFirstResponder in
            if isFirstResponder {
                self?.addressCell.textField.resignFirstResponder()
                self?.unitsCell.closePinPad()
                self?.ipfsCell.textField.resignFirstResponder()
            }
        }
        
        quantityView.didUpdateAmount = { [weak self] amount in
            self?.quantity = amount
        }
        
        unitsCell.didChangeFirstResponder = { [weak self] isFirstResponder in
            if isFirstResponder {
                self?.addressCell.textField.resignFirstResponder()
                self?.quantityView.closePinPad()
                self?.ipfsCell.textField.resignFirstResponder()
            }
        }
        
        unitsCell.didUpdateAmount = { amount in
            guard amount != nil else {
                self.unitsCell.amount = Satoshis.zero
                return
            }
            guard (Int(exactly: amount!.rawValue / 100000000)! >= self.asset.units) else {
                self.unitsCell.amount = Satoshis(UInt64(self.asset.units) * C.satoshis)
                return self.showAlert(title: S.Alert.error, message: String(format: S.Asset.errorUnitsValue, self.asset.units), buttonLabel: S.Button.ok)
            }
        }
        
        feeView.didUpdateAssetFee = { [weak self] feeAmount in
            self?.feeAmount = feeAmount
        }
        
        //initiate feeview balance
        feeView.balance = self.balance

    }
    
    func getAssetData(assetName:String) {
        let asssetNamePointer = UnsafeMutablePointer<Int8>(mutating: (assetName as NSString).utf8String)
        PeerManagerGetAssetData(self.walletManager.peerManager?.cPtr, Unmanaged.passUnretained(self).toOpaque(), asssetNamePointer, assetName.count, {(info, assetRef) in
            guard let info = info else { return }
            guard assetRef != nil else { return }
            let mySelf = Unmanaged<ManageOwnedAssetVC>.fromOpaque(info).takeUnretainedValue()
            mySelf.qtAmountAsset = Satoshis.init((assetRef?.pointee.amount)!)
        })
    }

    @objc private func pasteTapped(sender: UIButton) {
        guard let pasteboard = UIPasteboard.general.string, pasteboard.utf8.count > 0 else {
            return showAlert(title: S.Alert.error, message: S.Send.emptyPasteboard, buttonLabel: S.Button.ok)
        }

        if sender.superview == addressCell {
            guard PaymentRequest(string: pasteboard, currency: currency) != nil else {
                let message = String.init(format: S.Send.invalidAddressOnPasteboard, currency.name)
                return showAlert(title: S.Send.invalidAddressTitle, message: message, buttonLabel: S.Button.ok)
            }
            addressCell.setContent(pasteboard)
        }
        else if sender.superview == ipfsCell{
            guard AssetValidator.shared.IsIpfsHashValid(ipfsHash: pasteboard) else {
                let message = String.init(format: S.Asset.invalidIpfsHashMessage, currency.name)
                return showAlert(title: S.Send.invalidAddressTitle, message: message, buttonLabel: S.Button.ok)
            }
            ipfsCell.textField.text = pasteboard
        }
    }

    @objc private func scanTapped(sender: UIButton) {
        addressCell.textField.resignFirstResponder()
        quantityView.closePinPad()
        unitsCell.closePinPad()
        ipfsCell.textField.resignFirstResponder()

        presentScan? { [weak self] paymentRequest in
            if sender.superview == self?.addressCell {
                self?.addressCell.setContent(paymentRequest?.displayAddress)
            }
            else if sender.superview == self?.ipfsCell{
                self?.ipfsCell.textField.text = paymentRequest?.displayAddress
            }
        }
    }
    
    @objc private func addressBookTapped() {
        addressCell.textField.resignFirstResponder()
        quantityView.closePinPad()
        unitsCell.closePinPad()
        ipfsCell.textField.resignFirstResponder()
        Store.trigger(name: .selectAddressBook(.select, ({ address in
            self.addressCell.setContent(address)
        })))
    }
    
    @objc private func generateTapped() {
        guard let addressText = currency.state.receiveAddress else { return }
        addressCell.setContent(addressText)
    }
    
    @objc private func sendTapped() {
        if addressCell.textField.isFirstResponder {
            addressCell.textField.resignFirstResponder()
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
        guard quantity != nil else {
            return showAlert(title: S.Alert.error, message: S.Asset.noQuanityToManage, buttonLabel: S.Button.ok)
        }
        
        guard let amount = quantity else {
            return showAlert(title: S.Alert.error, message: S.Send.noAmount, buttonLabel: S.Button.ok)
        }
        
        guard amount != Satoshis.zero else {
            return showAlert(title: S.Alert.error, message: S.Asset.noQuanityToManage, buttonLabel: S.Button.ok)
        }
        
        let totalAmount = amount.rawValue + (qtAmountAsset != nil ? qtAmountAsset!.rawValue : 0)
        guard totalAmount <= C.maxAsset else {
            return showAlert(title: S.Alert.error, message: S.Asset.maxQuanityToManage, buttonLabel: S.Button.ok)
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
        
        showConfirmationView(amount: amount, address: address)
        return
    }
    
    func showConfirmationView(amount:Satoshis, address:String) {
        //sender
        asset = Asset.init(idAsset: -1, name: asset.name, amount: amount, units: Int(exactly: unitsCell.amount!.rawValue / 100000000)!, reissubale: reissubaleCell.btnCheckBox.isSelected ? 1 : 0, hasIpfs: ipfsCell.hasIpfs ? 1 : 0, ipfsHash: ipfsCell.ipfsHash!, ownerShip: -1, hidden: -1, sort: -1)
        
        let assetToSend: BRAssetRef = BRAsset.createAssetRef(asset: asset, type: REISSUE, amount: amount)
        guard sender.createAssetTransaction(amount: C.manageAssetFee, to: address, asset: assetToSend) else {
            return showAlert(title: S.Alert.error, message: S.Send.createTransactionError, buttonLabel: S.Button.ok)
        }
        
        
        let confirm = ConfirmationViewController(amount: amount, fee: Satoshis(sender.fee), feeType: feeType ?? .regular, selectedRate: nil, minimumFractionDigits: quantityView.minimumFractionDigits, address: addressCell.displayAddress ?? "", isUsingBiometrics: sender.canUseBiometrics, operationType: .manageAsset, assetToSend: asset)
        confirm.successCallback = {
            confirm.dismiss(animated: true, completion: {
                self.send()
            })
        }
        confirm.cancelCallback = {
            confirm.dismiss(animated: true, completion: {
                self.sender.transaction = nil
            })
        }
        confirmTransitioningDelegate.shouldShowMaskView = false
        confirm.transitioningDelegate = confirmTransitioningDelegate
        confirm.modalPresentationStyle = .overFullScreen
        confirm.modalPresentationCapturesStatusBarAppearance = true
        present(confirm, animated: true, completion: nil)
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
                            self?.parent?.view.isFrameChangeBlocked = false
                            pinValidationCallback(pin)
                        }
            }, completion: { [weak self] result in
                switch result {
                case .success:
                    self?.dismiss(animated: true, completion: {
                        guard let myself = self else { return }
                        Store.trigger(name: .showStatusBar)
                        if myself.isPresentedFromLock {
                            Store.trigger(name: .loginFromSend)
                        }
                        myself.onPublishSuccess?()
                    })
                    self?.saveEvent("manage.success")
                case .creationError(let message):
                    self?.showAlert(title: S.Send.createTransactionError, message: message, buttonLabel: S.Button.ok)
                    self?.saveEvent("manage.publishFailed", attributes: ["errorMessage": message])
                case .publishFailure(let error):
                    if case .posixError(let code, let description) = error {
                        self?.showAlert(title: S.Alerts.sendFailure, message: "\(description) (\(code))", buttonLabel: S.Button.ok)
                        self?.saveEvent("manage.publishFailed", attributes: ["errorMessage": "\(description) (\(code))"])
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

    //MARK: - Keyboard Notifications
    @objc private func keyboardWillShow(notification: Notification) {
        copyKeyboardChangeAnimation(notification: notification)
    }

    @objc private func keyboardWillHide(notification: Notification) {
        copyKeyboardChangeAnimation(notification: notification)
    }

    //TODO - maybe put this in ModalPresentable?
    private func copyKeyboardChangeAnimation(notification: Notification) {
        guard let info = KeyboardNotificationInfo(notification.userInfo) else { return }
        UIView.animate(withDuration: info.animationDuration, delay: 0, options: info.animationOptions, animations: {
            guard let parentView = self.parentView else { return }
            parentView.frame = parentView.frame.offsetBy(dx: 0, dy: info.deltaY)
        }, completion: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ManageOwnedAssetVC : ModalDisplayable {
    var faqArticleId: String? {
        return nil
    }

    var modalTitle: String {
        return "\(S.Asset.manageTitle) \(asset.name)"
    }
}
