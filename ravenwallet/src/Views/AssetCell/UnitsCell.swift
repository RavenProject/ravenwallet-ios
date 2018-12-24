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
        amountLabel.constrain([
            amountLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: C.padding[2]),
            amountLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: C.padding[6]),
            amountLabel.heightAnchor.constraint(equalToConstant: 55.0)])
        placeHolderHeightAnchor?.constant = 0
    }
    
    override func setInitialData() {
        super.setInitialData()
        unitsLabel.text = placeHolderString
        amount = Satoshis(0)
    }
    
    
}
