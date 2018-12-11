//
//  DescriptionSendCell.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2016-12-16.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit

class CheckBoxCell : SendCell {

    init(labelCheckBox: String ,placeholder: String) {
        super.init()
        textField.delegate = self
        textField.textColor = .darkText
        textField.font = .customBody(size: 20.0)
        textField.returnKeyType = .done
        textField.autocorrectionType = .no
        self.labelChoice.text = labelCheckBox
        self.placeHolderString = placeholder
        self.placeholder.text = placeholder
        self.placeholder.isHidden = true
        setupViews()
        setInitialData()
    }
    
    init(labelCheckBox: String) {
        super.init()
        self.labelChoice.text = labelCheckBox
        setupViews()
        setInitialData()
    }

    var placeHolderString : String?
    fileprivate let placeholder = UILabel(font: .customBody(size: 16.0), color: .grayTextTint)
    let labelChoice = UILabel(font: .customBody(size: 16.0), color: .grayTextTint)
    let btnCheckBox = ShadowButton(type: .checkBox, image: #imageLiteral(resourceName: "CircleUnCheckSolid"), selectedImage: #imageLiteral(resourceName: "CircleCheckSolid"))
    let textField = UITextField()
    var didBeginEditing: (() -> Void)?
    var didReturn: ((UITextField) -> Void)?
    var didChange: ((String) -> Void)?
    var content: String? {
        didSet {
            textField.text = content
            textFieldDidChange(textField)
        }
    }


    private func setupViews() {
        addSubview(labelChoice)
        addSubview(btnCheckBox)
        
        labelChoice.constrain([
            labelChoice.topAnchor.constraint(equalTo: topAnchor, constant: C.padding[2]),
            labelChoice.leadingAnchor.constraint(equalTo: leadingAnchor, constant: C.padding[1] + 5.0) ])
        
        btnCheckBox.constrain([
            btnCheckBox.centerYAnchor.constraint(equalTo: centerYAnchor),
            btnCheckBox.heightAnchor.constraint(equalToConstant: 30.0),
            btnCheckBox.widthAnchor.constraint(equalTo: btnCheckBox.heightAnchor),
            btnCheckBox.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -C.padding[2])])
        btnCheckBox.isToggleable = true
        
        if placeHolderString != nil {
            addSubview(textField)
            textField.addSubview(placeholder)
            textField.constrain([
                textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: C.padding[1]),
                textField.centerYAnchor.constraint(equalTo: labelChoice.centerYAnchor),
                textField.heightAnchor.constraint(greaterThanOrEqualToConstant: 30.0),
                textField.trailingAnchor.constraint(equalTo: btnCheckBox.leadingAnchor, constant: -C.padding[1]) ])
            
            placeholder.constrain([
                placeholder.centerYAnchor.constraint(equalTo: textField.centerYAnchor),
                placeholder.leadingAnchor.constraint(equalTo: textField.leadingAnchor, constant: 0.0) ])
        }
    }
    
    private func setInitialData() {
        textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        btnCheckBox.selectCallback = { isSelected in
            if self.placeHolderString != nil {
                if isSelected {
                    self.labelChoice.isHidden = true
                    self.textField.isHidden = false
                    self.placeholder.isHidden = false
                    self.textField.becomeFirstResponder()
                }
                else{
                    self.textField.isHidden = true
                    self.labelChoice.isHidden = false
                    self.placeholder.isHidden = true
                    self.textField.text = ""
                    self.textField.resignFirstResponder()
                }
            }
        }
        btnCheckBox.isSelected = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CheckBoxCell : UITextFieldDelegate {
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
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        didReturn?(textField)
    }
}
