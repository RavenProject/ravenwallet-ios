//
//  AssetManageCell.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2017-11-28.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit

class AssetManageCell : UITableViewCell {
    
    static let cellIdentifier = "AssetManageCell"

    private let assetName = UILabel(font: .customMedium(size: 18.0), color: .darkGray)
    private let imgAsset = UIImageView()
    let hide = ShadowButton(title: S.Asset.hideTitle, type: .primary)
    private var viewModel: AssetListViewModel?
    private let separator = UIView(color: .separator)

    private var isAssetHidden: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.assetName.textColor = self.isAssetHidden ? .lightGray : .darkGray
                if self.isAssetHidden {
                    self.hide.layer.borderColor = UIColor.orangeGradientEnd.cgColor
                    self.hide.title = S.Asset.hideTitle
                    self.hide.container.backgroundColor = UIColor.orangeGradientEnd.withAlphaComponent(0.5)
                }
                else{
                    self.hide.layer.borderColor = UIColor.blueGradientEnd.cgColor
                    self.hide.title = S.Asset.showTitle
                    self.hide.container.backgroundColor = UIColor.blueGradientEnd.withAlphaComponent(0.5)
                }
            }
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    func set(viewModel: AssetListViewModel) {
        assetName.text = viewModel.asset.name
        self.viewModel = viewModel
        self.isAssetHidden = viewModel.asset.isHidden
    }

    private func setupViews() {
        addSubviews()
        addConstraints()
        setupStyle()
        addButtonActions()
    }

    private func addSubviews() {
        contentView.addSubview(assetName)
        contentView.addSubview(hide)
        contentView.addSubview(separator)
    }

    private func addConstraints() {
        assetName.constrain([
            assetName.leadingAnchor.constraint(equalTo: leadingAnchor, constant: C.padding[2]),
            assetName.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
        hide.constrain([
            hide.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -C.padding[6]),
            hide.centerYAnchor.constraint(equalTo: centerYAnchor),
            hide.leadingAnchor.constraint(greaterThanOrEqualTo: assetName.trailingAnchor, constant: C.padding[1])
            ])
        separator.constrain([
            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.topAnchor.constraint(equalTo: bottomAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1.0) ])
    }

    private func setupStyle() {
        selectionStyle = .none
        backgroundColor = .white
        hide.layer.borderWidth = 1.0
        hide.layer.cornerRadius = 4.0
        hide.layer.masksToBounds = true
        hide.shadowView.isHidden = true
    }
    
    private func addButtonActions() {
        hide.addTarget(self, action: #selector(AssetManageCell.hideTapped), for: .touchUpInside)
        hide.isToggleable = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func hideTapped() {
        
        self.viewModel!.asset.hidden ^= 1
        self.isAssetHidden = self.viewModel!.asset.isHidden
        AssetManager.shared.hideAsset(asset: viewModel!.asset, where: viewModel!.asset.idAsset)
    }
}
