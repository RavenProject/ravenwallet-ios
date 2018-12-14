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

private let verticalButtonPadding: CGFloat = 32.0

class CreateAssetVC : UIViewController, Subscriber, ModalPresentable, Trackable {

    //MARK - Public
    var presentScan: PresentScan?
    var presentVerifyPin: ((String, @escaping ((String) -> Void))->Void)?
    var onPublishSuccess: ((String)->Void)?
    var parentView: UIView? //ModalPresentable
    var initialAddress: String?
    var isPresentedFromLock = false

    init(walletManager: WalletManager, initialAddress: String? = nil, initialRequest: PaymentRequest? = nil) {
        self.initialAddress = initialAddress
        self.initialRequest = initialRequest
        self.walletManager = walletManager
        self.sender = SenderAsset(walletManager: self.walletManager, currency: self.currency, operationType: .createAsset)
        self.addressCell = AddressCell(currency: self.currency, type: .create)
        self.feeView = FeeAmountVC(walletManager: self.walletManager, sender: self.sender, operationType: .createAsset)
        super.init(nibName: nil, bundle: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    //MARK - Private
    deinit {
        Store.unsubscribe(self)
        NotificationCenter.default.removeObserver(self)
    }

    private var asset: Asset?
    private let sender: SenderAsset
    private let walletManager: WalletManager
    private let nameCell = NameAddressCell(placeholder: S.AddressBook.nameAddressLabel)
    private let addressCell: AddressCell
    private let quantityView = QuantityCell(placeholder: S.Asset.quantity, keyboardType: .quantityPad)
    private let feeView: FeeAmountVC
    private let unitsCell = UnitsCell(placeholder: S.Asset.unitsLabel)
    private let reissubaleCell = CheckBoxCell(labelCheckBox: S.Asset.isReissubaleLabel)
    private let ipfsCell = IPFSCell(labelCheckBox: S.Asset.hasIpfsLabel, placeholder: S.Asset.ipfsHashLabel)
    private let createButton = ShadowButton(title: S.Asset.create, type: .tertiary)
    private let currencyBorder = UIView(color: .secondaryShadow)
    private var currencySwitcherHeightConstraint: NSLayoutConstraint?
    private var pinPadHeightConstraint: NSLayoutConstraint?
    private var balance: UInt64 = 0
    private var feeAmount: UInt64 = 0
    private var quantity: Satoshis?
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
        view.addSubview(nameCell)
        view.addSubview(addressCell)
        view.addSubview(reissubaleCell)
        view.addSubview(ipfsCell)
        view.addSubview(createButton)
    }
    
    private func addConstraints() {
        nameCell.constrainTopCorners(height: SendCell.defaultHeight)
        addressCell.constrain([
            addressCell.widthAnchor.constraint(equalTo: nameCell.widthAnchor),
            addressCell.topAnchor.constraint(equalTo: nameCell.bottomAnchor),
            addressCell.leadingAnchor.constraint(equalTo: nameCell.leadingAnchor),
            addressCell.heightAnchor.constraint(equalToConstant: SendCell.defaultHeight) ])
        
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
            reissubaleCell.heightAnchor.constraint(equalTo: addressCell.heightAnchor, constant: -C.padding[2]) ])
        
