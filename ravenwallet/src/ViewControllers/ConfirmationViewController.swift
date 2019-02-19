//
//  ConfirmationViewController.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2017-07-28.
//  Copyright © 2018 a Team. All rights reserved.
//

import UIKit
import LocalAuthentication

class ConfirmationViewController : UIViewController, ContentBoxPresenter {

    init(amount: Satoshis, fee: Satoshis, feeType: Fee, selectedRate: Rate?, minimumFractionDigits: Int?, address: String, isUsingBiometrics: Bool, operationType: OperationType? = OperationType.transferRvn, assetToSend:Asset? = nil) {
        self.amount = amount
        self.feeAmount = fee
        self.feeType = feeType
        self.selectedRate = selectedRate
        self.minimumFractionDigits = minimumFractionDigits
        self.addressText = address
        self.isUsingBiometrics = isUsingBiometrics
        self.asset = assetToSend
        self.operationType = operationType!
        super.init(nibName: nil, bundle: nil)
    }

    private let amount: Satoshis
    private let feeAmount: Satoshis
    private let feeType: Fee
    private let selectedRate: Rate?
    private let minimumFractionDigits: Int?
    private let addressText: String
    private let isUsingBiometrics: Bool
    private var asset: Asset?
    private let operationType: OperationType


    //ContentBoxPresenter
    let contentBox = UIView(color: .white)
    let blurView = UIVisualEffectView()
    let effect = UIBlurEffect(style: .dark)

    var successCallback: (() -> Void)?
    var cancelCallback: (() -> Void)?

