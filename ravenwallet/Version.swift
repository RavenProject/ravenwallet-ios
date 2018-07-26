//
//  Version.swift
//  Ravencoin
//
//  Created by ROSHii on 7/26/18.
//  Copyright © 2018 Medici Ventures. All rights reserved.
//

import Foundation

class Version {
    var DVersion = "1.1.0"
    static var sharedInstance = Version()
    
    let current_version : String
    
    private init() {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            self.current_version = version
            return
        }
        self.current_version = DVersion
            
    }
}
