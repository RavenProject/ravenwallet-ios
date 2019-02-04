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
    var content: String? {
        didSet {
            textField.text = content
            textFieldDidChange(textField)
        }
    }

    let textField = UITextField()
    let placeholder = UILabel(font: .customBody(size: 16.0), color: .grayTextTint)

    func setupViews() {
        addSubview(textField)
        textField.addSubview(placeholder)
        
        textField.constrain([
            textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 11.0),
            textField.centerYAnchor.constraint(equalTo: centerYAnchor),
            textField.heightAnchor.constraint(greaterThanOrEqualToConstant: 30.0),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -C.padding[2]) ])

        placeholder.constrain([
            placeholder.centerYAnchor.constraint(equalTo: textField.centerYAnchor),
            placeholder.leadingAnchor.constraint(equalTo: textField.leadingAnchor, constant: 5.0) ])
    }
    
    func setInitialData() {
        textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
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
    
    //func textFieldDidEndEditing(_ textField: UITextField) {
    //    didReturn?(textField)
    //}
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        let count = text.count + string.count - range.length
        return count <= C.MAX_ADDRESSBOOK_NAME_LENGTH
    }
}
