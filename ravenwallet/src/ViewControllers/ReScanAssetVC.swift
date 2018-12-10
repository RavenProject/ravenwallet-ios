//
//  ReScanViewController.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2017-04-10.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit

class ReScanAssetVC : ReScanViewController {

    override var bodyText: NSAttributedString {
        let body = NSMutableAttributedString()
        let headerAttributes = [ NSAttributedString.Key.font: UIFont.customBold(size: 16.0),
                                 NSAttributedString.Key.foregroundColor: UIColor.darkText ]
        let bodyAttributes = [ NSAttributedString.Key.font: UIFont.customBody(size: 16.0),
                               NSAttributedString.Key.foregroundColor: UIColor.darkText ]

        body.append(NSAttributedString(string: "\(S.ReScanAsset.subheader1)\n", attributes: headerAttributes))
        body.append(NSAttributedString(string: "\(S.ReScanAsset.body1)\n\n", attributes: bodyAttributes))
        body.append(NSAttributedString(string: "\(S.ReScanAsset.body2)\n", attributes: bodyAttributes))
        return body
    }
    
    override func setInitialData() {
        super.setInitialData()
        button.title = S.ReScanAsset.buttonTitle
        header.text = S.ReScanAsset.header
    }
    
    override func presentRescanAlert() {
        let alert = UIAlertController(title: S.ReScanAsset.alertTitle, message: S.ReScanAsset.alertMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: S.Button.cancel, style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: S.ReScanAsset.alertAction, style: .default, handler: { _ in
            Store.trigger(name: .rescan(self.currency))
            self.dismiss(animated: true, completion: nil)
        }))
        present(alert, animated: true, completion: nil)
    }
}
