//
//  PaperPhraseViewController.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2016-10-25.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit

class StartPaperPhraseViewController : UIViewController {

    init(callback: @escaping () -> Void) {
        self.callback = callback
        let buttonTitle = UserDefaults.walletRequiresBackup ? S.StartPaperPhrase.buttonTitle : S.StartPaperPhrase.againButtonTitle
        button = ShadowButton(title: buttonTitle, type: .primary)
        super.init(nibName: nil, bundle: nil)
    }

    private let button: ShadowButton
    private let illustration = UIImageView(image: #imageLiteral(resourceName: "PaperKey"))
    private let pencil = UIImageView(image: #imageLiteral(resourceName: "Pencil"))
    private let subHeader = OrangeGradientHeader()
//    private let invisibleView = UIView()
    private let explanation = UILabel.wrapping(font: UIFont.customBody(size: 16.0))
    private let important = UILabel.wrapping(font: UIFont.customBody(size: 22.0))
    private let header = BlueGradiantCenterHeader()
    private let footer = UILabel.wrapping(font: .customBody(size: 13.0), color: .secondaryGrayText)
    private let callback: () -> Void

    override func viewDidLoad() {
        view.backgroundColor = .white
        explanation.text = S.StartPaperPhrase.body
        explanation.textColor = .white
        
        important.text = S.StartPaperPhrase.important
        important.textColor = .white
        
        addSubviews()
        addConstraints()
        button.tap = { [weak self] in
            self?.callback()
        }
        if let writePaperPhraseDate = UserDefaults.writePaperPhraseDate {
            let df = DateFormatter()
            df.setLocalizedDateFormatFromTemplate("MMMM d, yyyy")
            footer.text = String(format: S.StartPaperPhrase.date, df.string(from: writePaperPhraseDate))
        }
    }

    private func addSubviews() {
        view.addSubview(header)
        subHeader.addSubview(explanation)
        subHeader.addSubview(important)
        view.addSubview(subHeader)
//        view.addSubview(invisibleView)
//        invisibleView.addSubview(illustration)
        view.addSubview(illustration)
//        illustration.addSubview(pencil)
//        view.addSubview(explanation)
        view.addSubview(button)
        view.addSubview(footer)
    }

    private func addConstraints() {
        header.constrainTopCorners(sidePadding: 0, topPadding: 0)
        header.constrain([
              header.constraint(.height, constant: 100.0) ])
        subHeader.constrain([
            subHeader.constraint(.height, constant: 200.0),
            subHeader.topAnchor.constraint(equalTo: header.bottomAnchor),
            subHeader.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            subHeader.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
//        invisibleView.constrain([
//            invisibleView.constraint(.width, constant: 0),
//            invisibleView.constraint(.height, constant: 0),
//            invisibleView.topAnchor.constraint(equalTo: subHeader.bottomAnchor),
//            invisibleView.bottomAnchor.constraint(equalTo: button.topAnchor),
//            invisibleView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            invisibleView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
//            ])
        illustration.constrain([
            illustration.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1/3),
            illustration.heightAnchor.constraint(equalTo: illustration.widthAnchor),
            illustration.constraint(.centerX, toView: view, constant: nil),
            illustration.topAnchor.constraint(equalTo: view.centerYAnchor, constant: C.padding[5]) ])
        important.constrain([
            important.topAnchor.constraint(equalTo: subHeader.topAnchor, constant: C.padding[2]),
            important.constraint(.leading, toView: subHeader, constant: C.padding[2]),
            important.constraint(.trailing, toView: subHeader, constant: -C.padding[2]) ])
        explanation.constrain([
            explanation.topAnchor.constraint(equalTo: important.bottomAnchor, constant: C.padding[2]),
            explanation.constraint(.leading, toView: subHeader, constant: C.padding[2]),
            explanation.constraint(.trailing, toView: subHeader, constant: -C.padding[2]) ])
        button.constrain([
            button.leadingAnchor.constraint(equalTo: footer.leadingAnchor),
            button.bottomAnchor.constraint(equalTo: footer.topAnchor, constant: -C.padding[4]),
            button.trailingAnchor.constraint(equalTo: footer.trailingAnchor),
            button.constraint(.height, constant: C.Sizes.buttonHeight) ])
        footer.constrain([
            footer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: C.padding[2]),
            footer.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -C.padding[4]),
            footer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -C.padding[2]) ])
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
