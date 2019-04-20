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

private let buttonSize = CGSize(width: 52.0, height: 32.0)

class TransferAssetVC : UIViewController, Subscriber, ModalPresentable {

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
        self.sender = SenderAsset(walletManager: self.walletManager, currency: self.currency, operationType: .transferAsset)
        self.addressCell = AddressCell(currency: self.currency)
        self.feeView = FeeAmountVC(walletManager: walletManager, sender: self.sender, operationType: .transferAsset)
        self.quantityView = QuantityCell(asset: asset, placeholder: S.Asset.quantity, keyboardType: asset.units == 0 ? .quantityPad : .decimalPad, maxDigits: Int(asset.units))
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
    private let quantityView: QuantityCell
    private let feeView: FeeAmountVC
    private let addressCell: AddressCell
    private let transferOwnerShip = CheckBoxCell(labelCheckBox: S.Asset.transferOwnerShip)
    private let transferButton = ShadowButton(title: S.Asset.transfer, type: .tertiary)
    private let currencyBorder = UIView(color: .secondaryShadow)
    private var balance: UInt64 = 0
    private var feeAmount: UInt64 = 0
    private var quantity: Satoshis?
    private var didIgnoreUsedAddressWarning = false
    private var didIgnoreIdentityNotCertified = false
    private let initialRequest: PaymentRequest?
    private let confirmTransitioningDelegate = PinTransitioningDelegate()
    private var feeType: Fee?
    private let currency: CurrencyDef = Currencies.rvn //BMEX
    private var transferOwnerShipHeight: NSLayoutConstraint?
    private let checkBoxNameCell = CheckBoxCell(labelCheckBox: S.Send.saveInAddresBook, placeholder: S.AddressBook.nameAddressLabel)

    override func viewDidLoad() {
        addSubviews()
        addConstraints()
        addSubscriptions()
        addButtonActions()
        setInitialData()
    }
    
    func addSubviews() {
        view.backgroundColor = .white
        view.addSubview(addressCell)
        addChildVC(quantityView)
        view.addSubview(transferOwnerShip)
        view.addSubview(transferButton)
        addChildVC(feeView)
        view.addSubview(checkBoxNameCell)
        transferOwnerShip.clipsToBounds = true

    }
    private func addConstraints() {
        addressCell.constrainTopCorners(height: SendCell.defaultHeight)
        quantityView.view.constrain([
            quantityView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            quantityView.view.topAnchor.constraint(equalTo: addressCell.bottomAnchor),
            quantityView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            quantityView.view.heightAnchor.constraint(equalTo: addressCell.heightAnchor, constant: -C.padding[2])])
        
        transferOwnerShipHeight = transferOwnerShip.heightAnchor.constraint(equalToConstant: 0)
        transferOwnerShip.constrain([
            transferOwnerShip.leadingAnchor.constraint(equalTo: addressCell.leadingAnchor),
            transferOwnerShip.trailingAnchor.constraint(equalTo: addressCell.trailingAnchor),
            transferOwnerShip.widthAnchor.constraint(equalTo: addressCell.widthAnchor),
            transferOwnerShip.topAnchor.constraint(equalTo: quantityView.view.bottomAnchor),
            transferOwnerShipHeight
            ])
        
        feeView.view.constrain([
            feeView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            feeView.view.topAnchor.constraint(equalTo: transferOwnerShip.bottomAnchor),
            feeView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor) ])
        
        checkBoxNameCell.constrain([
            checkBoxNameCell.widthAnchor.constraint(equalTo: feeView.view.widthAnchor),
            checkBoxNameCell.topAnchor.constraint(equalTo: feeView.view.bottomAnchor),
            checkBoxNameCell.leadingAnchor.constraint(equalTo: feeView.view.leadingAnchor),
            checkBoxNameCell.heightAnchor.constraint(equalTo: addressCell.heightAnchor, constant: -C.padding[2]) ])
        
        checkBoxNameCell.accessoryView.constrain([
            checkBoxNameCell.accessoryView.constraint(.width, constant: 0.0) ])
        
