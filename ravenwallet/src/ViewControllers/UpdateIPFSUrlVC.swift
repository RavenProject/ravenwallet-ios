//
//  SendViewController.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2016-11-30.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit

class UpdateIPFSUrlVC : UIViewController, Subscriber, ModalPresentable {

    //MARK - Public
    var parentView: UIView? //ModalPresentable
    var origineParentFrame:CGRect?

    //MARK - Private
    deinit {
        Store.unsubscribe(self)
        NotificationCenter.default.removeObserver(self)
    }

    private let ipfsTextField = UITextField()
    private let updateButton = ShadowButton(title: "Save", type: .tertiary)
    private let borderTop = UIView(color: .secondaryShadow)
    private let borderbottom = UIView(color: .secondaryShadow)

    override func viewDidLoad() {
        addSubviews()
        addConstraints()
        addSubscriptions()
        addButtonActions()
        setInitialData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        origineParentFrame = self.parentView?.frame
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        ipfsTextField.becomeFirstResponder()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func addSubviews() {
        view.backgroundColor = .white
        view.addSubview(ipfsTextField)
        view.addSubview(updateButton)
        view.addSubview(borderbottom)
    }
    
    private func addConstraints() {
        borderbottom.constrain([
            borderbottom.constraint(.leading, toView: view),
            borderbottom.constraint(.trailing, toView: view),
            borderbottom.constraint(.height, constant: 1),
            borderbottom.topAnchor.constraint(equalTo: ipfsTextField.bottomAnchor)
        ])
        ipfsTextField.constrain([
            ipfsTextField.constraint(.top, toView: view),
            ipfsTextField.constraint(.leading, toView: view, constant: C.padding[2]),
            ipfsTextField.constraint(.trailing, toView: view, constant: -C.padding[2]),
            ipfsTextField.constraint(.height, constant: createNameAssetHeight)
        ])
        updateButton.constrain([
            updateButton.constraint(.leading, toView: view, constant: C.padding[2]),
            updateButton.constraint(.trailing, toView: view, constant: -C.padding[2]),
            updateButton.constraint(toBottom: ipfsTextField, constant: verticalButtonPadding),
            updateButton.constraint(.height, constant: C.Sizes.buttonHeight),
            updateButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: E.isIPhoneXOrLater ? -C.padding[5] : -C.padding[2]) ])
    }
    
    private func setInitialData() {
        keyboardShowed = false
        ipfsTextField.text = UserDefaults.ipfsUrl
        ipfsTextField.font = .customBody(size: 14.0)
        ipfsTextField.textColor = .darkText
        ipfsTextField.returnKeyType = .done
        ipfsTextField.delegate = self
        ipfsTextField.clearButtonMode = .whileEditing
        ipfsTextField.autocorrectionType = .no
        ipfsTextField.autocapitalizationType = .none
    }
    
    private func addSubscriptions() {
    }
    
    private func addButtonActions() {
        updateButton.tap = {
            guard !self.ipfsTextField.text!.isEmpty else {
                self.ipfsTextField.becomeFirstResponder()
                return
            }
            UserDefaults.ipfsUrl = self.ipfsTextField.text!
            self.ipfsTextField.resignFirstResponder()
            self.dismiss(animated: true, completion: nil)
        }
    }

    //MARK: - Keyboard Notifications
    @objc private func keyboardWillShow(notification: Notification) {
        if !keyboardShowed {
            keyboardShowed = true
            copyKeyboardChangeAnimation(notification: notification)
        }
    }

    @objc private func keyboardWillHide(notification: Notification) {
        keyboardShowed = false
        copyKeyboardChangeAnimation(notification: notification)
    }

    //TODO - maybe put this in ModalPresentable?
    func copyKeyboardChangeAnimation(notification: Notification) {
        guard let info = KeyboardNotificationInfo(notification.userInfo) else { return }
        UIView.animate(withDuration: info.animationDuration, delay: 0, options: info.animationOptions, animations: {
            guard let parentView = self.parentView else { return }
            let diff:CGFloat = info.deltaY //- createAddressHeight
            if keyboardShowed {
                parentView.frame = parentView.frame.offsetBy(dx: 0, dy: diff)
            }
            else{
                parentView.frame = self.origineParentFrame!
            }
        }, completion: nil)
    }

    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        ipfsTextField.resignFirstResponder()
        return true;
    }
}

extension UpdateIPFSUrlVC : ModalDisplayable {
    var faqArticleId: String? {
        return nil
    }

    var modalTitle: String {
        return "Update IPFS Url"
    }
}

