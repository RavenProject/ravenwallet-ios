//
//  AddressCell.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2016-12-16.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit

class AddressCreateAssetCell : AddressCell {

    let generate = ShadowButton(title: S.Send.generateLabel, type: .secondary)
    
    override func addSubviews() {
        super.addSubviews()
        addSubview(generate)
    }

    override func addConstraints() {
        label.constrain([
            label.constraint(.top, toView: self, constant: C.padding[2]),
            label.constraint(.leading, toView: self, constant: C.padding[2]) ])
        contentLabel.constrain([
            contentLabel.constraint(.leading, toView: label),
            contentLabel.constraint(toBottom: label, constant: 0.0),
            contentLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -C.padding[1]) ])
        textField.constrain([
            textField.constraint(.leading, toView: label),
            textField.constraint(toBottom: label, constant: 0.0),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -C.padding[1]) ])
        tapView.constrain([
            tapView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tapView.topAnchor.constraint(equalTo: topAnchor),
            tapView.bottomAnchor.constraint(equalTo: bottomAnchor),
            tapView.trailingAnchor.constraint(equalTo: paste.leadingAnchor) ])
        scan.constrain([
            scan.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -C.padding[2]),
            scan.topAnchor.constraint(equalTo: label.bottomAnchor, constant: C.padding[3]) ])
        paste.constrain([
            paste.topAnchor.constraint(equalTo: scan.topAnchor),
            paste.trailingAnchor.constraint(equalTo: scan.leadingAnchor, constant: -C.padding[1]) ])
        addressBook.constrain([
            addressBook.trailingAnchor.constraint(equalTo: paste.leadingAnchor, constant: -C.padding[1]),
            addressBook.topAnchor.constraint(equalTo: scan.topAnchor),
            addressBook.widthAnchor.constraint(equalTo: scan.widthAnchor, multiplier: isAddressBookBtnHidden ? 0 : 1),
            addressBook.heightAnchor.constraint(equalTo: scan.heightAnchor)])
        generate.constrain([
            generate.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: C.padding[1]),
            generate.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 0.41),
            generate.trailingAnchor.constraint(equalTo: addressBook.leadingAnchor, constant: -C.padding[1]),
            generate.topAnchor.constraint(equalTo: scan.topAnchor),
            generate.heightAnchor.constraint(equalTo: addressBook.heightAnchor)])
        border.constrain([
            border.leadingAnchor.constraint(equalTo: leadingAnchor),
            border.bottomAnchor.constraint(equalTo: bottomAnchor),
            border.trailingAnchor.constraint(equalTo: trailingAnchor),
            border.heightAnchor.constraint(equalToConstant: 1.0) ])
        
        
    }
}
