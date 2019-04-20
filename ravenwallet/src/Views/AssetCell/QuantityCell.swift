//
//  AmountViewController.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2017-05-19.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit

class QuantityCell : NumberCell {
    

    init(asset:Asset? = nil, placeholder: String, keyboardType: KeyboardType = .pinPad, maxDigits: Int = 0, isPinPadExpandedAtLaunch: Bool = false) {
        self.asset = asset
        super.init(placeholder: placeholder, keyboardType: keyboardType, maxDigits: maxDigits, numberDigit: .many, isPinPadExpandedAtLaunch: isPinPadExpandedAtLaunch)
    }
    
    override var amount: Satoshis? {
        didSet {
            updateAmountLabel()
            updateBalanceLabel()
            didUpdateAmount?(amount)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let balanceLabel = UILabel.init(font: .customBody(size: 14.0), color: .grayTextTint)

    private var asset:Asset? {
        didSet {
            let balance = balanceTextForQuantity()
            balanceLabel.attributedText = balance
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func addSubviews() {
        super.addSubviews()
        guard asset == nil else {
            view.addSubview(balanceLabel)
            balanceLabel.isHidden = true
            return
        }
    }

    override func addConstraints() {
        super.addConstraints()
        guard asset == nil else {
            balanceLabel.constrain([
                balanceLabel.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: -C.padding[2]),
                balanceLabel.leadingAnchor.constraint(equalTo: placeholder.leadingAnchor),
                balanceLabel.trailingAnchor.constraint(equalTo: textField.trailingAnchor)
                ])
            return
        }
    }
    
    override func togglePinPad(isCollapsed: Bool){
        super.togglePinPad(isCollapsed: isCollapsed)
        balanceLabel.isHidden = !isCollapsed
    }
    
    func updateBalanceLabel() {
        guard (asset != nil) else { return }
        let balance = balanceTextForQuantity()
        balanceLabel.attributedText = balance
    }
    
    private func balanceTextForQuantity() -> NSAttributedString? {
        let balanceOutput = String(format: S.Asset.balance, NumberFormatter.formattedString(value: (self.asset?.amount.doubleValue)!, minimumFractionDigits: 0, maxDigits: Int((self.asset?.units)!)), (asset?.name)!)
        var color: UIColor = .grayTextTint
        if let amount = amount, amount.rawValue > 0 {
            if ((asset?.amount.rawValue)! < amount.rawValue) {
                color = .cameraGuideNegative
            }
        }
        
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.font: UIFont.customBody(size: 14.0),
            NSAttributedString.Key.foregroundColor: color
        ]
        
        return (NSAttributedString(string: balanceOutput, attributes: attributes))
    }
}
