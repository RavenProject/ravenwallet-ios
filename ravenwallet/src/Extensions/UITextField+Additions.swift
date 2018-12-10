//
//  UIBarButtonItem+Additions.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2017-04-24.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit

private struct AssociatedKeys {
    static var cancelCallback = "cancelCallback"
    static var doneCallback = "donceCallback"
}

private class CallbackWrapper : NSObject, NSCopying {
    
    init(_ callback: @escaping (UITextField) -> Void) {
        self.callback = callback
    }
    
    let callback: (UITextField) -> Void
    
    func copy(with zone: NSZone? = nil) -> Any {
        return CallbackWrapper(callback)
    }
}

extension UITextField {

    func addDoneCancelToolbar(onDone: ((UITextField) -> Void)? = nil, onCancel: ((UITextField) -> Void)? = nil) {
        doneCallback = onDone
        cencelCallback = onCancel
        let toolbar: UIToolbar = UIToolbar()
        toolbar.barStyle = .default
        toolbar.items = [
            UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelButtonTapped)),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
            UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneButtonTapped))
        ]
        toolbar.sizeToFit()
        
        self.inputAccessoryView = toolbar
    }
    
    // Default actions:
    @objc func doneButtonTapped() {
        self.resignFirstResponder()
        doneCallback?(self)
    }
    @objc func cancelButtonTapped() {
        self.resignFirstResponder()
        cencelCallback?(self)
    }
    
    
    var doneCallback: ((UITextField) -> Void)? {
        get {
            guard let callbackWrapper = objc_getAssociatedObject(self, &AssociatedKeys.doneCallback) as? CallbackWrapper else { return nil }
            return callbackWrapper.callback
        }
        set {
            guard let newValue = newValue else { return }
            addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
            objc_setAssociatedObject(self, &AssociatedKeys.doneCallback, CallbackWrapper(newValue), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var cencelCallback: ((UITextField) -> Void)? {
        get {
            guard let callbackWrapper = objc_getAssociatedObject(self, &AssociatedKeys.cancelCallback) as? CallbackWrapper else { return nil }
            return callbackWrapper.callback
        }
        set {
            guard let newValue = newValue else { return }
            addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
            objc_setAssociatedObject(self, &AssociatedKeys.cancelCallback, CallbackWrapper(newValue), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

}
