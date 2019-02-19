//
//  UIView+AnimationAdditions.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2016-11-28.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit

extension UIView {
    static func spring(_ duration: TimeInterval, delay: TimeInterval, animations: @escaping () -> Void, completion: @escaping (Bool) -> Void) {
            UIViewPropertyAnimator.springAnimation(duration, delay: delay, animations: animations, completion: {_ in completion(true) })
    }

    static func spring(_ duration: TimeInterval, animations: @escaping () -> Void, completion: @escaping (Bool) -> Void) {
            UIViewPropertyAnimator.springAnimation(duration, animations: animations, completion: {_ in completion(true) })
    }
    
    func fadeIn(_ duration: TimeInterval = 0.5, delay: TimeInterval = 0.0, completion: @escaping ((Bool) -> Void) = {(finished: Bool) -> Void in}) {
        UIView.animate(withDuration: duration, delay: delay, options: UIView.AnimationOptions.curveEaseOut, animations: {
            self.alpha = 1.0
        }, completion: completion)  }
    
    func fadeOut(_ duration: TimeInterval = 0.5, delay: TimeInterval = 1.0, completion: @escaping (Bool) -> Void = {(finished: Bool) -> Void in}) {
        UIView.animate(withDuration: duration, delay: delay, options: UIView.AnimationOptions.curveEaseIn, animations: {
            self.alpha = 0.3
        }, completion: completion)
    }
}
