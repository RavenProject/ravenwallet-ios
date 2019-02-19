    
//
//  Main.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2017-02-17.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit

private func delegateClassName() -> String? {
    return NSClassFromString("XCTestCase") == nil ? NSStringFromClass(AppDelegate.self) : nil
}

    UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, delegateClassName())
