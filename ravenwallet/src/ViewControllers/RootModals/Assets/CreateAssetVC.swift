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

internal let verticalButtonPadding: CGFloat = 32.0
internal let createAddressHeight: CGFloat = 110.0
internal let createNameAssetHeight: CGFloat = 77.0

enum NameStatus {
    case notVerified
    case availabe
    case notAvailable
}


class CreateAssetVC : UIViewController, Subscriber, ModalPresentable, Trackable {

    //MARK - Public
    var presentScan: PresentScan?
    var presentVerifyPin: ((String, @escaping ((String) -> Void))->Void)?
    var onPublishSuccess: ((String)->Void)?
    var parentView: UIView? //ModalPresentable
    var initialAddress: String?
    var isPresentedFromLock = false
    var group: DispatchGroup?
    var callbackNameAvailability: ((NameStatus) -> Void)?

    init(walletManager: WalletManager, initialAddress: String? = nil, initialRequest: PaymentRequest? = nil) {
        self.initialAddress = initialAddress
        self.initialRequest = initialRequest
        self.walletManager = walletManager
        self.operationType = .createAsset
        self.sender = SenderAsset(walletManager: self.walletManager, currency: self.currency, operationType: self.operationType)
        self.addressCell = AddressCreateAssetCell(currency: self.currency, type: .create)
        self.feeView = FeeAmountVC(walletManager: self.walletManager, sender: self.sender, operationType: self.operationType)
        self.cPtr = (walletManager.peerManager?.cPtr)!
        super.init(nibName: nil, bundle: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    //MARK - Private
    deinit {
        Store.unsubscribe(self)
        NotificationCenter.default.removeObserver(self)
    }

    let cPtr: OpaquePointer
    internal var operationType: OperationType
    internal var asset: Asset?
    internal var sender: SenderAsset
    internal let walletManager: WalletManager
    internal let nameCell = NameAssetCell(placeholder: S.AddressBook.nameAddressLabel)
    internal let addressCell: AddressCreateAssetCell
    internal let quantityView = QuantityCell(placeholder: S.Asset.quantity, keyboardType: .quantityPad)
    internal var feeView: FeeAmountVC
    internal let unitsCell = UnitsCell(placeholder: S.Asset.unitsLabel)
    internal let reissubaleCell = CheckBoxCell(labelCheckBox: S.Asset.isReissuableLabel)
    internal let ipfsCell = IPFSCell(labelCheckBox: S.Asset.hasIpfsLabel, placeholder: S.Asset.ipfsHashLabel)
    internal let createButton = ShadowButton(title: S.Asset.create, type: .tertiary)
    private let currencyBorder = UIView(color: .secondaryShadow)
    private var currencySwitcherHeightConstraint: NSLayoutConstraint?
    private var pinPadHeightConstraint: NSLayoutConstraint?
    internal var balance: UInt64 = 0
    internal var feeAmount: UInt64 = 0
    internal var quantity: Satoshis?
    private var didIgnoreUsedAddressWarning = false
    private var didIgnoreIdentityNotCertified = false
    private let initialRequest: PaymentRequest?
    internal let confirmTransitioningDelegate = PinTransitioningDelegate()
    internal var feeType: Fee?
    internal let currency: CurrencyDef = Currencies.rvn //BMEX
    internal var nameStatus: NameStatus = .notVerified
    internal let activityView = UIActivityIndicatorView(style: .white)
    private var origineParentFrame:CGRect?
    override func viewDidLoad() {
        addSubviews()
        addConstraints()
        addSubscriptions()
        addButtonActions()
        setInitialData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        origineParentFrame = self.parentView?.frame
    }
    
    internal func addSubviews() {
        view.backgroundColor = .white
        view.addSubview(nameCell)
        view.addSubview(addressCell)
        view.addSubview(reissubaleCell)
        view.addSubview(ipfsCell)
        view.addSubview(createButton)
        createButton.addSubview(activityView)
    }
    
    internal func addConstraints() {
        nameCell.constrainTopCorners(height: createNameAssetHeight)
        addressCell.constrain([
            addressCell.widthAnchor.constraint(equalTo: nameCell.widthAnchor),
            addressCell.topAnchor.constraint(equalTo: nameCell.bottomAnchor),
            addressCell.leadingAnchor.constraint(equalTo: nameCell.leadingAnchor),
            addressCell.heightAnchor.constraint(equalToConstant: !UserDefaults.hasActivatedExpertMode ? 0.0 : createAddressHeight) ])
        
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
        
        activityView.constrain([
            activityView.constraint(.trailing, toView: createButton, constant: -C.padding[2]),
            activityView.centerYAnchor.constraint(equalTo: createButton.centerYAnchor) ])
    }
    
    internal func setInitialData() {
        nameCell.textField.autocapitalizationType = .allCharacters
        if initialAddress != nil {
            addressCell.setContent(initialAddress)
        }
        activityView.hidesWhenStopped = true
        activityView.stopAnimating()
        if !UserDefaults.hasActivatedExpertMode {
            self.generateTapped()
        }
        //reissuable is true by default
        reissubaleCell.btnCheckBox.isSelected = true
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
    
    

    internal func addButtonActions() {
        addressCell.paste.addTarget(self, action: #selector(CreateAssetVC.pasteTapped), for: .touchUpInside)
        addressCell.scan.addTarget(self, action: #selector(CreateAssetVC.scanTapped), for: .touchUpInside)
        addressCell.addressBook.addTarget(self, action: #selector(CreateAssetVC.addressBookTapped), for: .touchUpInside)
        addressCell.generate.addTarget(self, action: #selector(CreateAssetVC.generateTapped), for: .touchUpInside)

        ipfsCell.paste.addTarget(self, action: #selector(CreateAssetVC.pasteTapped), for: .touchUpInside)
        ipfsCell.scan.addTarget(self, action: #selector(CreateAssetVC.scanTapped), for: .touchUpInside)

        createButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        
        nameCell.didReturn = { textField in
            textField.resignFirstResponder()
            let assetType:AssetType = AssetValidator.shared.getAssetType(operationType: self.operationType, nameAsset: self.nameCell.textField.text!)
            guard AssetValidator.shared.validateName(name: self.nameCell.textField.text!, forType: assetType) else {
                return self.showAlert(title: S.Alert.error, message: S.Asset.errorAssetNameMessage, buttonLabel: S.Button.ok)
            }
        }
        
        nameCell.didChange = { text in
            self.nameStatus = .notVerified
        }
        
        nameCell.didBeginEditing = { [weak self] in
            self?.quantityView.closePinPad()
            self?.unitsCell.closePinPad()
        }
        
        nameCell.didVerifyTapped = { assetName in
            let assetType:AssetType = AssetValidator.shared.getAssetType(operationType: self.operationType, nameAsset: self.nameCell.textField.text!)
            guard AssetValidator.shared.validateName(name: self.nameCell.textField.text!, forType: assetType) else {
                DispatchQueue.main.async {
                    self.nameCell.activityView.stopAnimating()
                    self.nameCell.verify.label.isHidden = false
                    self.nameCell.verify.isEnabled = true
                }
                return self.showAlert(title: S.Alert.error, message: S.Asset.errorAssetNameMessage, buttonLabel: S.Button.ok)
            }
            self.getAssetData(assetName: assetName!, callback: { nameStatus in
                DispatchQueue.main.async {
                    self.nameCell.verify.isEnabled = true
                }
                self.nameCell.checkAvailabilityResult(nameStatus: nameStatus)
            })
        }
        
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
                self?.nameCell.textField.resignFirstResponder()
                self?.addressCell.textField.resignFirstResponder()
                self?.unitsCell.closePinPad()
                self?.ipfsCell.textField.resignFirstResponder()
            }
        }
        
        quantityView.didReturn = { [weak self] in
            self?.parentView?.frame = self!.origineParentFrame!
        }
        
        quantityView.didUpdateAmount = { [weak self] amount in
            self?.quantity = amount
        }
        
        unitsCell.didChangeFirstResponder = { [weak self] isFirstResponder in
            if isFirstResponder {
                self?.nameCell.textField.resignFirstResponder()
                self?.addressCell.textField.resignFirstResponder()
                self?.quantityView.closePinPad()
                self?.ipfsCell.textField.resignFirstResponder()
            }
        }
        
        unitsCell.didReturn = { [weak self] in
            self?.parentView?.frame = self!.origineParentFrame!
        }
        
        feeView.didUpdateAssetFee = { [weak self] feeAmount in
            self?.feeAmount = feeAmount
        }
        //initiate feeview balance
        feeView.balance = self.balance
    }
    
    func getAssetData(assetName:String, callback: @escaping (NameStatus) -> Void) {
        self.callbackNameAvailability = callback
        self.group = DispatchGroup()
        self.group!.enter()
        DispatchQueue.walletQueue.async {
            let asssetNamePointer = UnsafeMutablePointer<Int8>(mutating: (assetName as NSString).utf8String)
            PeerManagerGetAssetData(self.walletManager.peerManager?.cPtr, Unmanaged.passUnretained(self).toOpaque(), asssetNamePointer, assetName.count, {(info, assetRef) in
                guard let info = info else { return }
                let mySelf = Unmanaged<CreateAssetVC>.fromOpaque(info).takeUnretainedValue()
                mySelf.nameStatus = assetRef != nil ? .notAvailable : .availabe
                mySelf.callbackNameAvailability!(mySelf.nameStatus)
                if(mySelf.group != nil){
                    mySelf.group?.leave()
                    mySelf.group = nil
                }
            })
            let result = self.group!.wait(timeout: .now() + 2.0)
            if result == .timedOut {
                self.group = nil
                callback(.notVerified)
                self.nameStatus = .notVerified
            }
        }
    }

    @objc private func pasteTapped(sender:UIButton) {
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
                return showAlert(title: S.Send.invalidAddressTitle, message: S.Asset.invalidIpfsHashMessage, buttonLabel: S.Button.ok)
            }
            ipfsCell.textField.text = pasteboard
        }
    }

    @objc private func scanTapped(sender:UIButton) {
        nameCell.textField.resignFirstResponder()
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
    
    @objc private func generateTapped() {
        guard let addressText = currency.state.receiveAddress else { return }
        addressCell.setContent(addressText)        
    }
    
    @objc private func addressBookTapped() {
        nameCell.textField.resignFirstResponder()
        addressCell.textField.resignFirstResponder()
        quantityView.closePinPad()
        unitsCell.closePinPad()
        ipfsCell.textField.resignFirstResponder()
        Store.trigger(name: .selectAddressBook(.select, ({ address in
            self.addressCell.setContent(address)
        })))
    }
    
    @objc internal func sendTapped() {
        if addressCell.textField.isFirstResponder {
            addressCell.textField.resignFirstResponder()
        }

        guard self.nameCell.textField.text != nil else {
            return showAlert(title: S.Alert.error, message: S.Asset.noName, buttonLabel: S.Button.ok)
        }
        
        guard self.nameCell.textField.text?.isEmpty == false else {
            return showAlert(title: S.Alert.error, message: S.Asset.noName, buttonLabel: S.Button.ok)
        }
        var assetType:AssetType = .ROOT
        if (AssetValidator.shared.IsAssetNameAnOwner(name: self.nameCell.textField.text!)) {
            assetType = .OWNER
        }
        else{
            assetType = operationType == .createAsset ? .ROOT : .SUB
        }

        guard AssetValidator.shared.validateName(name: self.nameCell.textField.text!, forType: assetType) else {
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
        guard quantity != nil else {
            return showAlert(title: S.Alert.error, message: S.Asset.noQuanityToCreate, buttonLabel: S.Button.ok)
        }
        
        guard let amount = quantity else {
            return showAlert(title: S.Alert.error, message: S.Send.noAmount, buttonLabel: S.Button.ok)
        }
        
        guard amount != Satoshis.zero else {
            return showAlert(title: S.Alert.error, message: S.Asset.noQuanityToCreate, buttonLabel: S.Button.ok)
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
                return showAlert(title: S.Send.invalidAddressTitle, message: S.Asset.invalidIpfsHashMessage, buttonLabel: S.Button.ok)
            }
        }
        //if all ok check name availability if not checked
        if nameStatus == .notVerified {
            createButton.label.text = S.Asset.availability
            activityView.startAnimating()
            getAssetData(assetName: self.nameCell.textField.text!) {nameStatus in
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
                        self.showConfirmationView(amount: amount, address: address, units: Int(exactly: self.unitsCell.amount!.rawValue / 100000000)!, reissubale:self.reissubaleCell.btnCheckBox.isSelected ? 1 : 0)
                    }
                }
            }
        }
        else
        {
            showConfirmationView(amount: amount, address: address, units: Int(exactly: unitsCell.amount!.rawValue / 100000000)!, reissubale:reissubaleCell.btnCheckBox.isSelected ? 1 : 0)
        }
        return
    }
    
    func createAsset(amount:Satoshis) -> (BRAssetRef, BRAssetRef?) {
        let assetToSend = BRAsset.createAssetRef(asset: asset!, type: NEW_ASSET, amount: amount)
        return (assetToSend, nil)
    }
    
    func showConfirmationView(amount:Satoshis, address:String, units:Int, reissubale:Int) {
        //sender
        asset = Asset.init(idAsset: -1, name: self.nameCell.textField.text!, amount: amount, units: units, reissubale: reissubale, hasIpfs: ipfsCell.hasIpfs ? 1 : 0, ipfsHash: ipfsCell.ipfsHash!, ownerShip: -1, hidden: -1, sort: -1)
        
        let (assetToSend, rootAsset) = createAsset(amount: amount)
        guard sender.createAssetTransaction(to: address, asset: assetToSend, rootAsset: rootAsset) else {
            return showAlert(title: S.Alert.error, message: S.Send.createTransactionError, buttonLabel: S.Button.ok)
        }
        
        let confirm = ConfirmationViewController(amount: amount, fee: Satoshis(sender.fee), feeType: feeType ?? .regular, selectedRate: nil, minimumFractionDigits: quantityView.minimumFractionDigits, address: addressCell.displayAddress ?? "", isUsingBiometrics: sender.canUseBiometrics, operationType: operationType, assetToSend: asset)
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
                        myself.onPublishSuccess?(myself.sender.transaction!.txHash.description)
                    })
                    self?.saveEvent("\(self!.operationType).success")
                case .creationError(let message):
                    self?.showAlert(title: S.Send.createTransactionError, message: message, buttonLabel: S.Button.ok)
                    self?.saveEvent("\(self!.operationType).publishFailed", attributes: ["errorMessage": message])
                case .publishFailure(let error):
                    if case .posixError(let code, let description) = error {
                        self?.showAlert(title: S.Alerts.sendFailure, message: "\(description) (\(code))", buttonLabel: S.Button.ok)
                        self?.saveEvent("\(self!.operationType).publishFailed", attributes: ["errorMessage": "\(description) (\(code))"])
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
        if parentView!.frame.origin.y >= (origineParentFrame?.origin.y)!  {
            return
        }
        copyKeyboardChangeAnimation(notification: notification)
    }

    //TODO - maybe put this in ModalPresentable?
    private func copyKeyboardChangeAnimation(notification: Notification) {
        guard let info = KeyboardNotificationInfo(notification.userInfo) else { return }
        UIView.animate(withDuration: info.animationDuration, delay: 0, options: info.animationOptions, animations: {
            guard let parentView = self.parentView else { return }
            var diff:CGFloat = info.deltaY
            if(self.nameCell.textField.isFirstResponder){
                diff = info.deltaY + (notification.name.rawValue == UIResponder.keyboardWillShowNotification.rawValue ? createAddressHeight : -createAddressHeight)
            }
            parentView.frame = parentView.frame.offsetBy(dx: 0, dy: diff)
        }, completion: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CreateAssetVC : ModalDisplayable {
    var faqArticleId: String? {
        return nil
    }

    var modalTitle: String {
        switch self.operationType {
        case .createAsset:
            return "\(S.Asset.createTitle)"
        case .subAsset:
            return "\(S.Asset.subAssetTitle)"
        case .uniqueAsset:
            return "\(S.Asset.uniqueAssetTitle)"
        default:
            return "\(S.Asset.createTitle)"
        }
    }
}

