//
//  ShadowButton.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2016-11-15.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit

class ShadowActivityButton:ShadowButton {

    let activityView = UIActivityIndicatorView(style: .white)

    override func addContent() {
        super.addContent()
        addSubview(activityView)
        activityView.constrain([
            activityView.constraint(.trailing, toView: self, constant: -C.padding[2]),
            activityView.centerYAnchor.constraint(equalTo: self.centerYAnchor) ])
        activityView.hidesWhenStopped = true
        activityView.stopAnimating()


    }
}
