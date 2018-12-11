//
//  AmountViewController.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2017-05-19.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit

enum NumberDigit {
    case many
    case one
}

class NumberCell : UIViewController, Trackable {
    

    init(placeholder: String, keyboardType: KeyboardType = .pinPad, maxDigits: Int = 0, numberDigit:NumberDigit = .many, isPinPadExpandedAtLaunch: Bool = false, isEnabled: Bool = true) {
        self.placeHolderString = placeholder
        self.placeholder.text = placeHolderString
        self.isPinPadExpandedAtLaunch = isPinPadExpandedAtLaunch
        self.pinPad = PinPadViewController(style: .white, keyboardType: keyboardType, maxDigits: maxDigits)
        self.numberDigit = numberDigit
        self.isEnabled = isEnabled
        super.init(nibName: nil, bundle: nil)
    }

    var didChangeFirstResponder: ((Bool) -> Void)?

    /*var currentOutput: String {
        return amountLabel.text ?? ""
    }*/

    func expandPinPad() {
        if pinPadHeight?.constant == 0.0 {
            togglePinPad()
        }
    }

    private let isPinPadExpandedAtLaunch: Bool
    var minimumFractionDigits = 0
    private var hasTrailingDecimal = false
    var pinPadHeight: NSLayoutConstraint?
    var borderTopAnchor: NSLayoutConstraint?
    var bottomBorderTopAnchor: NSLayoutConstraint?
    var placeHolderHeightAnchor: NSLayoutConstraint?
    let placeHolderString: String
    let placeholder = UILabel(font: .customBody(size: 16.0), color: .grayTextTint)
    let amountLabel = UILabel(font: .customBody(size: 26.0), color: .darkText)
    let pinPad: PinPadViewController
    let border = UIView(color: .secondaryShadow)
    let bottomBorder = UIView(color: .secondaryShadow)
    var isEnabled : Bool = true
    private let tapView = UIView()
    private let numberDigit:NumberDigit
    
    var amount: Satoshis? {
        didSet {
            updateAmountLabel()
        }
    }

    override func viewDidLoad() {
        addSubviews()
        addConstraints()
        setInitialData()
    }

    func addSubviews() {
        view.addSubview(amountLabel)
        view.addSubview(placeholder)
        view.addSubview(border)
        view.addSubview(tapView)
        view.addSubview(bottomBorder)
    }

    func addConstraints() {
        amountLabel.constrain([
            amountLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: C.padding[2]),
            amountLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            amountLabel.heightAnchor.constraint(equalToConstant: 55.0)])
        placeHolderHeightAnchor = placeholder.heightAnchor.constraint(equalToConstant: 55.0)
        placeholder.constrain([
            placeholder.leadingAnchor.constraint(equalTo: amountLabel.leadingAnchor, constant: 2.0),
            placeholder.centerYAnchor.constraint(equalTo: amountLabel.centerYAnchor),
            placeHolderHeightAnchor])
        borderTopAnchor = border.topAnchor.constraint(equalTo: amountLabel.bottomAnchor)
        border.constrain([
            border.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            border.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            border.heightAnchor.constraint(equalToConstant: 1.0),
            borderTopAnchor])
        pinPadHeight = pinPad.view.heightAnchor.constraint(equalToConstant: 0.0)
        addChild(pinPad, layout: {
            pinPad.view.constrain([
                pinPad.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                pinPad.view.topAnchor.constraint(equalTo: border.bottomAnchor),
                pinPad.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                pinPad.view.bottomAnchor.constraint(equalTo: bottomBorder.topAnchor),
                pinPadHeight ])
        })
        bottomBorderTopAnchor = bottomBorder.topAnchor.constraint(greaterThanOrEqualTo: amountLabel.bottomAnchor, constant: 0)
        bottomBorder.constrain([
            bottomBorder.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBorder.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomBorder.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBorder.heightAnchor.constraint(equalToConstant: 1.0),
            bottomBorderTopAnchor])

        tapView.constrain([
            tapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tapView.topAnchor.constraint(equalTo: view.topAnchor),
            tapView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 4.0),
            tapView.bottomAnchor.constraint(equalTo: amountLabel.bottomAnchor) ])
        preventAmountOverflow()
    }

    func setInitialData() {
        amountLabel.text = ""
        bottomBorder.isHidden = true
        pinPad.ouputDidUpdate = { [weak self] output in
            self?.handlePinPadUpdate(output: output)
        }
        if isEnabled {
            let gr = UITapGestureRecognizer(target: self, action: #selector(didTap))
            tapView.addGestureRecognizer(gr)
            tapView.isUserInteractionEnabled = true
            
            if isPinPadExpandedAtLaunch {
                didTap()
            }
        }

    }

    private func preventAmountOverflow() {
        amountLabel.constrain([
            amountLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -C.padding[2]) ])
        amountLabel.minimumScaleFactor = 0.5
        amountLabel.adjustsFontSizeToFitWidth = true
        amountLabel.setContentCompressionResistancePriority(UILayoutPriority.defaultLow, for: .horizontal)
    }

    private func handlePinPadUpdate(output: String) {
        placeholder.isHidden = output.utf8.count > 0 ? true : false
        var newOutput = ""
        
        switch numberDigit {
        case .many:
            newOutput = output
        case .one:
            newOutput = output.utf8.count > 0 ? String(output.last!) : output
            pinPad.currentOutput = ""
        }
        handleAmountUpdate(output: newOutput)
    }
    
    func handleAmountUpdate(output: String) {
        let currencyDecimalSeparator = NumberFormatter().currencyDecimalSeparator ?? "."
        //If trailing decimal, append the decimal to the output
        hasTrailingDecimal = false //set default
        if let decimalLocation = output.range(of: currencyDecimalSeparator)?.upperBound {
            if output.endIndex == decimalLocation {
                hasTrailingDecimal = true
            }
        }
        
        minimumFractionDigits = 0 //set default
        if let decimalLocation = output.range(of: currencyDecimalSeparator)?.upperBound {
            let locationValue = output.distance(from: output.endIndex, to: decimalLocation)
            minimumFractionDigits = abs(locationValue)
        }

        
        var newAmount: Satoshis?
        if let outputAmount = NumberFormatter().number(from: output)?.doubleValue {
            newAmount = Satoshis(value: outputAmount)
        }
        
        if let newAmount = newAmount {
            if newAmount > C.maxAsset {//never happend for units (.one)
                pinPad.removeLast()
            } else {
                amount = newAmount
            }
        } else {
            amount = nil
        }
    }
    
    func updateAmountLabel() {
        guard let amount = amount else { amountLabel.text = ""; return }
        var output = amount.description(minimumFractionDigits: minimumFractionDigits)
        if hasTrailingDecimal {
            output = output.appending(NumberFormatter().currencyDecimalSeparator)
        }
        amountLabel.text = output
    }

    @objc private func didTap() {
        UIView.spring(C.animationDuration, animations: {
            self.togglePinPad()
            self.parent?.parent?.view.layoutIfNeeded()
        }, completion: { completed in })
    }

    func closePinPad() {
        pinPadHeight?.constant = 0.0
        bottomBorder.isHidden = true
    }

    func togglePinPad() {
        let isCollapsed: Bool = pinPadHeight?.constant == 0.0
        pinPadHeight?.constant = isCollapsed ? pinPad.height : 0.0
        bottomBorder.isHidden = isCollapsed ? false : true
        didChangeFirstResponder?(isCollapsed)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