    private let header = ModalHeaderView(title: S.Confirmation.title, style: .dark)
    private let cancel = ShadowButton(title: S.Button.cancel, type: .secondary)
    private let sendButton = ShadowButton(title: S.Confirmation.send, type: .primary, image: (LAContext.biometricType() == .face ? #imageLiteral(resourceName: "FaceId") : #imageLiteral(resourceName: "TouchId")))

    private let payLabel = UILabel(font: .customBody(size: 14.0), color: .grayTextTint)
    private let toLabel = UILabel(font: .customBody(size: 14.0), color: .grayTextTint)
    private let amountLabel = UILabel(font: .customBody(size: 16.0), color: .darkText)
    private let address = UILabel(font: .customBody(size: 16.0), color: .darkText)

    private let processingTime = UILabel.wrapping(font: .customBody(size: 14.0), color: .grayTextTint)
    private let sendLabel = UILabel(font: .customBody(size: 14.0), color: .darkText)
    private let feeLabel = UILabel(font: .customBody(size: 14.0), color: .darkText)
    private let operationAssetFeeLabel = UILabel(font: .customBody(size: 14.0), color: .darkText)
    private var operationAssetFeeHeight: NSLayoutConstraint?
    private let totalLabel = UILabel(font: .customMedium(size: 14.0), color: .darkText)

    private let send = UILabel(font: .customBody(size: 14.0), color: .darkText)
    private let fee = UILabel(font: .customBody(size: 14.0), color: .darkText)
    private let operationAssetFee = UILabel(font: .customBody(size: 14.0), color: .darkText)
    private let total = UILabel(font: .customMedium(size: 14.0), color: .darkText)

    override func viewDidLoad() {
        addSubviews()
        addConstraints()
        setInitialData()
    }

    private func addSubviews() {
        view.addSubview(contentBox)
        contentBox.addSubview(header)
        contentBox.addSubview(payLabel)
        contentBox.addSubview(toLabel)
        contentBox.addSubview(amountLabel)
        contentBox.addSubview(address)
        contentBox.addSubview(processingTime)
        contentBox.addSubview(sendLabel)
        contentBox.addSubview(feeLabel)
        contentBox.addSubview(operationAssetFeeLabel)
        contentBox.addSubview(totalLabel)
        contentBox.addSubview(send)
        contentBox.addSubview(fee)
        contentBox.addSubview(operationAssetFee)
        contentBox.addSubview(total)
        contentBox.addSubview(cancel)
        contentBox.addSubview(sendButton)
    }

    private func addConstraints() {
        contentBox.constrain([
            contentBox.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentBox.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            contentBox.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -C.padding[6] ) ])
        header.constrainTopCorners(height: 49.0)
        payLabel.constrain([
            payLabel.leadingAnchor.constraint(equalTo: contentBox.leadingAnchor, constant: C.padding[2]),
            payLabel.topAnchor.constraint(equalTo: header.bottomAnchor, constant: C.padding[2]) ])
        amountLabel.constrain([
            amountLabel.leadingAnchor.constraint(equalTo: payLabel.leadingAnchor),
            amountLabel.topAnchor.constraint(equalTo: payLabel.bottomAnchor)])
        toLabel.constrain([
            toLabel.leadingAnchor.constraint(equalTo: amountLabel.leadingAnchor),
            toLabel.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: C.padding[2]) ])
        address.constrain([
            address.leadingAnchor.constraint(equalTo: toLabel.leadingAnchor),
            address.topAnchor.constraint(equalTo: toLabel.bottomAnchor),
            address.trailingAnchor.constraint(equalTo: contentBox.trailingAnchor, constant: -C.padding[2]) ])
        processingTime.constrain([
            processingTime.leadingAnchor.constraint(equalTo: address.leadingAnchor),
            processingTime.topAnchor.constraint(equalTo: address.bottomAnchor, constant: C.padding[2]),
            processingTime.trailingAnchor.constraint(equalTo: contentBox.trailingAnchor, constant: -C.padding[2]) ])
        sendLabel.constrain([
            sendLabel.leadingAnchor.constraint(equalTo: processingTime.leadingAnchor),
            sendLabel.topAnchor.constraint(equalTo: processingTime.bottomAnchor, constant: C.padding[2]),
            sendLabel.trailingAnchor.constraint(lessThanOrEqualTo: send.leadingAnchor) ])
        send.constrain([
            send.trailingAnchor.constraint(equalTo: contentBox.trailingAnchor, constant: -C.padding[2]),
            sendLabel.firstBaselineAnchor.constraint(equalTo: send.firstBaselineAnchor) ])
        feeLabel.constrain([
            feeLabel.leadingAnchor.constraint(equalTo: sendLabel.leadingAnchor),
            feeLabel.topAnchor.constraint(equalTo: sendLabel.bottomAnchor) ])
        fee.constrain([
            fee.trailingAnchor.constraint(equalTo: contentBox.trailingAnchor, constant: -C.padding[2]),
            fee.firstBaselineAnchor.constraint(equalTo: feeLabel.firstBaselineAnchor) ])
        operationAssetFeeHeight = operationAssetFeeLabel.heightAnchor.constraint(equalToConstant: 0.0)
        operationAssetFeeLabel.constrain([
            operationAssetFeeLabel.leadingAnchor.constraint(equalTo: feeLabel.leadingAnchor),
            operationAssetFeeLabel.topAnchor.constraint(equalTo: feeLabel.bottomAnchor),
            operationAssetFeeHeight])
        operationAssetFee.constrain([
            operationAssetFee.trailingAnchor.constraint(equalTo: contentBox.trailingAnchor, constant: -C.padding[2]),
            operationAssetFee.firstBaselineAnchor.constraint(equalTo: operationAssetFeeLabel.firstBaselineAnchor),
            operationAssetFeeHeight])
        totalLabel.constrain([
            totalLabel.leadingAnchor.constraint(equalTo: feeLabel.leadingAnchor),
            totalLabel.topAnchor.constraint(equalTo: operationAssetFeeLabel.bottomAnchor) ])
        total.constrain([
            total.trailingAnchor.constraint(equalTo: contentBox.trailingAnchor, constant: -C.padding[2]),
            total.firstBaselineAnchor.constraint(equalTo: totalLabel.firstBaselineAnchor) ])
        cancel.constrain([
            cancel.leadingAnchor.constraint(equalTo: contentBox.leadingAnchor, constant: C.padding[2]),
            cancel.topAnchor.constraint(equalTo: totalLabel.bottomAnchor, constant: C.padding[2]),
            cancel.trailingAnchor.constraint(equalTo: contentBox.centerXAnchor, constant: -C.padding[1]),
            cancel.bottomAnchor.constraint(equalTo: contentBox.bottomAnchor, constant: -C.padding[2]) ])
        sendButton.constrain([
            sendButton.leadingAnchor.constraint(equalTo: contentBox.centerXAnchor, constant: C.padding[1]),
            sendButton.topAnchor.constraint(equalTo: totalLabel.bottomAnchor, constant: C.padding[2]),
            sendButton.trailingAnchor.constraint(equalTo: contentBox.trailingAnchor, constant: -C.padding[2]),
            sendButton.bottomAnchor.constraint(equalTo: contentBox.bottomAnchor, constant: -C.padding[2]) ])
    }

