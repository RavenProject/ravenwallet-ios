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
    private func setup() {
        addSubview(descriptionLabel)
        addSubview(check)
        check.constrain([
            check.leadingAnchor.constraint(equalTo: leadingAnchor, constant: C.padding[2]),
            check.topAnchor.constraint(equalTo: topAnchor, constant: C.padding[2]),
            check.widthAnchor.constraint(equalToConstant: buttonSize),
            check.heightAnchor.constraint(equalToConstant: buttonSize) ])
        descriptionLabel.constrain([
            descriptionLabel.leadingAnchor.constraint(equalTo: check.trailingAnchor, constant: C.padding[3]),
            descriptionLabel.topAnchor.constraint(equalTo: check.topAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -C.padding[2]),
            descriptionLabel.bottomAnchor.constraint(equalTo: bottomAnchor) ])
        descriptionLabel.numberOfLines = 0
        descriptionLabel.lineBreakMode = .byWordWrapping
        check.imageView?.contentMode = .scaleToFill
        check.setImage(#imageLiteral(resourceName: "CircleCheck"), for: .normal)
        addTarget(self, action: #selector(TermsUseCell.touchUpInside), for: .touchUpInside)
        isSelected = false
    }
    
    

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
