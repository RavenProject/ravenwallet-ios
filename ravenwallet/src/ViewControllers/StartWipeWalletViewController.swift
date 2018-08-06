//
//  StartWipeWalletViewController.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2017-07-04.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit

class StartWipeWalletViewController : UIViewController {

    init(didTapNext: @escaping () -> Void) {
        self.didTapNext = didTapNext
        super.init(nibName: nil, bundle: nil)
    }

    private let didTapNext: () -> Void
    private let header = SecurityCenterHeader()
    private let subHeader = OrangeGradientHeader()
    private let illustration = UIImageView(image: #imageLiteral(resourceName: "RestoreIllustration"))
    private let message = UILabel.wrapping(font: .customBody(size: 16.0), color: .darkText)
    private let warning = UILabel.wrapping(font: .customBody(size: 16.0), color: .darkText)
    private let button = ShadowButton(title: S.RecoverWallet.next, type: .primary)
//    private let bullet = UIImageView(image: #imageLiteral(resourceName: "deletecircle"))

    override func viewDidLoad() {
        
        message.textColor = .white
        warning.textColor = .white
        
        addSubviews()
        addConstraints()
        setInitialData()
    }

    private func addSubviews() {
        view.addSubview(header)
        view.addSubview(subHeader)
        view.addSubview(illustration)
        subHeader.addSubview(message)
        subHeader.addSubview(warning)
//        view.addSubview(bullet)
        view.addSubview(button)
    }

    private func addConstraints() {
        header.constrainTopCorners(sidePadding: 0, topPadding: 0)
        header.constrain([
            header.constraint(.height, constant: 100.0) ])
        subHeader.constrain([
            subHeader.constraint(.height, constant: 180.0),
            subHeader.topAnchor.constraint(equalTo: header.bottomAnchor),
            subHeader.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            subHeader.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
        
        illustration.constrain([
            illustration.constraint(.width, constant: 107.0),
            illustration.constraint(.height, constant: 116.0),
            illustration.constraint(.centerX, toView: view, constant: nil),
            illustration.topAnchor.constraint(equalTo: subHeader.bottomAnchor, constant: C.padding[15]) ])
        message.constrain([
            message.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: C.padding[2]),
            message.topAnchor.constraint(equalTo: header.bottomAnchor, constant: C.padding[2]),
            message.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -C.padding[2]) ])
//        bullet.constrain([
//            bullet.leadingAnchor.constraint(equalTo: message.leadingAnchor),
//            bullet.topAnchor.constraint(equalTo: message.bottomAnchor, constant: C.padding[4]),
//            bullet.widthAnchor.constraint(equalToConstant: 16.0),
//            bullet.heightAnchor.constraint(equalToConstant: 16.0) ])
        warning.constrain([
            warning.leadingAnchor.constraint(equalTo: /*bullet*/view.leadingAnchor, constant: C.padding[2]),
            warning.topAnchor.constraint(equalTo: /*bullet*/message.bottomAnchor, constant: C.padding[2]),
            warning.trailingAnchor.constraint(equalTo: message.trailingAnchor, constant: C.padding[2]) ])
        button.constrain([
            button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: C.padding[3]),
            button.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -C.padding[8]),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -C.padding[3]),
            button.constraint(.height, constant: C.Sizes.buttonHeight) ])
    }

    private func setInitialData() {
        view.backgroundColor = .white
        illustration.contentMode = .scaleAspectFill
        message.text = S.WipeWallet.startMessage
        warning.text = S.WipeWallet.startWarning
        button.tap = { [weak self] in
            self?.didTapNext()
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
