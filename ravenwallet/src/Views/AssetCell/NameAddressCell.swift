//
//  DescriptionSendCell.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2016-12-16.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit

class NameAddressCell : SendCell {

    init(placeholder: String) {
        super.init()
        textField.delegate = self
        textField.textColor = .darkText
        textField.font = .customBody(size: 20.0)
        textField.autocorrectionType = .no
        textField.returnKeyType = .done
        self.placeholder.text = placeholder
        setupViews()
        setInitialData()
    }

    var didBeginEditing: (() -> Void)?
    var didReturn: ((UITextField) -> Void)?
    var didChange: ((String) -> Void)?
    var didVerifyTapped: ((String?) -> Void)?
    var isVerifyShowing: Bool = false {
        didSet {
            verify.isHidden = !isVerifyShowing
        }
    }
    var content: String? {
        didSet {
            textField.text = content
            textFieldDidChange(textField)
        }
    }

    let textField = UITextField()
    fileprivate let placeholder = UILabel(font: .customBody(size: 16.0), color: .grayTextTint)
    private let verify = ShadowButton(title: S.Asset.verifyLabel, type: .secondary)
    let activityView = UIActivityIndicatorView(style: .white)

    private func setupViews() {
        addSubview(textField)
        textField.addSubview(placeholder)
        addSubview(verify)
        verify.addSubview(activityView)

        textField.constrain([
            textField.constraint(.leading, toView: self, constant: 11.0),
            textField.topAnchor.constraint(equalTo: topAnchor, constant: C.padding[2]),
            textField.heightAnchor.constraint(greaterThanOrEqualToConstant: 30.0),
            textField.trailingAnchor.constraint(equalTo: verify.leadingAnchor, constant: -C.padding[2]) ])

        placeholder.constrain([
            placeholder.centerYAnchor.constraint(equalTo: textField.centerYAnchor),
            placeholder.leadingAnchor.constraint(equalTo: textField.leadingAnchor, constant: 5.0) ])
        
        verify.constrain([
            verify.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -C.padding[2]),
            verify.topAnchor.constraint(equalTo: topAnchor, constant: C.padding[2])])
        
        activityView.constrain([
            activityView.centerXAnchor.constraint(equalTo: verify.centerXAnchor),
            activityView.centerYAnchor.constraint(equalTo: verify.centerYAnchor)])

    }
    
    private func setInitialData() {
        textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        verify.addTarget(self, action: #selector(NameAddressCell.verifyTapped), for: .touchUpInside)
        verify.isHidden = !isVerifyShowing
        activityView.hidesWhenStopped = true
        activityView.stopAnimating()
    }
    
    @objc func verifyTapped() {
        activityView.startAnimating()
        verify.label.isHidden = true
        self.didVerifyTapped!(self.textField.text)
    }
    
    func checkAvailabilityResult(isFound:Bool) {
        self.textField.textColor = .darkText
        verify.label.isHidden = false
        if isFound {
            self.textField.textColor = .red
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension NameAddressCell : UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        didBeginEditing?()
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        placeholder.isHidden = (textField.text?.utf8.count)! > 0
        textField.textColor = .darkText
        if let text = textField.text {
            didChange?(text)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        didReturn?(textField)
        return true;
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        didReturn?(textField)
    }
}
