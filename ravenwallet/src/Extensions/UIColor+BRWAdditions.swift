//
//  UIColor+BRWAdditions.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2016-10-21.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit

extension UIColor {

    // MARK: Buttons
    static var primaryButton: UIColor {
        return UIColor(red:46/255.0, green:62/255.0, blue:128/255.0, alpha:1.0)
    }

    static var primaryText: UIColor {
        return .white
    }

    static var tertiaryButton: UIColor {
        return UIColor(red: 241.0/255.0, green: 103.0/255.0, blue: 38.0/255.0, alpha: 1.0)
    }
    
    static var secondaryButton: UIColor {
        return UIColor(red: 86.0/255.0, green: 103.0/255.0, blue: 165.0/255.0, alpha: 1.0)
    }

    static var secondaryBorder: UIColor {
        return UIColor(red: 241.0/255.0, green: 103.0/255.0, blue: 38.0/255.0, alpha: 1.0)
    }

    static var tertiaryBorder: UIColor {
        return UIColor(red: 241.0/255.0, green: 103.0/255.0, blue: 38.0/255.0, alpha: 1.0)
    }
    
    static var darkText: UIColor {
        return UIColor(red: 35.0/255.0, green: 37.0/255.0, blue: 38.0/255.0, alpha: 1.0)
    }

    static var darkLine: UIColor {
        return UIColor(red: 36.0/255.0, green: 35.0/255.0, blue: 38.0/255.0, alpha: 1.0)
    }

    static var secondaryShadow: UIColor {
        return UIColor(red: 213.0/255.0, green: 218.0/255.0, blue: 224.0/255.0, alpha: 1.0)
    }

    // MARK: Gradient
    static var gradientStart: UIColor {
        return UIColor(red:0/255.0, green:10/255.0, blue:69/255.0, alpha:1.0)
    }

    static var gradientEnd: UIColor {
        return UIColor(red:46/255.0, green:62/255.0, blue:128/255.0, alpha:1.0)
    }

    static var offWhite: UIColor {
        return UIColor(white: 247.0/255.0, alpha: 1.0)
    }

    static var borderGray: UIColor {
        return UIColor(white: 221.0/255.0, alpha: 1.0)
    }

    static var separatorGray: UIColor {
        return UIColor(white: 221.0/255.0, alpha: 1.0)
    }

    static var grayText: UIColor {
        return UIColor(white: 136.0/255.0, alpha: 1.0)
    }

    static var grayTextTint: UIColor {
        return UIColor(red: 163.0/255.0, green: 168.0/255.0, blue: 173.0/255.0, alpha: 1.0)
    }

    static var secondaryGrayText: UIColor {
        return UIColor(red: 101.0/255.0, green: 105.0/255.0, blue: 110.0/255.0, alpha: 1.0)
    }

    static var grayBackgroundTint: UIColor {
        return UIColor(red: 250.0/255.0, green: 251.0/255.0, blue: 252.0/255.0, alpha: 1.0)
    }

    static var cameraGuidePositive: UIColor {
        return UIColor(red: 72.0/255.0, green: 240.0/255.0, blue: 184.0/255.0, alpha: 1.0)
    }

    static var cameraGuideNegative: UIColor {
        return UIColor(red: 240.0/255.0, green: 74.0/255.0, blue: 93.0/255.0, alpha: 1.0)
    }

    static var purple: UIColor {
        return UIColor(red: 74.0/255.0, green: 29.0/255.0, blue: 92.0/255.0, alpha: 1.0)
    }

    static var darkPurple: UIColor {
        return UIColor(red: 54.0/255.0, green: 44.0/255.0, blue: 70.0/255.0, alpha: 1.0)
    }

    static var pink: UIColor {
        return UIColor(red: 252.0/255.0, green: 83.0/255.0, blue: 148.0/255.0, alpha: 1.0)
    }

    static var blue: UIColor {
        return UIColor(red: 46.0/255.0, green: 62.0/255.0, blue: 128.0/255.0, alpha: 1.0)
    }
    
    static var webBlue: UIColor {
        return UIColor(red: 40.0/255.0, green: 54.0/255.0, blue: 116.0/255.0, alpha: 1.0)
    }

