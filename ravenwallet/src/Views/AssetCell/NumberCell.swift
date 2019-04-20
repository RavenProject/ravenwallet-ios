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

class NumberCell : UIViewController {
    
    
    init(placeholder: String, keyboardType: KeyboardType = .pinPad, maxDigits: Int = 0, numberDigit:NumberDigit = .many, isPinPadExpandedAtLaunch: Bool = false, isEnabled: Bool = true) {
        self.placeHolderString = placeholder
        self.placeholder.text = placeHolderString
        self.isPinPadExpandedAtLaunch = isPinPadExpandedAtLaunch
        self.keyboardType = keyboardType
        self.numberDigit = numberDigit
        self.isEnabled = isEnabled
        self.maxDigits = maxDigits
        super.init(nibName: nil, bundle: nil)
    }
    
    var didChangeFirstResponder: ((Bool) -> Void)?
    var didUpdateAmount: ((Satoshis?) -> Void)?
    var didReturn: (() -> Void)?
    /*var currentOutput: String {
     return amountLabel.text ?? ""
     }*/
    
    private let isPinPadExpandedAtLaunch: Bool
    var minimumFractionDigits = 0
    private var hasTrailingDecimal = false
    let placeHolderString: String
    let placeholder = UILabel(font: .customBody(size: 16.0), color: .grayTextTint)
    let textField = UITextField()
    let tapView = UIView()
    let border = UIView(color: .secondaryShadow)
    var isEnabled : Bool = true {
        didSet {
            tapView.isUserInteractionEnabled = isEnabled
            closePinPad()
        }
    }
    private let numberDigit:NumberDigit
    let keyboardType: KeyboardType
    private let maxDigits: Int

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
        view.addSubview(border)
        view.addSubview(textField)
        view.addSubview(tapView)
        textField.addSubview(placeholder)
    }
    
    func addConstraints() {
        textField.constrain([
            textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 11.0),
            textField.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textField.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            textField.heightAnchor.constraint(equalTo: view.heightAnchor)])
        placeholder.constrain([
            placeholder.centerYAnchor.constraint(equalTo: textField.centerYAnchor),
            placeholder.leadingAnchor.constraint(equalTo: textField.leadingAnchor, constant: 5.0) ])
        border.constrain([
            border.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            border.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            border.heightAnchor.constraint(equalToConstant: 1.0),
            border.topAnchor.constraint(equalTo: textField.bottomAnchor)])
        tapView.constrain([
            tapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tapView.topAnchor.constraint(equalTo: view.topAnchor),
            tapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tapView.bottomAnchor.constraint(equalTo: view.bottomAnchor) ])
    }
    
    func setInitialData() {
        textField.font = .customBody(size: 26.0)
        textField.textColor = .darkText
        textField.text = ""
        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        //KeyWordType
        switch keyboardType {
        case .decimalPad:
            textField.keyboardType = .decimalPad
        case .pinPad:
            textField.keyboardType = .numberPad
        case .unitsPad, .quantityPad:
            textField.keyboardType = .numberPad
        }
        //tapView
        let gr = UITapGestureRecognizer(target: self, action: #selector(didTap))
        tapView.addGestureRecognizer(gr)
        if isEnabled {
            tapView.isUserInteractionEnabled = true
        }
    }
    
    @objc private func didTap() {
        UIView.spring(C.animationDuration, animations: {
            if self.textField.isFirstResponder {
                self.textField.resignFirstResponder()
                self.togglePinPad(isCollapsed: false)
            }
            else {
                self.textField.becomeFirstResponder()
                self.togglePinPad(isCollapsed: true)
            }
            self.parent?.parent?.view.layoutIfNeeded()
        }, completion: { completed in })
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
        if let outputAmount = NumberFormatter().number(from: output)?.doubleValue {//BMEX TODO : need optimisation
            if(Double(outputAmount) > Double(C.maxMoney/C.oneAsset)){
                textField.removeLast()
                return
            }
            newAmount = Satoshis(value: outputAmount)
        }
        
        if let newAmount = newAmount {
            if newAmount > C.maxAsset {//never happend for units (.one)
                textField.removeLast()
            } else {
                amount = newAmount
            }
        } else {
            amount = nil
        }
    }
    
    func updateAmountLabel() {
        guard let amount = amount else {
            //textField.text = "";
            //pinPad.clear()
            //placeholder.isHidden = false
            return
        }
        placeholder.isHidden = true
        var output = amount.description(minimumFractionDigits: minimumFractionDigits)
        if hasTrailingDecimal {
            output = output.appending(NumberFormatter().currencyDecimalSeparator)
        }
        textField.text = output
    }
    
    func closePinPad() {
        textField.resignFirstResponder()
        didReturn?()
    }

    func togglePinPad(isCollapsed:Bool) {
        didChangeFirstResponder?(isCollapsed)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Keyboard delegate
    func textFieldDidBeginEditing(_ textField: UITextField) {
        togglePinPad(isCollapsed: true)
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        placeholder.isHidden = (textField.text?.utf8.count)! > 0
        if let text = textField.text {
            placeholder.isHidden = text.utf8.count > 0 ? true : false
            var newOutput = ""
            
            switch numberDigit {
            case .many:
                newOutput = textField.text!
            case .one:
                newOutput = text.utf8.count > 0 ? String(text.last!) : text
            }
            handleAmountUpdate(output: newOutput)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // when user taps Return, make the next text field first responder
        if makeTFFirstResponder(next: true) == false {
            // if it fails (last text field), submit the form
            submitForm()
        }
        
        return false
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        togglePinPad(isCollapsed: false)
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.isEmpty { return true }
        let currentText = textField.text ?? ""
        let replacementText = (currentText as NSString).replacingCharacters(in: range, with: string)
        return replacementText.isValidDouble(maxDecimalPlaces: maxDigits)
    }
}
