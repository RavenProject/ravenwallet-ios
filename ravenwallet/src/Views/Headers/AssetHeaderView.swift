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

class AssetHeaderView : UIView, GradientDrawable, Subscriber {

    // MARK: - Views
    
    private let assetName = UILabel(font: .customBody(size: 18.0))
    private let amountLabel = UILabel(font: .customBody(size: 14.0))
    private let amount = UILabel(font: UIFont(name: "AlexBrush-Regular", size: 40.0)!, color: .transparentWhiteText)
    private let syncIndicator = SyncingIndicator(style: .account)
    
    // MARK: Properties
    private let asset: Asset
    private var hasInitialized = false
    private var hasSetup = false
    
    private var isSyncIndicatorVisible: Bool = false {
        didSet {
            UIView.crossfade(amountLabel, syncIndicator, toRight: isSyncIndicatorVisible, duration: 0.3)
        }
    }

    // MARK: -
    
    init(asset: Asset) {
        self.asset = asset
        super.init(frame: CGRect())
        setup()
    }

    // MARK: Private
    
    private func setup() {
        addSubviews()
        addConstraints()
        addShadow()
        setData()
        addSubscriptions()
    }

    private func setData() {
        assetName.textColor = .white
        assetName.textAlignment = .center
        assetName.text = asset.name
        
        amountLabel.textColor = .transparentWhiteText
        amountLabel.text = S.Asset.quantity
        
        amount.textAlignment = .right
    
        syncIndicator.isHidden = true
    }

    private func addSubviews() {
        addSubview(assetName)
        addSubview(amountLabel)
        addSubview(amount)
        addSubview(syncIndicator)
    }

    private func addConstraints() {
        assetName.constrain([
            assetName.constraint(.leading, toView: self, constant: C.padding[2]),
            assetName.constraint(.trailing, toView: self, constant: -C.padding[2]),
            assetName.constraint(.top, toView: self, constant: E.isIPhoneXOrLater ? C.padding[5] : C.padding[3])
            ])
        
        amountLabel.constrain([
            amountLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -C.padding[2]),
            amountLabel.bottomAnchor.constraint(equalTo: amount.topAnchor, constant: 0.0)
            ])
        
        amount.constrain([
            amount.firstBaselineAnchor.constraint(equalTo: bottomAnchor, constant: -C.padding[2])
            ])
        
        syncIndicator.constrain([
            syncIndicator.trailingAnchor.constraint(equalTo: amountLabel.trailingAnchor),
            syncIndicator.topAnchor.constraint(equalTo: amountLabel.topAnchor),
            syncIndicator.bottomAnchor.constraint(equalTo: amountLabel.bottomAnchor)
            ])
    }

    private func addShadow() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        layer.shadowOpacity = 0.15
        layer.shadowRadius = 8.0
    }

    private func addSubscriptions() {
        //TODO
    }

    override func draw(_ rect: CGRect) {
        drawGradient(start: UIColor.assetGradientStart(isOwnerShip: asset.isOwnerShip), end: UIColor.assetGradientEnd(isOwnerShip: asset.isOwnerShip), rect)
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
