//
//  AddAddressBookVC.swift
//  ravenwallet
//
//  Created by Ben on 2018-10-30.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit
import LocalAuthentication
import Core

enum ActionAddressType {//BMEX
    case add
    case update
}

private let buttonSize = CGSize(width: 52.0, height: 32.0)

class AddAddressBookVC : UIViewController, Subscriber, ModalPresentable, Trackable {
    
    //MARK - Public
    var presentScan: PresentScan?
    var presentVerifyPin: ((String, @escaping ((String) -> Void))->Void)?
    var parentView: UIView? //ModalPresentable
    var initialAddress: String?
    var db: CoreDatabase?
    var actionAddressType: ActionAddressType
    let addressBookManager:AddressBookManager = AddressBookManager()

    init(currency: CurrencyDef, initialAddress: String? = nil, type:ActionAddressType = .add, callback: @escaping () -> Void) {
        print("init AddAddressViewController called")
        self.currency = currency
        self.addressCell = AddressCell(currency: currency, type: .create, isAddressBookBtnHidden: true)
        self.db = CoreDatabase()
        self.actionAddressType = type
        self.initialAddress = initialAddress
        self.callback = callback
        super.init(nibName: nil, bundle: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    //MARK - Private
    deinit {
        Store.unsubscribe(self)
        NotificationCenter.default.removeObserver(self)
    }
    
    private let addressCell: AddressCell
    private let nameCell = NameAddressCell(placeholder: S.AddressBook.nameAddressLabel)
    private var addButton:ShadowButton?
    private let currencyBorder = UIView(color: .secondaryShadow)
    private var currencySwitcherHeightConstraint: NSLayoutConstraint?
    private var pinPadHeightConstraint: NSLayoutConstraint?
    private var balance: UInt64 = 0
    private var didIgnoreUsedAddressWarning = false
    private var didIgnoreIdentityNotCertified = false
    private let currency: CurrencyDef
    let callback: () -> Void

    override func viewDidLoad() {
        view.backgroundColor = .white
        let titleAddButton = (self.actionAddressType == .add) ? S.Button.addAddress : S.Button.updateAddress
        addButton = ShadowButton(title: titleAddButton, type: .secondary)
        view.addSubview(addressCell)
        view.addSubview(nameCell)
        view.addSubview(addButton!)
        
        addressCell.constrainTopCorners(height: SendCell.defaultHeight)
        
        nameCell.constrain([
            nameCell.widthAnchor.constraint(equalTo: addressCell.widthAnchor),
            nameCell.topAnchor.constraint(equalTo: addressCell.bottomAnchor),
            nameCell.leadingAnchor.constraint(equalTo: addressCell.leadingAnchor),
            nameCell.heightAnchor.constraint(equalTo: nameCell.textField.heightAnchor, constant: C.padding[4]) ])
        
        nameCell.accessoryView.constrain([
            nameCell.accessoryView.constraint(.width, constant: 0.0) ])
        
        addButton?.constrain([
            addButton?.constraint(.leading, toView: view, constant: C.padding[2]),
            addButton?.constraint(.trailing, toView: view, constant: -C.padding[2]),
            addButton?.constraint(toBottom: nameCell, constant: verticalButtonPadding),
            addButton?.constraint(.height, constant: C.Sizes.buttonHeight),
            addButton?.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: E.isIPhoneXOrLater ? -C.padding[5] : -C.padding[2]) ])
        addButtonActions()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if initialAddress != nil {
            addressCell.setContent(initialAddress)
        }
    }
    
    private func addButtonActions() {
        addressCell.paste.addTarget(self, action: #selector(AddAddressBookVC.pasteTapped), for: .touchUpInside)
        addressCell.scan.addTarget(self, action: #selector(AddAddressBookVC.scanTapped), for: .touchUpInside)
        addButton?.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        nameCell.didReturn = { textField in
            textField.resignFirstResponder()
        }
        nameCell.didBeginEditing = { [weak self] in
        }
        addressCell.didBeginEditing = strongify(self) { myself in
        }
    }
    
    @objc private func pasteTapped() {
        guard let pasteboard = UIPasteboard.general.string, pasteboard.utf8.count > 0 else {
            return showAlert(title: S.Alert.error, message: S.Send.emptyPasteboard, buttonLabel: S.Button.ok)
        }
        addressCell.setContent(pasteboard)
    }
    
    @objc private func scanTapped() {
        nameCell.textField.resignFirstResponder()
        addressCell.textField.resignFirstResponder()
        //BMEX
        presentScan? { [weak self] paymentRequest in
            self?.addressCell.setContent(paymentRequest?.displayAddress)
        }
    }
    
    @objc private func addTapped() {
        if addressCell.textField.isFirstResponder {
            addressCell.textField.resignFirstResponder()
        }
        
        guard let address = addressCell.address else {
            return showAlert(title: S.Alert.error, message: S.Send.noAddress, buttonLabel: S.Button.ok)
        }
        
        guard address.isValidAddress else {
            let message = String.init(format: S.Send.invalidAddressMessage, currency.name)
            return showAlert(title: S.Send.invalidAddressTitle, message: message, buttonLabel: S.Button.ok)
        }
        
        guard !(nameCell.textField.text?.isEmpty)! else {
            return showAlert(title: S.Alert.error, message: S.AddressBook.noNameAddress, buttonLabel: S.Button.ok)
        }
        
        let newAddress = AddressBook(name: nameCell.textField.text!, address: address)
        if self.actionAddressType == .add {
            addAddressBook(newAddress: newAddress)
        }
        else{
            updateAddressBook(newAddress: newAddress)
        }
        
        return
    }
    
    func addAddressBook(newAddress:AddressBook) {
        addressBookManager.addAddressBook(newAddress: newAddress, successCallBack: {
            Store.perform(action: Alert.Show(.addressAdded(callback: { [weak self] in
            })))
            DispatchQueue.main.async {
                self.dismiss(animated: false, completion: nil)
                self.callback()
            }
        }, faillerCallBack: {
            DispatchQueue.main.async {
                self.showAlert(title: S.Alert.error, message: S.AddressBook.errorAddressMessage, buttonLabel: S.Button.ok)
            }
        })
    }
    
    func updateAddressBook(newAddress:AddressBook) {
        addressBookManager.updateAddressBook(newAddress: newAddress, oldAddress: initialAddress!, successCallBack: {
            Store.perform(action: Alert.Show(.addressUpdated))
            DispatchQueue.main.async {
                self.dismiss(animated: false, completion: nil)
                self.callback()
            }
        }, faillerCallBack: {
            DispatchQueue.main.async {
                self.showAlert(title: S.AddressBook.errorBaseTitle, message: S.AddressBook.errorBaseMessage, buttonLabel: S.Button.ok)
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

extension AddAddressBookVC : ModalDisplayable {
    var faqArticleId: String? {
        return nil
    }
    
    var modalTitle: String {
        return "\((self.actionAddressType == .add) ? S.AddressBook.titleAdd : S.AddressBook.titleUpdate)"
    }
}
