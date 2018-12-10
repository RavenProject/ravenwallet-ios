//
//  HomeScreenCell.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2017-11-28.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit

class ShowMoreCell : UITableViewCell {
    
    static let cellIdentifier = "ShowMoreCell"

    private let showMoreLabel = UILabel(font: .customMedium(size: 18.0), color: .primaryButton)
    private let container = Background()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    private func setupViews() {
        showMoreLabel.text = "Show More ..."
        addSubviews()
        addConstraints()
        setupStyle()
    }

    private func addSubviews() {
        contentView.addSubview(container)
        container.addSubview(showMoreLabel)
    }

    private func addConstraints() {
        container.constrain(toSuperviewEdges: UIEdgeInsets(top: C.padding[1]*0.5,
                                                           left: C.padding[2],
                                                           bottom: -C.padding[1],
                                                           right: -C.padding[2]))
        showMoreLabel.constrain([
            showMoreLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 0),
            showMoreLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            showMoreLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor)
            ])
    }

    private func setupStyle() {
        showMoreLabel.textAlignment = .center
        selectionStyle = .none
        backgroundColor = .clear
        //add shadow
        container.backgroundColor = .clear
        container.layer.cornerRadius = 4.0
        container.layer.borderWidth = 1.0
        container.layer.borderColor = UIColor.primaryButton.cgColor
        container.layer.shadowOpacity = 0.15
        container.layer.shadowRadius = 4.0
        container.layer.shadowOffset = .zero
        container.layer.shadowColor = UIColor.clear.cgColor
        container.layer.shadowOpacity = 0.3
    }
    
    override func prepareForReuse() {
    }
    
    deinit {
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
