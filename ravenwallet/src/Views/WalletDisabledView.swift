//
//  WalletDisabledView.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2017-05-01.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit

class WalletDisabledView : UIView {

    func setTimeLabel(string: String) {
        label.text = string
    }

    init() {
        self.faq = UIButton.buildFaqButton(articleId: ArticleIds.walletDisabled)
        blur = UIVisualEffectView()
        super.init(frame: .zero)
        setup()
    }

    func show() {
        UIView.animate(withDuration: C.animationDuration, animations: {
            self.blur.effect = self.effect
        })
    }

    func hide(completion: @escaping () -> Void) {
        UIView.animate(withDuration: C.animationDuration, animations: {
            self.blur.effect = nil
        }, completion: { _ in
            completion()
        })
    }

    var didTapReset: (() -> Void)? {
        didSet {
            reset.tap = didTapReset
        }
    }

    private let label = UILabel(font: .customBold(size: 20.0), color: .darkText)
    private let faq: UIButton
    private let blur: UIVisualEffectView
    private let reset = ShadowButton(title: S.UnlockScreen.resetPin, type: .blackTransparent)
    private let wipe = ShadowButton(title: S.WipeSetting.title, type: .blackTransparent)
    private let effect = UIBlurEffect(style: .light)

    private func setup() {
        addSubviews()
        addConstraints()
        setData()
    }

    private func addSubviews() {
        addSubview(blur)
        addSubview(label)
        addSubview(faq)
        addSubview(reset)
        addSubview(wipe)
    }

    private func addConstraints() {
        blur.constrain(toSuperviewEdges: nil)
        label.constrain([
            label.centerYAnchor.constraint(equalTo: blur.centerYAnchor),
            label.centerXAnchor.constraint(equalTo: blur.centerXAnchor) ])
        faq.constrain([
            faq.leadingAnchor.constraint(equalTo: leadingAnchor, constant: C.padding[2]),
            faq.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -C.padding[2]),
            faq.widthAnchor.constraint(equalToConstant: 44.0),
            faq.heightAnchor.constraint(equalToConstant: 44.0)])
        reset.constrain([
            reset.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -C.padding[2]),
            reset.centerYAnchor.constraint(equalTo: faq.centerYAnchor),
            reset.heightAnchor.constraint(equalToConstant: C.Sizes.buttonHeight),
            reset.widthAnchor.constraint(equalToConstant: 200.0) ])
        wipe.constrain([
            wipe.trailingAnchor.constraint(equalTo: reset.trailingAnchor),
            wipe.bottomAnchor.constraint(equalTo: reset.topAnchor, constant: -C.padding[1]),
            wipe.heightAnchor.constraint(equalToConstant: C.Sizes.buttonHeight),
            wipe.widthAnchor.constraint(equalToConstant: 200.0) ])

    }

    private func setData() {
        label.textAlignment = .center
        wipe.tap = {
            let alert = UIAlertController(title: S.WipeWallet.alertTitle, message: S.WipeWallet.alertResetMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: S.Button.cancel, style: .default, handler: nil))
            alert.addAction(UIAlertAction(title: S.WipeWallet.wipe, style: .destructive, handler: { _ in
                Store.trigger(name: .wipeWalletNoPrompt)
            }))
            self.parentViewController()!.present(alert, animated: true, completion: nil)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
