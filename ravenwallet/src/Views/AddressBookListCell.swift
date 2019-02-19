//
//  TxListCell.swift
//  ravenwallet
//
//  Created by Ehsan Rezaie on 2018-02-19.
//  Copyright © 2018 breadwallet LLC. All rights reserved.
//

import UIKit
import SwipeCellKit

class AddressBookListCell: SwipeTableViewCell {

    // MARK: - Views
    
    private let ownerNameLabel = UILabel(font: .customBody(size: 16.0), color: .darkGray)
    private let addressLabel = UILabel(font: .customBody(size: 14.0), color: .lightGray)
    private let separator = UIView(color: .separatorGray)
    // MARK: Vars
    
    private var addressBook: AddressBook!
    
    // MARK: - Init
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    func setAddress(_ address: AddressBook) {
        self.addressBook = address
        ownerNameLabel.text = address.name
        addressLabel.text = address.address
    }
    
    // MARK: - Private
    
    private func setupViews() {
        addSubviews()
        addConstraints()
        setupStyle()
    }
    
    private func addSubviews() {
        contentView.addSubview(ownerNameLabel)
        contentView.addSubview(addressLabel)
        contentView.addSubview(separator)
    }
    
    private func addConstraints() {
        ownerNameLabel.constrain([
            ownerNameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: C.padding[2]),
            ownerNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: C.padding[2])
            ])
        
        addressLabel.constrain([
            addressLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -C.padding[2]),
            addressLabel.trailingAnchor.constraint(equalTo: ownerNameLabel.trailingAnchor),
            addressLabel.topAnchor.constraint(equalTo: ownerNameLabel.bottomAnchor),
            addressLabel.leadingAnchor.constraint(equalTo: ownerNameLabel.leadingAnchor)
            ])
        
        separator.constrainBottomCorners(height: 0.5)
    }
    
    private func setupStyle() {
        selectionStyle = .none
        ownerNameLabel.setContentHuggingPriority(.required, for: .vertical)
        addressLabel.lineBreakMode = .byTruncatingTail
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
