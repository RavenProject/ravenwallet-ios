//
//  DescriptionSendCell.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2016-12-16.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit

class IPFSCell : SendCell {

    init(labelCheckBox: String ,placeholder: String) {
        super.init()
        self.labelChoice.text = labelCheckBox
        self.label.text = placeholder
        setupViews()
        setInitialData()
    }

    let labelChoice = UILabel(font: .customBody(size: 16.0), color: .grayTextTint)
    let btnCheckBox = ShadowButton(type: .checkBox, image: #imageLiteral(resourceName: "CircleUnCheckSolid"), selectedImage: #imageLiteral(resourceName: "CircleCheckSolid"))
    let label = UILabel(font: .customBody(size: 16.0), color: .grayTextTint)
    let textField = UITextField()
    let paste = ShadowButton(title: S.Send.pasteLabel, type: .secondary)
    let scan = ShadowButton(title: S.Send.scanLabel, type: .secondary)
    var hasIpfs = false
    var ipfsHash: String? {
        return textField.text
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


    private func setupViews() {
        addSubview(labelChoice)
        addSubview(btnCheckBox)
        addSubview(label)
        addSubview(textField)
        addSubview(paste)
        addSubview(scan)
        
        labelChoice.constrain([
            labelChoice.centerYAnchor.constraint(equalTo: centerYAnchor),
            labelChoice.topAnchor.constraint(equalTo: topAnchor, constant: C.padding[2]),
            labelChoice.leadingAnchor.constraint(equalTo: leadingAnchor, constant: C.padding[1] + 5.0) ])
        btnCheckBox.constrain([
            btnCheckBox.centerYAnchor.constraint(equalTo: centerYAnchor),
            btnCheckBox.heightAnchor.constraint(equalToConstant: 30.0),
            btnCheckBox.widthAnchor.constraint(equalTo: btnCheckBox.heightAnchor),
            btnCheckBox.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -C.padding[2])])
        btnCheckBox.isToggleable = true
        label.constrain([
            label.topAnchor.constraint(equalTo: topAnchor, constant: C.padding[2]),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: C.padding[1] + 5.0) ])
        textField.constrain([
            textField.constraint(.leading, toView: label),
            textField.constraint(toBottom: label, constant: 0.0),
            textField.trailingAnchor.constraint(equalTo: paste.leadingAnchor, constant: -C.padding[1]) ])
        scan.constrain([
            scan.trailingAnchor.constraint(equalTo: btnCheckBox.leadingAnchor, constant: -C.padding[1]),
            scan.centerYAnchor.constraint(equalTo: centerYAnchor) ])
        paste.constrain([
            paste.centerYAnchor.constraint(equalTo: centerYAnchor),
            paste.trailingAnchor.constraint(equalTo: scan.leadingAnchor, constant: -C.padding[1]) ])
    }
    
    private func setInitialData() {
        self.label.isHidden = true
        self.paste.isHidden = true
        self.scan.isHidden = true
        textField.font = .customBody(size: 14.0)
        textField.textColor = .darkText
        textField.returnKeyType = .done
        textField.delegate = self
        textField.clearButtonMode = .whileEditing
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.keyboardType = .asciiCapable
        textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        btnCheckBox.selectCallback = { isSelected in
            if isSelected {
                self.hasIpfs = true
                self.labelChoice.isHidden = true
                self.textField.isHidden = false
                self.label.isHidden = false
                self.paste.isHidden = false
                self.scan.isHidden = false
                self.textField.becomeFirstResponder()
            }
            else{
                self.hasIpfs = false
                self.textField.isHidden = true
                self.paste.isHidden = true
                self.scan.isHidden = true
                self.labelChoice.isHidden = false
                self.label.isHidden = true
                self.textField.text = ""
                self.textField.resignFirstResponder()
            }
        }
        self.btnCheckBox.isSelected = false

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension IPFSCell : UITextFieldDelegate {
    
    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        // set the tool bar as this text field's input accessory view
        textField.inputAccessoryView = tbKeyboard
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        didBeginEditing?()
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
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
