//
//  AmountViewController.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2017-05-19.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit

class UnitsCell : NumberCell {
    
    
    init(placeholder: String, maxDigits: Int = 0, isPinPadExpandedAtLaunch: Bool = false, isEnabled: Bool = true) {
        super.init(placeholder: placeholder, keyboardType: .unitsPad, maxDigits: maxDigits, numberDigit: .one, isPinPadExpandedAtLaunch: isPinPadExpandedAtLaunch, isEnabled: isEnabled)
    }
    
    private let unitsLabel = UILabel.init(font: .customBody(size: 14.0), color: .grayTextTint)
    
    override var amount: Satoshis? {
        didSet {
            updateAmountLabel()
            didUpdateAmount?(amount)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func addSubviews() {
        super.addSubviews()
        view.addSubview(unitsLabel)
    }
    
    override func addConstraints() {
        super.addConstraints()
        unitsLabel.constrain([
            unitsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: C.padding[2]),
            unitsLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 0)])
        textField.constrain([
            textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: C.padding[2]),
            textField.topAnchor.constraint(equalTo: view.topAnchor, constant: C.padding[6]),
            textField.heightAnchor.constraint(equalTo: view.heightAnchor)])
    }
    
    override func setInitialData() {
        super.setInitialData()
        unitsLabel.text = placeHolderString
        amount = Satoshis(0)
    }
    
    override func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if (string == "9") {
            return false
        }
        return true
    }
}
