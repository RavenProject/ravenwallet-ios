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
        self.addressCell = AddressCell(currency: self.currency, type: .create)
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
    private let sender: SenderAsset
    private let walletManager: WalletManager
    private let addressCell: AddressCell
    private let quantityView: QuantityCell
    private let feeView: FeeAmountVC
    private let unitsCell = UnitsCell(placeholder: S.Asset.unitsLabel, isEnabled: false)
    private let reissubaleCell = CheckBoxCell(labelCheckBox: S.Asset.isReissubaleLabel)
    private let ipfsCell = IPFSCell(labelCheckBox: S.Asset.hasIpfsLabel, placeholder: S.Asset.ipfsHashLabel)
    private let createButton = ShadowButton(title: S.Asset.create, type: .tertiary)
    private let currencyBorder = UIView(color: .secondaryShadow)
    private var currencySwitcherHeightConstraint: NSLayoutConstraint?
    private var pinPadHeightConstraint: NSLayoutConstraint?
    private var balance: UInt64 = 0
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
        addButtonActions()
        setInitialData()
        addSubscriptions()
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
        addressCell.constrainTopCorners(height: SendCell.defaultHeight)
        
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
        if initialAddress != nil {
            addressCell.setContent(initialAddress)
            //BMEX amountView.expandPinPad()
        }
        
    }
    
    private func addSubscriptions() {
        //
    }

    private func addButtonActions() {
        addressCell.paste.addTarget(self, action: #selector(ManageOwnedAssetVC.pasteTapped), for: .touchUpInside)
        addressCell.scan.addTarget(self, action: #selector(ManageOwnedAssetVC.scanTapped), for: .touchUpInside)
        addressCell.addressBook.addTarget(self, action: #selector(ManageOwnedAssetVC.addressBookTapped), for: .touchUpInside)
        ipfsCell.paste.addTarget(self, action: #selector(ManageOwnedAssetVC.pasteTapped), for: .touchUpInside)
        ipfsCell.scan.addTarget(self, action: #selector(ManageOwnedAssetVC.scanTapped), for: .touchUpInside)
        createButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        
        ipfsCell.didBeginEditing = { [weak self] in
            self?.quantityView.closePinPad()
            self?.unitsCell.closePinPad()
        }
        
        /*unitsCell.didReturn = { textField in
            guard (textField.text?.isEmpty)! else {
                guard Int(textField.text!)! < 8 else {
                    return self.showAlert(title: S.Alert.error, message: S.Asset.errorUnitsMessage, buttonLabel: S.Button.ok)
                }
                return
            }
        }*/
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
        
        unitsCell.didChangeFirstResponder = { [weak self] isFirstResponder in
            if isFirstResponder {
                self?.addressCell.textField.resignFirstResponder()
                self?.quantityView.closePinPad()
                self?.ipfsCell.textField.resignFirstResponder()
            }
        }
    }

    @objc private func pasteTapped(sender: UIButton) {
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
    
    @objc private func sendTapped() {
        if addressCell.textField.isFirstResponder {
            addressCell.textField.resignFirstResponder()
        }

        if sender.transaction == nil {
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
            guard let amount = amount else {
                return showAlert(title: S.Alert.error, message: S.Send.noAmount, buttonLabel: S.Button.ok)
            }
            if let minOutput = walletManager.wallet?.minOutputAmount {
                guard amount.rawValue >= minOutput else {
                    let minOutputAmount = Amount(amount: minOutput, rate: Rate.empty, maxDigits: currency.state.maxDigits, currency: currency)
                    let message = String(format: S.PaymentProtocol.Errors.smallPayment, minOutputAmount.string(isBtcSwapped: Store.state.isSwapped))
                    return showAlert(title: S.Alert.error, message: message, buttonLabel: S.Button.ok)
                }
            }
            guard !(walletManager.wallet?.containsAddress(address) ?? false) else {
                return showAlert(title: S.Alert.error, message: S.Send.containsAddress, buttonLabel: S.Button.ok)
            }
            guard amount.rawValue <= (walletManager.wallet?.maxOutputAmount ?? 0) else {
                return showAlert(title: S.Alert.error, message: S.Send.insufficientFunds, buttonLabel: S.Button.ok)
            }
            
            if ipfsCell.hasIpfs {
                guard let ipfsHash = ipfsCell.content else {
                    return showAlert(title: S.Alert.error, message: S.Asset.noIpfsHash, buttonLabel: S.Button.ok)
                }
                guard AssetValidator.shared.IsIpfsHashValid(ipfsHash: ipfsHash) else {
                    let message = String.init(format: S.Asset.invalidIpfsHashMessage, currency.name)
                    return showAlert(title: S.Send.invalidAddressTitle, message: message, buttonLabel: S.Button.ok)
                }
            }
            //sender
            
        }
        

        guard amount != nil else { return }
        return
    }

    private func send() {
        guard currency.state.currentRate != nil else { return }
        guard (walletManager.wallet?.feePerKb) != nil else { return }
        //BMEX
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