        ipfsCell.constrain([
            ipfsCell.widthAnchor.constraint(equalTo: reissubaleCell.widthAnchor),
            ipfsCell.topAnchor.constraint(equalTo: reissubaleCell.bottomAnchor),
            ipfsCell.leadingAnchor.constraint(equalTo: reissubaleCell.leadingAnchor),
            ipfsCell.heightAnchor.constraint(equalTo: addressCell.heightAnchor, constant: 0) ])
        
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
        nameCell.textField.autocapitalizationType = .allCharacters
        if initialAddress != nil {
            addressCell.setContent(initialAddress)
        }
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
        addressCell.paste.addTarget(self, action: #selector(CreateAssetVC.pasteTapped), for: .touchUpInside)
        addressCell.scan.addTarget(self, action: #selector(CreateAssetVC.scanTapped), for: .touchUpInside)
        addressCell.addressBook.addTarget(self, action: #selector(CreateAssetVC.addressBookTapped), for: .touchUpInside)

        ipfsCell.paste.addTarget(self, action: #selector(CreateAssetVC.pasteTapped), for: .touchUpInside)
        ipfsCell.scan.addTarget(self, action: #selector(CreateAssetVC.scanTapped), for: .touchUpInside)

        createButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        
        nameCell.didReturn = { textField in
            textField.resignFirstResponder()
            guard AssetValidator.shared.IsAssetNameValid(name: self.nameCell.textField.text!).0 else {
                return self.showAlert(title: S.Alert.error, message: S.Asset.errorAssetNameMessage, buttonLabel: S.Button.ok)
            }
            
            //Check if name asset disponible
            AssetManager.shared.isAssetNameExiste(name: self.nameCell.textField.text!, callback: { (assetName, isExiste) in
                if isExiste {
                    self.showAlert(title: S.Alert.error, message: S.Asset.errorAssetMessage, buttonLabel: S.Button.ok)
                }
            })
        }
        
        nameCell.didBeginEditing = { [weak self] in
            self?.quantityView.closePinPad()
            self?.unitsCell.closePinPad()
        }
        
        ipfsCell.didBeginEditing = { [weak self] in
            self?.quantityView.closePinPad()
            self?.unitsCell.closePinPad()
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
        
        unitsCell.didChangeFirstResponder = { [weak self] isFirstResponder in
            if isFirstResponder {
                self?.nameCell.textField.resignFirstResponder()
                self?.addressCell.textField.resignFirstResponder()
                self?.quantityView.closePinPad()
                self?.ipfsCell.textField.resignFirstResponder()
            }
        }
        
        quantityView.didUpdateAmount = { [weak self] amount in
            self?.quantity = amount
        }
        
        feeView.didUpdateAssetFee = { [weak self] feeAmount in
            self?.feeAmount = feeAmount
        }
        //initiate feeview balance
        feeView.balance = self.balance
    }

    @objc private func pasteTapped(sender:UIButton) {
        guard let pasteboard = UIPasteboard.general.string, pasteboard.utf8.count > 0 else {
            return showAlert(title: S.Alert.error, message: S.Send.emptyPasteboard, buttonLabel: S.Button.ok)
        }
        
        guard PaymentRequest(string: pasteboard, currency: currency) != nil else {
            let message = String.init(format: S.Send.invalidAddressOnPasteboard, currency.name)
            return showAlert(title: S.Send.invalidAddressTitle, message: message, buttonLabel: S.Button.ok)
        }
        if sender.superview == addressCell {
            addressCell.setContent(pasteboard)
        }
        else if sender.superview == ipfsCell{
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
    
    @objc private func sendTapped() {
        if addressCell.textField.isFirstResponder {
            addressCell.textField.resignFirstResponder()
        }

        if sender.transaction == nil {
            guard self.nameCell.textField.text != nil else {
                return showAlert(title: S.Alert.error, message: S.Asset.noName, buttonLabel: S.Button.ok)
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
                return showAlert(title: S.Alert.error, message: S.Asset.noQuanity, buttonLabel: S.Button.ok)
            }
            
            guard let amount = quantity else {
                return showAlert(title: S.Alert.error, message: S.Send.noAmount, buttonLabel: S.Button.ok)
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
            //sender
            asset = Asset.init(idAsset: -1, name: self.nameCell.textField.text!, amount: amount, units: Int(exactly: unitsCell.amount!.rawValue / 100000000)!, reissubale: reissubaleCell.btnCheckBox.isSelected ? 1 : 0, hasIpfs: ipfsCell.hasIpfs ? 1 : 0, ipfsHash: ipfsCell.ipfsHash!, ownerShip: -1, hidden: -1, sort: -1)
            
            let assetToSend: BRAssetRef = BRAsset.createAssetRef(asset: asset!, type: NEW_ASSET, amount: amount)
            guard sender.createAssetTransaction(amount: 0, to: address, asset: assetToSend) else {
                return showAlert(title: S.Alert.error, message: S.Send.createTransactionError, buttonLabel: S.Button.ok)
            }
        }
        
        
        guard let amount = quantity else { return }
        let confirm = ConfirmationViewController(amount: amount, fee: Satoshis(sender.fee), feeType: feeType ?? .regular, selectedRate: nil, minimumFractionDigits: quantityView.minimumFractionDigits, address: addressCell.displayAddress ?? "", isUsingBiometrics: sender.canUseBiometrics, operationType: .createAsset, assetToSend: asset)
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
                    self?.saveEvent("create.success")
                case .creationError(let message):
                    self?.showAlert(title: S.Send.createTransactionError, message: message, buttonLabel: S.Button.ok)
                    self?.saveEvent("create.publishFailed", attributes: ["errorMessage": message])
                case .publishFailure(let error):
                    if case .posixError(let code, let description) = error {
                        self?.showAlert(title: S.Alerts.sendFailure, message: "\(description) (\(code))", buttonLabel: S.Button.ok)
                        self?.saveEvent("create.publishFailed", attributes: ["errorMessage": "\(description) (\(code))"])
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

extension CreateAssetVC : ModalDisplayable {
    var faqArticleId: String? {
        return nil
    }

    var modalTitle: String {
        return "\(S.Asset.createTitle)"
    }
}
