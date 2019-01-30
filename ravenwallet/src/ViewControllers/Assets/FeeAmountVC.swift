//
//  AmountViewController.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2017-05-19.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit

enum OperationType {
    case transferRvn
    case createAsset
    case subAsset
    case uniqueAsset
    case manageAsset
    case transferAsset
    case transferOwnerShipAsset
    case burnAsset
}


class FeeAmountVC : UIViewController, Trackable, Subscriber {
    
    private let currency: CurrencyDef = Currencies.rvn

    init(walletManager: WalletManager, sender:SenderAsset, operationType: OperationType) {
        self.feeSelector = FeeSelector()
        self.sender = sender
        self.operationType = operationType
        self.walletManager = walletManager
        super.init(nibName: nil, bundle: nil)
    }
    
    var didUpdateFee: ((Fee) -> Void)? {
        didSet {
            feeSelector.didUpdateFee = didUpdateFee
        }
    }
    var didUpdateAssetFee: ((UInt64) -> Void)?

    
    var canEditFee: Bool = true
    private let walletManager: WalletManager
    var minimumFractionDigits = 0
    private let sender: SenderAsset
    private let operationType: OperationType
    private var hasTrailingDecimal = false
    private var feeSelectorHeight: NSLayoutConstraint?
    private var feeSelectorTop: NSLayoutConstraint?
    private let border = UIView(color: .secondaryShadow)
    private let balanceLabel = UILabel()
    private let assetFeeLabel = UILabel()
    private let feeLabel = UILabel()
    private let feeContainer = InViewAlert(type: .secondary)
    private let editFee = UIButton(type: .system)
    private let feeSelector: FeeSelector
    private var feeType: Fee?
    private var assetFeeHeight: NSLayoutConstraint?
    var balance: UInt64 = 0 {
        didSet{
            updateBalanceAndFeeLabels()
        }
    }


    override func viewDidLoad() {
        addSubviews()
        addConstraints()
        addSubsriptions()
        setInitialData()
        addButtonActions()
    }

    private func addSubviews() {
        view.addSubview(feeContainer)
        view.addSubview(border)
        view.addSubview(balanceLabel)
        view.addSubview(assetFeeLabel)
        view.addSubview(feeLabel)
        view.addSubview(editFee)
    }

