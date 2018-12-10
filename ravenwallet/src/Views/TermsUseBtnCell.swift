//
//  SecurityCenterCell.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2017-02-15.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit

private let buttonSize: CGFloat = 30.0

class TermsUseBtnCell : TermsUseCell {
    
    override var isSelected: Bool {
        didSet {
            check.tintColor = isSelected ? .darkGray : .lightGray
            descriptionLabel.textColor = isSelected ? .darkGray : .lightGray
            if selectCallback != nil {
                self.selectCallback!(isSelected)
            }
        }
    }
    
}
