//
//  SecurityCenterCell.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2017-02-15.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit

private let buttonSize: CGFloat = 30.0

class TermsUseCell : UIControl {

    init(descriptionText: String) {
        super.init(frame: .zero)
        descriptionLabel.text = descriptionText
        setup()
    }
    
    let descriptionLabel = UILabel(font: .customBody(size: 16.0), color : .lightGray)
    let check = UIButton(type: .system)
    var selectCallback: ((Bool) -> Void)?
    
    override var isSelected: Bool {
        didSet {
            check.isSelected = isSelected
            check.tintColor = isSelected ? .white : .lightGray
            descriptionLabel.textColor = isSelected ? .white : .lightGray
            if selectCallback != nil {
                self.selectCallback!(isSelected)
            }
        }
    }
    
    @objc private func touchUpInside() {
        isSelected = !isSelected
    }

    //MARK: - Private
    func setup() {
        addSubview(descriptionLabel)
        addSubview(check)
        check.constrain([
            check.leadingAnchor.constraint(equalTo: leadingAnchor, constant: C.padding[2]),
            check.centerYAnchor.constraint(equalTo: descriptionLabel.centerYAnchor, constant: C.padding[0]),
            check.widthAnchor.constraint(equalToConstant: buttonSize),
            check.heightAnchor.constraint(equalToConstant: buttonSize) ])
        descriptionLabel.constrain([
            descriptionLabel.leadingAnchor.constraint(equalTo: check.trailingAnchor, constant: C.padding[3]),
            descriptionLabel.topAnchor.constraint(equalTo: topAnchor, constant: C.padding[2]),
            descriptionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -C.padding[2]),
            descriptionLabel.bottomAnchor.constraint(equalTo: bottomAnchor) ])
        descriptionLabel.numberOfLines = 0
        descriptionLabel.lineBreakMode = .byWordWrapping
        check.setImage(#imageLiteral(resourceName: "CircleUnCheck"), for: .normal)
        check.setImage(#imageLiteral(resourceName: "CircleCheck"), for: .selected)
        addTarget(self, action: #selector(TermsUseCell.touchUpInside), for: .touchUpInside)
        isSelected = false
        check.addTarget(self, action: #selector(TermsUseCell.touchUpInside), for: .touchUpInside)
    }
    
    

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