    static var whiteTint: UIColor {
        return UIColor(red: 245.0/255.0, green: 247.0/255.0, blue: 250.0/255.0, alpha: 1.0)
    }

    static var transparentWhite: UIColor {
        return UIColor(white: 1.0, alpha: 0.3)
    }
    
    static var transparentWhiteText: UIColor {
        return UIColor(white: 1.0, alpha: 0.7)
    }
    
    static var disabledWhiteText: UIColor {
        return UIColor(white: 1.0, alpha: 0.5)
    }

    static var transparentBlack: UIColor {
        return UIColor(white: 0.0, alpha: 0.3)
    }

    static var blueGradientStart: UIColor {
        return UIColor(red: 99.0/255.0, green: 188.0/255.0, blue: 255.0/255.0, alpha: 1.0)
    }

    static var blueGradientEnd: UIColor {
        return UIColor(red: 56.0/255.0, green: 141.0/255.0, blue: 252.0/255.0, alpha: 1.0)
    }
    
    static func assetGradientStart(isOwnerShip:Bool) -> UIColor {
        return isOwnerShip ? .darkBlueGradientStart : .orangeGradientStart
    }
    
    static func assetGradientEnd(isOwnerShip:Bool) -> UIColor {
        return isOwnerShip ? .darkBlueGradientEnd : .orangeGradientEnd
    }
    
    static var darkBlueGradientStart: UIColor {
        return UIColor(red: 71.0/255.0, green: 100.0/255.0, blue: 177.0/255.0, alpha: 1.0)
    }
    
    static var darkBlueGradientEnd: UIColor {
        return UIColor(red: 67.0/255.0, green: 95.0/255.0, blue: 170.0/255.0, alpha: 1.0)
    }

    static var orangeGradientStart: UIColor {
        return UIColor(red: 241.0/255.0, green: 91.0/255.0, blue: 35.0/255.0, alpha: 1.0)
    }
    
    static var orangeGradientEnd: UIColor {
        return UIColor(red: 246.0/255.0, green: 135.0/255.0, blue: 47.0/255.0, alpha: 1.0)
    }
    
    static var txListGreen: UIColor {
        return UIColor(red: 23.0/255.0, green: 175.0/255.0, blue: 99.0/255.0, alpha: 1.0)
    }
    
    static var blueButtonText: UIColor {
        return UIColor(red: 127.0/255.0, green: 181.0/255.0, blue: 255.0/255.0, alpha: 1.0)
    }
    
    static var darkGray: UIColor {
        return UIColor(red: 84.0/255.0, green: 104.0/255.0, blue: 117.0/255.0, alpha: 1.0)
    }
    
    static var lightGray: UIColor {
        return UIColor(red: 179.0/255.0, green: 192.0/255.0, blue: 200.0/255.0, alpha: 1.0)
    }
    
    static var mediumGray: UIColor {
        return UIColor(red: 120.0/255.0, green: 143.0/255.0, blue: 158.0/255.0, alpha: 1.0)
    }
    
    static var receivedGreen: UIColor {
        return UIColor(red: 23.0/255.0, green: 175.0/255.0, blue: 99.0/255.0, alpha: 1.0)
    }
    
    static var sentRed: UIColor {
        return UIColor(red: 208.0/255.0, green: 10.0/255.0, blue: 10.0/255.0, alpha:1.0)
    }
    
    static var statusIndicatorActive: UIColor {
        return UIColor(red: 75.0/255.0, green: 119.0/255.0, blue: 243.0/255.0, alpha: 1.0)
    }
    
    static var grayBackground: UIColor {
        return UIColor(red: 224.0/255.0, green: 229.0/255.0, blue: 232.0/255.0, alpha: 1.0)
    }
    
    static var whiteBackground: UIColor {
        return UIColor(red: 249.0/255.0, green: 251.0/255.0, blue: 254.0/255.0, alpha: 1.0)
    }
    
    static var separator: UIColor {
        return UIColor(red: 236.0/255.0, green: 236.0/255.0, blue: 236.0/255.0, alpha: 1.0)
    }
}
