//
//  UIViewController+BRWAdditions.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2016-10-21.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit

enum CloseButtonSide {
    case left
    case right
}

extension UIViewController {
    func addChild(_ viewController: UIViewController, layout: () -> Void) {
        addChild(viewController)
        view.addSubview(viewController.view)
        layout()
        viewController.didMove(toParent: self)
    }
    
    func addChildVC(_ viewController: UIViewController) {
        addChild(viewController)
        view.addSubview(viewController.view)
        viewController.didMove(toParent: self)
    }

    func remove() {
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }

    func addCloseNavigationItem(tintColor: UIColor? = nil, side: CloseButtonSide = .left) {
        let close = UIButton.close
        close.tap = { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
        if let color = tintColor {
            close.tintColor = color
        }
        navigationItem.leftBarButtonItems = [UIBarButtonItem.negativePadding, UIBarButtonItem(customView: close)]
        switch side {
        case .left:
            navigationItem.leftBarButtonItems = [UIBarButtonItem.negativePadding, UIBarButtonItem(customView: close)]
        case .right:
            navigationItem.rightBarButtonItems = [UIBarButtonItem(customView: close), UIBarButtonItem.negativePadding]
        }
    }
    
    func presentFullScreen(_ viewControllerToPresent: UIViewController, animated:Bool, completion:(() -> Void)?) {
        viewControllerToPresent.modalPresentationStyle = .fullScreen
        self.present(viewControllerToPresent, animated: animated, completion: completion)
    }
}