    private func setInitialData() {
        view.backgroundColor = .clear

        var assetFee = Satoshis.zero
        switch operationType {
        case .createAsset:
            assetFee = Satoshis(C.creatAssetFee)
            operationAssetFeeLabel.text = S.Confirmation.createFeeLabel
            sendLabel.text = S.Confirmation.amountCreateLabel
            payLabel.text = S.Asset.create
        case .manageAsset:
            assetFee = Satoshis(C.manageAssetFee)
            operationAssetFeeLabel.text = S.Confirmation.manageFeeLabel
            sendLabel.text = S.Confirmation.amountManageLabel
            payLabel.text = S.Asset.manageTitle
        case .subAsset:
            assetFee = Satoshis(C.subAssetFee)
            operationAssetFeeLabel.text = S.Confirmation.subAssetFeeLabel
            sendLabel.text = S.Confirmation.amountCreateLabel
            payLabel.text = S.Asset.create
        case .uniqueAsset:
            assetFee = Satoshis(C.uniqueAssetFee)
            operationAssetFeeLabel.text = S.Confirmation.uniqueAssetFeeLabel
            sendLabel.text = S.Confirmation.amountCreateLabel
            payLabel.text = S.Asset.create
        default:
            assetFee = Satoshis.zero
            sendLabel.text = S.Confirmation.amountSendLabel
            payLabel.text = S.Confirmation.send
        }
        let displayAssetFee = DisplayAmount(amount: assetFee, selectedRate: selectedRate, minimumFractionDigits: minimumFractionDigits, currency: Currencies.rvn)
        var totalFee = amount + feeAmount
        if operationType != .transferRvn {
            totalFee = assetFee + feeAmount
        }
        let displayAmount = DisplayAmount(amount: amount, selectedRate: selectedRate, minimumFractionDigits: minimumFractionDigits, currency: Currencies.rvn)
        let displayFee = DisplayAmount(amount: feeAmount, selectedRate: selectedRate, minimumFractionDigits: minimumFractionDigits, currency: Currencies.rvn)
        let displayTotal = DisplayAmount(amount: totalFee, selectedRate: selectedRate, minimumFractionDigits: minimumFractionDigits, currency: Currencies.rvn)

        amountLabel.text = operationType == .transferRvn ? displayAmount.combinedDescription : amount.description(minimumFractionDigits: minimumFractionDigits!) + " " + asset!.name

        toLabel.text = S.Confirmation.to
        address.text = addressText
        address.lineBreakMode = .byTruncatingMiddle
        switch feeType {
        case .regular:
            processingTime.text = String(format: S.Confirmation.processingTime, S.FeeSelector.regularTime)
        case .economy:
            processingTime.text = String(format: S.Confirmation.processingTime, S.FeeSelector.economyTime)
        }


        sendLabel.adjustsFontSizeToFitWidth = true
        send.text = asset == nil ? displayAmount.description : amount.description(minimumFractionDigits: minimumFractionDigits!) + " " + asset!.name
        feeLabel.text = S.Confirmation.feeLabel
        fee.text = displayFee.description
        
        operationAssetFee.text = displayAssetFee.description
        switch operationType {
        case .createAsset, .manageAsset, .subAsset, .uniqueAsset :
            operationAssetFeeHeight?.constant = 20
            operationAssetFee.isHidden = false //BMEX Todo : should work only with autolayout
        default:
            operationAssetFeeHeight?.constant = 0
            operationAssetFee.isHidden = true
        }
        self.view.layoutIfNeeded()

        totalLabel.text = S.Confirmation.totalLabel
        total.text = displayTotal.description
        if operationType == .transferAsset {
            totalLabel.isHidden = true
            total.isHidden = true
        }

        cancel.tap = strongify(self) { myself in
            myself.cancelCallback?()
        }
        header.closeCallback = strongify(self) { myself in
            myself.cancelCallback?()
        }
        sendButton.tap = strongify(self) { myself in
            myself.successCallback?()
        }

        contentBox.layer.cornerRadius = 6.0
        contentBox.layer.masksToBounds = true

        if !isUsingBiometrics {
            sendButton.image = nil
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
