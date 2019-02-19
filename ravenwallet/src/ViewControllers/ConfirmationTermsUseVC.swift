//
//  SecurityCenterViewController.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2017-02-14.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit
import LocalAuthentication

class BlueGradiantScroll : UIScrollView, GradientDrawable {
    override func draw(_ rect: CGRect) {
        drawGradient(rect)
    }
}

class ConfirmationTermsUseVC : UIViewController, Subscriber {
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    private let headerBackground = BlueGradiantCenterHeader()
    private let scrollView = BlueGradiantScroll()
    private let titleLabel = UILabel(font: .customMedium(size: 26.0), color: .white)
    private let infoLabel = UILabel(font: .customBody(size: 16.0), color: .lightGray)
    private let firstTermCell = TermsUseCell(descriptionText: S.TermsOfUse.Cells.firstTermDescription)
    private let secondTermCell = TermsUseCell(descriptionText: S.TermsOfUse.Cells.secondTermDescription)
    private let acceptCell = TermsUseBtnCell(descriptionText: S.TermsOfUse.Cells.acceptDescription)
    private let container = UIView()
    private let confirmBtn = ShadowButton(title: S.TermsOfUse.confirmButton, type: .primary)
    var didSelectCallback: ((Bool) -> Void)?

    fileprivate var didViewAppear = false
    
    deinit {
        Store.unsubscribe(self)
    }
    
    override func viewDidLoad() {
        setupSubviewProperties()
        addSubviews()
        addConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        didViewAppear = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        didViewAppear = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        didViewAppear = false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    private func setupSubviewProperties() {
        scrollView.alwaysBounceVertical = true
        scrollView.panGestureRecognizer.delaysTouchesBegan = false
        scrollView.delegate = self
        titleLabel.text = S.TermsOfUse.title
        titleLabel.textAlignment = .center
        infoLabel.text = S.TermsOfUse.info
        infoLabel.textAlignment = .center
        infoLabel.numberOfLines = 0
        infoLabel.lineBreakMode = .byWordWrapping
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .white
        confirmBtn.addTarget(self, action: #selector(ConfirmationTermsUseVC.confirmTaped), for: .touchUpInside)
        confirmBtn.isEnabled = false
        acceptCell.isEnabled = false
        didSelectCallback = { isSelected in
            self.confirmBtn.isEnabled = false
            if !self.firstTermCell.isSelected || !self.secondTermCell.isSelected {
                self.acceptCell.isEnabled = false
            }
            else{
                self.acceptCell.isEnabled = true
            }
            if self.firstTermCell.isSelected && self.secondTermCell.isSelected && self.acceptCell.isSelected {
                self.confirmBtn.isEnabled = true
            }
        }
        firstTermCell.selectCallback = didSelectCallback
        secondTermCell.selectCallback = didSelectCallback
        acceptCell.selectCallback = didSelectCallback
    }
    
    private func addSubviews() {
        view.addSubview(scrollView)
        scrollView.addSubview(titleLabel)
        scrollView.addSubview(infoLabel)
        scrollView.addSubview(firstTermCell)
        scrollView.addSubview(secondTermCell)
        view.addSubview(container)
        container.addSubview(acceptCell)
        container.addSubview(confirmBtn)
    }
    
    private func addConstraints() {
        scrollView.constrain([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),    scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor) ])
        titleLabel.constrain([
            titleLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: C.padding[4]),
            titleLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -C.padding[4]) ])
        infoLabel.constrain([
            infoLabel.centerXAnchor.constraint(equalTo: titleLabel.centerXAnchor),
            infoLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: C.padding[2]),
            infoLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -C.padding[4]) ])
        firstTermCell.constrain([
            firstTermCell.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: C.padding[2]),
            firstTermCell.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: C.padding[4]),
            firstTermCell.trailingAnchor.constraint(equalTo: view.trailingAnchor) ])
        secondTermCell.constrain([
            secondTermCell.leadingAnchor.constraint(equalTo: firstTermCell.leadingAnchor),
            secondTermCell.topAnchor.constraint(equalTo: firstTermCell.bottomAnchor, constant: C.padding[4]),
            secondTermCell.trailingAnchor.constraint(equalTo: view.trailingAnchor) ])
        acceptCell.constrain([
            acceptCell.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: C.padding[2]),
            acceptCell.topAnchor.constraint(equalTo: container.topAnchor, constant: C.padding[2]),
            acceptCell.trailingAnchor.constraint(equalTo: container.trailingAnchor) ])
        confirmBtn.constrain([
            confirmBtn.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            confirmBtn.topAnchor.constraint(equalTo: acceptCell.bottomAnchor, constant: C.padding[2]),
            confirmBtn.widthAnchor.constraint(equalTo: container.widthAnchor, constant: -C.padding[10]),
            confirmBtn.constraint(.height, constant: C.Sizes.buttonHeight),
            confirmBtn.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -C.padding[4])])
        container.constrain([
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            //container.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1/5),
            container.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor) ])
    }
    
    @objc func confirmTaped() {
        Store.perform(action: HideStartFlow())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ConfirmationTermsUseVC : UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard didViewAppear else { return } //We don't want to be doing an stretchy header stuff during interactive pop gestures
    }
}
