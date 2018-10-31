//
//  CheckView.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2016-11-22.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit

class CheckView : UIView, AnimatableIcon {

    public func animate() {
        let check = UIBezierPath()
        check.move(to: CGPoint(x: 32.5, y: 47.0))
        check.addLine(to: CGPoint(x: 43.0, y: 57.0))
        check.addLine(to: CGPoint(x: 63, y: 37.4))

        let shape = CAShapeLayer()
        shape.path = check.cgPath
        shape.lineWidth = 9.0
        shape.strokeColor = UIColor.white.cgColor
        shape.fillColor = UIColor.clear.cgColor
        shape.strokeStart = 0.0
        shape.strokeEnd = 0.0
        shape.lineCap = CAShapeLayerLineCap(rawValue: "round")
        shape.lineJoin = CAShapeLayerLineJoin(rawValue: "round")
        layer.addSublayer(shape)

        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.toValue = 1.0
        animation.isRemovedOnCompletion = false
        animation.fillMode = CAMediaTimingFillMode.forwards
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.default)
        animation.duration = 0.3

        shape.add(animation, forKey: nil)
    }

    override func draw(_ rect: CGRect) {

        let checkcircle = UIBezierPath()
        checkcircle.move(to: CGPoint(x: 47.76, y: -0))
        checkcircle.addCurve(to: CGPoint(x: 0, y: 47.76), controlPoint1: CGPoint(x: 21.38, y: -0), controlPoint2: CGPoint(x: 0, y: 21.38))
        checkcircle.addCurve(to: CGPoint(x: 47.76, y: 95.52), controlPoint1: CGPoint(x: 0, y: 74.13), controlPoint2: CGPoint(x: 21.38, y: 95.52))
        checkcircle.addCurve(to: CGPoint(x: 95.52, y: 47.76), controlPoint1: CGPoint(x: 74.14, y: 95.52), controlPoint2: CGPoint(x: 95.52, y: 74.13))
        checkcircle.addCurve(to: CGPoint(x: 47.76, y: -0), controlPoint1: CGPoint(x: 95.52, y: 21.38), controlPoint2: CGPoint(x: 74.14, y: -0))
        checkcircle.addLine(to: CGPoint(x: 47.76, y: -0))
        checkcircle.close()
        checkcircle.move(to: CGPoint(x: 47.99, y: 85.97))
        checkcircle.addCurve(to: CGPoint(x: 9.79, y: 47.76), controlPoint1: CGPoint(x: 26.89, y: 85.97), controlPoint2: CGPoint(x: 9.79, y: 68.86))
        checkcircle.addCurve(to: CGPoint(x: 47.99, y: 9.55), controlPoint1: CGPoint(x: 9.79, y: 26.66), controlPoint2: CGPoint(x: 26.89, y: 9.55))
        checkcircle.addCurve(to: CGPoint(x: 86.2, y: 47.76), controlPoint1: CGPoint(x: 69.1, y: 9.55), controlPoint2: CGPoint(x: 86.2, y: 26.66))
        checkcircle.addCurve(to: CGPoint(x: 47.99, y: 85.97), controlPoint1: CGPoint(x: 86.2, y: 68.86), controlPoint2: CGPoint(x: 69.1, y: 85.97))
        checkcircle.close()

        UIColor.white.setFill()
        checkcircle.fill()
    }
}
