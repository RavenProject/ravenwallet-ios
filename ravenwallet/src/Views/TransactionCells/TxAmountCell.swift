//
//  TxAmountCell.swift
//  ravenwallet
//
//  Created by Ehsan Rezaie on 2017-12-21.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit

class TxAmountCell: UITableViewCell, Subscriber {
    
    // MARK: - Vars
    
    private let container = UIView()
    private lazy var tokenAmountLabel: UILabel = {
        let label = UILabel(font: UIFont.customBody(size: 26.0))
        label.textAlignment = .center
        return label
    }()
    private lazy var fiatAmountLabel: UILabel = {
        let label = UILabel(font: UIFont.customBody(size: 14.0))
        label.textAlignment = .center
        return label
    }()
    private let separator = UIView(color: .clear)
    private var fiatHeight: NSLayoutConstraint?

    // MARK: - Init
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    private func setupViews() {
        addSubviews()
        addConstraints()
    }
    
    private func addSubviews() {
        contentView.addSubview(container)
        contentView.addSubview(separator)
        container.addSubview(fiatAmountLabel)
        container.addSubview(tokenAmountLabel)
    }
    
    private func addConstraints() {
        container.constrain(toSuperviewEdges: UIEdgeInsets(top: C.padding[1],
                                                           left: C.padding[2],
                                                           bottom: -C.padding[2],
                                                           right: -C.padding[2]))
        tokenAmountLabel.constrain([
            tokenAmountLabel.constraint(.top, toView: container),
            tokenAmountLabel.constraint(.leading, toView: container),
            tokenAmountLabel.constraint(.trailing, toView: container)
            ])
        fiatHeight = fiatAmountLabel.heightAnchor.constraint(equalToConstant: 20.0)
        fiatAmountLabel.constrain([
            fiatAmountLabel.constraint(toBottom: tokenAmountLabel, constant: 0),
            fiatAmountLabel.constraint(.leading, toView: container),
            fiatAmountLabel.constraint(.trailing, toView: container),
            fiatAmountLabel.constraint(.bottom, toView: container),
            fiatHeight
            ])
        
        separator.constrainBottomCorners(height: 0.5)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(viewModel: TxDetailViewModel) {
        
        let largeFont = UIFont.customBody(size: 26.0)
        let smallFont = UIFont.customBody(size: 14.0)
        let fiatColor = UIColor.mediumGray
        let textColor = UIColor.lightGray
        let tokenColor: UIColor = (viewModel.direction == .received) ? .receivedGreen : .darkGray
        
        let amountText = NSMutableAttributedString(string: viewModel.amount,
                                                   attributes: [.font: largeFont,
                                                                .foregroundColor: tokenColor])
        tokenAmountLabel.attributedText = amountText
        
        // fiat amount label

        if let tx = viewModel.tx as? RvnTransaction {
            if AssetValidator.shared.checkInvalidAsset(asset: tx.asset) {
                fiatHeight?.constant = 0
            }
        }
        
        let currentAmount = viewModel.fiatAmount
        let originalAmount = viewModel.originalFiatAmount
        
        if viewModel.status != .complete || originalAmount == nil {
            fiatAmountLabel.attributedText = NSAttributedString(string: viewModel.fiatAmount,
                                                attributes: [.font: smallFont,
                                                             .foregroundColor: fiatColor])
        } else {
            let format = (viewModel.direction == .sent) ? S.TransactionDetails.amountWhenSent : S.TransactionDetails.amountWhenReceived
            
            let attributedText = NSMutableAttributedString(string: String(format: format, originalAmount!, currentAmount),
                                                           attributes: [.font: smallFont,
                                                                        .foregroundColor: textColor])
            
            attributedText.set(attributes: [.foregroundColor: fiatColor], forText: currentAmount)
            attributedText.set(attributes: [.foregroundColor: fiatColor], forText: originalAmount!)
            
            fiatAmountLabel.attributedText = attributedText
        }
    }
}
