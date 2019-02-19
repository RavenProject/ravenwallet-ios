//
//  Setting.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2017-04-01.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit

struct Setting {
    let title: String
    let accessoryText: (() -> String)?
    let callback: (() -> Void)?
    let toggle:UISwitch?
    var toggleDefaultValue:Bool = false
    let toggleCallback: ((Bool) -> Void)?
    var isHidden:Bool = false
}

extension Setting {
    init(title: String, callback: @escaping () -> Void) {
        self.title = title
        self.accessoryText = nil
        self.toggle = nil
        self.toggleCallback = nil
        self.callback = callback
    }
    
    init(title: String, isHidden:Bool, callback: @escaping () -> Void) {
        self.title = title
        self.accessoryText = nil
        self.toggle = nil
        self.toggleCallback = nil
        self.callback = callback
        self.isHidden = isHidden
    }
    
    init(title: String, accessoryText: (() -> String)?, callback: @escaping () -> Void) {
        self.title = title
        self.accessoryText = accessoryText
        self.toggle = nil
        self.toggleCallback = nil
        self.callback = callback
    }
    
    init(title: String, toggle: UISwitch, toggleDefaultValue: Bool, toggleCallback: ((Bool) -> Void)?) {
        self.title = title
        self.accessoryText = nil
        self.callback = nil
        self.toggle = toggle
        self.toggleCallback = toggleCallback
        self.toggleDefaultValue = toggleDefaultValue
    }
}
