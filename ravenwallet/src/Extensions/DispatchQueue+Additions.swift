//
//  DispatchQueue+Additions.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2017-04-20.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import Foundation

extension DispatchQueue {
    static var walletQueue: DispatchQueue = {
        return DispatchQueue(label: C.walletQueue)
    }()
}
