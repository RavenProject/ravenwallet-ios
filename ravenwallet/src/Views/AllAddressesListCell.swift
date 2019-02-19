//
//  TxListCell.swift
//  ravenwallet
//
//  Created by Ehsan Rezaie on 2018-02-19.
//  Copyright © 2018 breadwallet LLC. All rights reserved.
//

import UIKit

class AllAddressesListCell: UITableViewCell {

    // MARK: - Views
    
    private let addressLabel = UILabel(font: .customBody(size: 16.0), color: .darkGray)
    private let separator = UIView(color: .separatorGray)
    // MARK: Vars
    
    private var address: String!
    
    // MARK: - Init
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    func setAddress(_ address: String) {
        self.address = address
        addressLabel.text = address
    }
    
    // MARK: - Private
    
    private func setupViews() {
        addSubviews()
        addConstraints()
        setupStyle()
    }
    
    private func addSubviews() {
        contentView.addSubview(addressLabel)
        contentView.addSubview(separator)
    }
    
    private func addConstraints() {
        addressLabel.constrain([
            addressLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            addressLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: C.padding[2])
            ])
        separator.constrainBottomCorners(height: 0.5)
    }
    
    private func setupStyle() {
        selectionStyle = .none
        addressLabel.setContentHuggingPriority(.required, for: .vertical)
        addressLabel.lineBreakMode = .byTruncatingTail
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
