//
//  Setting.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2017-04-01.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import Foundation

struct Setting {
    let title: String
    let accessoryText: (() -> String)?
    let callback: () -> Void
}

extension Setting {
    init(title: String, callback: @escaping () -> Void) {
        self.title = title
        self.accessoryText = nil
        self.callback = callback
    }
}