        transferButton.constrain([
            transferButton.constraint(.leading, toView: view, constant: C.padding[2]),
            transferButton.constraint(.trailing, toView: view, constant: -C.padding[2]),
            transferButton.constraint(toBottom: checkBoxNameCell, constant: verticalButtonPadding),
            transferButton.constraint(.height, constant: C.Sizes.buttonHeight),
            transferButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: E.isIPhoneXOrLater ? -C.padding[5] : -C.padding[2]) ])
    }

    private func addButtonActions() {
        addressCell.paste.addTarget(self, action: #selector(TransferAssetVC.pasteTapped), for: .touchUpInside)
        addressCell.scan.addTarget(self, action: #selector(TransferAssetVC.scanTapped), for: .touchUpInside)
        addressCell.addressBook.addTarget(self, action: #selector(TransferAssetVC.addressBookTapped), for: .touchUpInside)
        transferButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        addressCell.didBeginEditing = strongify(self) { myself in
            myself.quantityView.closePinPad()
        }

        quantityView.didChangeFirstResponder = { [weak self] isFirstResponder in
            if isFirstResponder {
                self?.addressCell.textField.resignFirstResponder()
            }
        }
        
        quantityView.didUpdateAmount = { [weak self] amount in
            self?.quantity = amount
        }
        
        feeView.didUpdateAssetFee = { [weak self] feeAmount in
            self?.feeAmount = feeAmount
        }
        
        transferOwnerShip.didSelected = { isSelected in
            self.quantityView.amount = nil
            self.quantityView.isEnabled = !isSelected
        }
        //initiate feeview balance
        feeView.balance = self.balance
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
    
    private func setInitialData() {
        if initialAddress != nil {
            addressCell.setContent(initialAddress)
        }
        if asset.isOwnerShip {
            transferOwnerShipHeight?.constant = SendCell.defaultHeight - C.padding[2]
            view.layoutIfNeeded()
        }
        //disable quantity for unique asset
        if asset.name.contains("#") {
            quantityView.amount = Satoshis(C.oneAsset)
            quantityView.isEnabled = false
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        makeKeyBoardToolBar()
    }


    @objc private func pasteTapped() {
        guard let pasteboard = UIPasteboard.general.string, pasteboard.utf8.count > 0 else {
            return showAlert(title: S.Alert.error, message: S.Send.emptyPasteboard, buttonLabel: S.Button.ok)
        }

        guard PaymentRequest(string: pasteboard, currency: currency) != nil else {
            let message = String.init(format: S.Send.invalidAddressOnPasteboard, currency.name)
            return showAlert(title: S.Send.invalidAddressTitle, message: message, buttonLabel: S.Button.ok)
        }
        
        addressCell.setContent(pasteboard)
    }

    @objc private func scanTapped() {
        addressCell.textField.resignFirstResponder()
        presentScan? { [weak self] paymentRequest in
            self?.addressCell.setContent(paymentRequest?.displayAddress)
        }
    }
    
    @objc private func addressBookTapped() {
        addressCell.textField.resignFirstResponder()
        Store.trigger(name: .selectAddressBook(.select, ({ address in
            self.addressCell.setContent(address)
        })))
    }
    
    func saveNewAddressBook() {
        if checkBoxNameCell.btnCheckBox.isSelected {
            guard !(checkBoxNameCell.textField.text?.isEmpty)! else {
                return showAlert(title: S.Alert.error, message: S.AddressBook.noNameAddress, buttonLabel: S.Button.ok)
            }
            let newAddress = AddressBook(name: checkBoxNameCell.textField.text!, address: addressCell.address!)
            let addressBookManager = AddressBookManager()
            addressBookManager.addAddressBook(newAddress: newAddress, successCallBack: {
                Store.perform(action: Alert.Show(.addressAdded(callback: nil)))
            }, faillerCallBack: {
                //if already existe dont show error
            })
        }
    }

    @objc private func sendTapped() {
        if addressCell.textField.isFirstResponder {
            addressCell.textField.resignFirstResponder()
        }
        var amount = Satoshis.zero //BMEX Todo : check amount value if transferOwnerShip selected

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
            guard !(walletManager.wallet?.containsAddress(address) ?? false) else {
                return showAlert(title: S.Alert.error, message: S.Send.containsAddress, buttonLabel: S.Button.ok)
            }
            if !transferOwnerShip.btnCheckBox.isSelected {
                guard quantity != nil else {
                    return showAlert(title: S.Alert.error, message: S.Send.noAmount, buttonLabel: S.Button.ok)
                }
                amount = quantity!
                guard amount.rawValue <= asset.amount.rawValue else {
                    return showAlert(title: S.Alert.error, message: S.Asset.insufficientAssetFunds, buttonLabel: S.Button.ok)
                }
                guard amount != Satoshis.zero else {
                    return showAlert(title: S.Alert.error, message: S.Send.noAmount, buttonLabel: S.Button.ok)
                }
                sender.operationType = .transferAsset
            }
            else {
                amount = Satoshis.init(C.ownerShipAsset)//one asset
                asset.ownerShip = 1
                asset.name = asset.name + C.OWNER_TAG
                asset.amount = amount
                sender.operationType = .transferOwnerShipAsset
            }
            
            //BMEX Todo : manage maxOutputAmount and minOutputAmount
            guard feeAmount <= balance else {
                return showAlert(title: S.Alert.error, message: S.Send.insufficientFunds, buttonLabel: S.Button.ok)
            }
            
            //BMEX save AddressBook
            saveNewAddressBook()
            
            //sender Asset
            let assetToSend: BRAssetRef = BRAsset.createAssetRef(asset: asset, type: TRANSFER, amount: amount)
            guard sender.createAssetTransaction(amount: 0, to: address, asset: assetToSend) else {
                return showAlert(title: S.Alert.error, message: S.Send.createTransactionError, buttonLabel: S.Button.ok)
            }
        }
        
        let confirm = ConfirmationViewController(amount: amount, fee: Satoshis(sender.fee), feeType: feeType ?? .regular, selectedRate: nil, minimumFractionDigits: quantityView.minimumFractionDigits, address: addressCell.displayAddress ?? "", isUsingBiometrics: sender.canUseBiometrics, operationType: .transferAsset, assetToSend: asset)
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
                case .creationError(let message):
                    self?.showAlert(title: S.Send.createTransactionError, message: message, buttonLabel: S.Button.ok)
                case .publishFailure(let error):
                    if case .posixError(let code, let description) = error {
                        self?.showAlert(title: S.Alerts.sendFailure, message: "\(description) (\(code))", buttonLabel: S.Button.ok)
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

extension TransferAssetVC : ModalDisplayable {
    var faqArticleId: String? {
        return nil
    }

    var modalTitle: String {
        return "\(S.Asset.transferTitle) \(asset.name)"
    }
}
