//
//  UIControl+Callback.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2017-02-23.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit

private class CallbackWrapper : NSObject, NSCopying {

    init(_ callback: @escaping () -> Void) {
        self.callback = callback
    }

    let callback: () -> Void

    func copy(with zone: NSZone? = nil) -> Any {
        return CallbackWrapper(callback)
    }
}

private class CallbackBoolWrapper : NSObject, NSCopying {
    
    init(_ callback: @escaping (Bool) -> Void) {
        self.boolCallback = callback
    }
    
    let boolCallback: (Bool) -> Void
    
    func copy(with zone: NSZone? = nil) -> Any {
        return CallbackBoolWrapper(boolCallback)
    }
}

private struct AssociatedKeys {
    static var didTapCallback = "didTapCallback"
    static var valueChangedCallback = "valueChangedCallback"
    static var boolChangedCallback = "boolChangedCallback"
    static var valueEditingChangedCallback = "valueEditingChangedCallback"
}

extension UIControl {
    var tap: (() -> Void)? {
        get {
            guard let callbackWrapper = objc_getAssociatedObject(self, &AssociatedKeys.didTapCallback) as? CallbackWrapper else { return nil }
            return callbackWrapper.callback
        }
        set {
            guard let newValue = newValue else { return }
            addTarget(self, action: #selector(didTap), for: .touchUpInside)
            objc_setAssociatedObject(self, &AssociatedKeys.didTapCallback, CallbackWrapper(newValue), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    @objc private func didTap() {
        tap?()
    }

    var valueChanged: (() -> Void)? {
        get {
            guard let callbackWrapper = objc_getAssociatedObject(self, &AssociatedKeys.valueChangedCallback) as? CallbackWrapper else { return nil }
            return callbackWrapper.callback
        }
        set {
            guard let newValue = newValue else { return }
            addTarget(self, action: #selector(valueDidChange), for: .valueChanged)
            objc_setAssociatedObject(self, &AssociatedKeys.valueChangedCallback, CallbackWrapper(newValue), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var boolChanged: ((Bool) -> Void)? {
        get {
            guard let callbackBoolWrapper = objc_getAssociatedObject(self, &AssociatedKeys.boolChangedCallback) as? CallbackBoolWrapper else { return nil }
            return callbackBoolWrapper.boolCallback
        }
        set {
            guard let newValue = newValue else { return }
            addTarget(self, action: #selector(boolDidChange(sender:)), for: .valueChanged)
            objc_setAssociatedObject(self, &AssociatedKeys.boolChangedCallback, CallbackBoolWrapper(newValue), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    var editingChanged: (() -> Void)? {
        get {
            guard let callbackWrapper = objc_getAssociatedObject(self, &AssociatedKeys.valueEditingChangedCallback) as? CallbackWrapper else { return nil }
            return callbackWrapper.callback
        }
        set {
            guard let newValue = newValue else { return }
            addTarget(self, action: #selector(editingChange), for: .editingChanged)
            objc_setAssociatedObject(self, &AssociatedKeys.valueEditingChangedCallback, CallbackWrapper(newValue), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    @objc private func valueDidChange() {
        valueChanged?()
    }
    
    @objc private func boolDidChange(sender:UISwitch) {
        boolChanged?(sender.isOn)
    }

    @objc private func editingChange() {
        editingChanged?()
    }
}
