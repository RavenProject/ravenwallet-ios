//
//  HomeScreenCell.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2017-11-28.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit

class BackgroundAsset : UIView, GradientDrawable {
    
    var ownerShip: Bool = false
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let maskLayer = CAShapeLayer()
        let corners: UIRectCorner = .allCorners
        maskLayer.path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: 4.0, height: 4.0)).cgPath
        layer.mask = maskLayer
    }
    
    override func draw(_ rect: CGRect) {
        drawGradient(start: !ownerShip ? .darkBlueGradientStart : .orangeGradientStart, end: !ownerShip ? .darkBlueGradientEnd : .orangeGradientEnd, rect)
    }
}

class AssetHomeCell : UITableViewCell, Subscriber {
    
    static let cellIdentifier = "AssetHomeCell"

    private let assetName = UILabel(font: .customMedium(size: 18.0), color: .white)
    private let assetAmount = UILabel(font: .customMedium(size: 18.0), color: .transparentWhiteText)
    private let imgAsset = UIImageView(image: #imageLiteral(resourceName: "owned"))
    private let container = BackgroundAsset()
    private var imgAssetWidth: NSLayoutConstraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    func set(viewModel: AssetListViewModel) {
        container.ownerShip = viewModel.asset.isOwnerShip
        assetName.text = viewModel.asset.name
        assetAmount.text = viewModel.assetAmount
        if viewModel.asset.isOwnerShip {
            imgAssetWidth?.constant = 24.0
        }
        else{
            imgAssetWidth?.constant = 0.0
        }
        container.setNeedsDisplay()
    }

    private func setupViews() {
        addSubviews()
        addConstraints()
        setupStyle()
    }

    private func addSubviews() {
        contentView.addSubview(container)
        container.addSubview(assetName)
        container.addSubview(assetAmount)
        container.addSubview(imgAsset)
    }

    private func addConstraints() {
        container.constrain(toSuperviewEdges: UIEdgeInsets(top: C.padding[1]*0.5,
                                                           left: C.padding[2],
                                                           bottom: -C.padding[1],
                                                           right: -C.padding[2]))
        imgAssetWidth = imgAsset.widthAnchor.constraint(equalToConstant: 0.0)
        imgAsset.constrain([
            imgAsset.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: C.padding[2]),
            imgAsset.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            imgAssetWidth
            ])
        assetName.constrain([
            assetName.leadingAnchor.constraint(equalTo: imgAsset.trailingAnchor, constant: C.padding[1]),
            assetName.centerYAnchor.constraint(equalTo: container.centerYAnchor)
            ])
        assetAmount.constrain([
            assetAmount.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -C.padding[2]),
            assetAmount.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            assetAmount.leadingAnchor.constraint(greaterThanOrEqualTo: assetName.trailingAnchor, constant: C.padding[1])
            ])
    }

    private func setupStyle() {
        selectionStyle = .none
        backgroundColor = .clear
        imgAsset.contentMode = .scaleAspectFit
        //add shadow
        container.backgroundColor = .white
    }
    
    override func prepareForReuse() {
        Store.unsubscribe(self)
    }
    
    deinit {
        Store.unsubscribe(self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
