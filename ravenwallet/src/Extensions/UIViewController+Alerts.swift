//
//  UIViewController+Alerts.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2017-07-04.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit

extension UIViewController {

    func showErrorMessage(_ message: String) {
        let alert = UIAlertController(title: S.Alert.error, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: S.Button.ok, style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    func showAlert(title: String, message: String, buttonLabel: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: S.Button.ok, style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func showAttributedAlert(title: String, message: NSMutableAttributedString, buttonLabel: String) {
        let alertController = UIAlertController(title: title, message: "", preferredStyle: .alert)
        alertController.setValue(message, forKey: "attributedMessage")
        alertController.addAction(UIAlertAction(title: S.Button.ok, style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func showImageAlert(title: String, message: String, image:UIImage, buttonLabel: String, callback: ((UIAlertAction) -> Void)?) {
        let alertController = AlertController(title: title, message: message, preferredStyle: .alert)
        alertController.setMessageImage(image)
        alertController.addAction(UIAlertAction(title: buttonLabel, style: .default, handler: callback))
        alertController.addAction(UIAlertAction(title: S.Button.ok, style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
}
