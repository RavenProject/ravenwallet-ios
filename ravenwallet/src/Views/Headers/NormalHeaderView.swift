//
//  AccountHeaderView.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2016-11-16.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit

private let largeFontSize: CGFloat = 28.0
private let smallFontSize: CGFloat = 14.0

class NormalHeaderView : UIView, GradientDrawable, Subscriber {

    // MARK: - Views
    
    private let titleLabel = UILabel(font: .customMedium(size: 18.0))
    private var title:String = ""
    private var regularConstraints: [NSLayoutConstraint] = []
    private var swappedConstraints: [NSLayoutConstraint] = []

    // MARK: -
    
    init(title:String) {
        self.title = title
        super.init(frame: CGRect())
        
        setup()
    }

    // MARK: Private
    
    private func setup() {
        addSubviews()
        addConstraints()
        addShadow()
        setData()
    }

    private func setData() {
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.text = title
    }

    private func addSubviews() {
        addSubview(titleLabel)
    }

    private func addConstraints() {
        titleLabel.constrain([
            titleLabel.constraint(.leading, toView: self, constant: C.padding[2]),
            titleLabel.constraint(.trailing, toView: self, constant: -C.padding[2]),
            titleLabel.constraint(.top, toView: self, constant: E.isIPhoneXOrLater ? C.padding[5] : C.padding[3])
            ])
    }

    private func addShadow() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        layer.shadowOpacity = 0.15
        layer.shadowRadius = 8.0
    }

    override func draw(_ rect: CGRect) {
        drawGradient(rect)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: -

private extension UILabel {
    func makePrimary() {
        font = UIFont.customBold(size: largeFontSize)
        textColor = .white
        reset()
    }
    
    func makeSecondary() {
        font = UIFont.customBody(size: largeFontSize)
        textColor = .transparentWhiteText
        shrink()
    }
    
    func shrink() {
        transform = .identity // must reset the view's transform before we calculate the next transform
        let scaleFactor: CGFloat = smallFontSize/largeFontSize
        let deltaX = frame.width * (1-scaleFactor)
        let deltaY = frame.height * (1-scaleFactor)
        let scale = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
        transform = scale.translatedBy(x: deltaX, y: deltaY/2.0)
    }
    
    func reset() {
        transform = .identity
    }
    
    func toggle() {
        if transform.isIdentity {
            makeSecondary()
        } else {
            makePrimary()
        }
    }
}