    private func addConstraints() {
        feeSelectorHeight = feeContainer.heightAnchor.constraint(equalToConstant: 0.0)
        feeSelectorTop = feeContainer.topAnchor.constraint(equalTo: assetFeeLabel.bottomAnchor, constant: C.padding[1])

        feeContainer.constrain([
            feeSelectorTop,
            feeSelectorHeight,
            feeContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            feeContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            feeContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor) ])
        feeContainer.arrowXLocation = C.padding[4]
        border.constrain([
            border.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            border.topAnchor.constraint(equalTo: feeContainer.bottomAnchor),
            border.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            border.heightAnchor.constraint(equalToConstant: 1.0) ])
        balanceLabel.constrain([
            balanceLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: C.padding[2]),
            balanceLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: C.padding[1]) ])
        feeLabel.constrain([
            feeLabel.leadingAnchor.constraint(equalTo: balanceLabel.leadingAnchor),
            feeLabel.topAnchor.constraint(equalTo: balanceLabel.bottomAnchor),
            feeLabel.trailingAnchor.constraint(equalTo: editFee.leadingAnchor, constant: C.padding[1]) ])
        editFee.constrain([
            editFee.centerYAnchor.constraint(equalTo: feeLabel.centerYAnchor, constant: -1.0),
            editFee.widthAnchor.constraint(equalToConstant: 44.0),
            editFee.heightAnchor.constraint(equalToConstant: 44.0) ])
        assetFeeHeight = assetFeeLabel.heightAnchor.constraint(equalToConstant: 0.0)
        assetFeeLabel.constrain([
            assetFeeLabel.leadingAnchor.constraint(equalTo: balanceLabel.leadingAnchor),
            assetFeeLabel.topAnchor.constraint(equalTo: feeLabel.bottomAnchor),
            assetFeeHeight])
    }

    private func setInitialData() {
        feeContainer.contentView = feeSelector
        editFee.tap = { [weak self] in
            self?.toggleFeeSelector()
        }
        editFee.setImage(#imageLiteral(resourceName: "Edit"), for: .normal)
        editFee.imageEdgeInsets = UIEdgeInsets(top: 15.0, left: 15.0, bottom: 15.0, right: 15.0)
        editFee.tintColor = .grayTextTint
        editFee.isHidden = false
        feeLabel.numberOfLines = 0
        feeLabel.lineBreakMode = .byWordWrapping
        switch operationType {
        case .createAsset, .manageAsset, .subAsset, .uniqueAsset :
            assetFeeHeight?.constant = 15
        default:
            assetFeeHeight?.constant = 0
        }
        self.view.layoutIfNeeded()
        self.parent?.view?.layoutIfNeeded()
        self.parent?.parent?.view?.layoutIfNeeded()
    }
    
    func addSubsriptions() {
        Store.subscribe(self, selector: { $0[self.currency].balance != $1[self.currency].balance },
                        callback: { [unowned self] in
                            if let balance = $0[self.currency].balance {
                                self.balance = balance
                            }
        })
        Store.subscribe(self, selector: { $0[self.currency].fees != $1[self.currency].fees }, callback: { [unowned self] in
            if let fees = $0[self.currency].fees {
                self.canEditFee = (fees.regular != fees.economy) || self.currency.matches(Currencies.rvn)
                if let feeType = self.feeType {
                    switch feeType {
                    case .regular :
                        self.walletManager.wallet?.feePerKb = fees.regular
                    case .economy:
                        self.walletManager.wallet?.feePerKb = fees.economy
                    }
                } else {
                    self.walletManager.wallet?.feePerKb = fees.regular
                }
            }
        })
    }
    
    private func addButtonActions() {
        didUpdateFee = strongify(self) { myself, fee in
            guard let wallet = myself.walletManager.wallet else { return }
            myself.feeType = fee
            if let fees = self.currency.state.fees {
                switch fee {
                case .regular:
                    wallet.feePerKb = fees.regular
                case .economy:
                    wallet.feePerKb = fees.economy
                }
            }
            myself.updateBalanceAndFeeLabels()
        }
    }

    private func toggleFeeSelector() {
        guard let height = feeSelectorHeight else { return }
        let isCollapsed: Bool = height.isActive
        UIView.spring(C.animationDuration, animations: {
            if isCollapsed {
                NSLayoutConstraint.deactivate([height])
                self.feeSelector.addIntrinsicSize()
            } else {
                self.feeSelector.removeIntrinsicSize()
                NSLayoutConstraint.activate([height])
            }
            self.view.layoutIfNeeded()
            self.parent?.view?.layoutIfNeeded()
            self.parent?.parent?.view?.layoutIfNeeded()
        }, completion: {_ in })
    }

    private func updateBalanceAndFeeLabels() {
        let (balance, fee, assetFee) = balanceTextForAmount()
        balanceLabel.attributedText = balance
        feeLabel.attributedText = fee
        assetFeeLabel.attributedText = assetFee
    }
    
    private func balanceTextForAmount() -> (NSAttributedString?, NSAttributedString?, NSAttributedString?){
        let balanceAmount = DisplayAmount(amount: Satoshis(rawValue: balance), selectedRate: nil, minimumFractionDigits: 0, currency: currency)
        let balanceText = balanceAmount.description
        let balanceOutput = String(format: S.Send.balance, balanceText)
        var feeOutput = S.Send.feeLabel
        var assetFeeAmount = UInt64(0)
        var assetFeeText = "%@" //not used for transfer type
        switch operationType {
        case .createAsset:
            assetFeeText = S.Asset.creationAssetFee
            assetFeeAmount = C.creatAssetFee
        case .manageAsset:
            assetFeeText = S.Asset.manageAssetFee
            assetFeeAmount = C.manageAssetFee
        case .subAsset:
            assetFeeText = S.Asset.subAssetFee
            assetFeeAmount = C.subAssetFee
        case .uniqueAsset:
            assetFeeText = S.Asset.uniqueAssetFee
            assetFeeAmount = C.uniqueAssetFee
        default:
            break
        }
        let desplayAssetFeeAmount = DisplayAmount(amount: Satoshis(rawValue: assetFeeAmount), selectedRate: nil, minimumFractionDigits: 8, currency: currency)
        let assetFeeOutput = String(format: assetFeeText, desplayAssetFeeAmount.description)
        var color: UIColor = .grayTextTint
        if let fee = sender.feeForTx(amount: UInt64(100000000)) {
            let feeAmount = DisplayAmount(amount: Satoshis(rawValue: fee), selectedRate: nil, minimumFractionDigits: 0, currency: currency)
            let feeText = feeAmount.description
            feeOutput = String(format: S.Send.fee, feeText)
            if(self.didUpdateAssetFee != nil){
                self.didUpdateAssetFee!(fee + assetFeeAmount)
            }
            if (balance <= (fee + assetFeeAmount)) {
                color = .cameraGuideNegative
            }
        }
        else {
            if(self.didUpdateAssetFee != nil){
                self.didUpdateAssetFee!(1)//fix fee to 1 if nill to block transaction
            }
            feeOutput = S.Send.nilFeeError
        }
        
        
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.font: UIFont.customBody(size: 14.0),
            NSAttributedString.Key.foregroundColor: color
        ]
        
        return (NSAttributedString(string: balanceOutput, attributes: attributes), NSAttributedString(string: feeOutput, attributes: attributes), NSAttributedString(string: assetFeeOutput, attributes: attributes))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
