//
//  UIScreen+Additions.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2017-09-28.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit

extension UIScreen {
    var safeWidth: CGFloat {
        return min(bounds.width, bounds.height)
    }
}
