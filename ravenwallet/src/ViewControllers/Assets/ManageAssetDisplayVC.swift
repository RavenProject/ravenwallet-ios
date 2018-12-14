//
//  AccountViewController.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2016-11-16.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit
import Core
import MachO

let manageAssetHeaderHeight: CGFloat = E.isIPhoneXOrLater ? 90 : 67.0

class ManageAssetDisplayVC : UIViewController, Subscriber {

    //MARK: - Public
    
    init() {
        self.headerView = ManageAssetHeaderView(title: S.Asset.settingTitle)
        super.init(nibName: nil, bundle: nil)
        self.manageAssetTableVC = ManageAssetTableVC()
    }
    
    //MARK: - Private
    private let headerView: ManageAssetHeaderView
    private let transitionDelegate = ModalTransitionDelegate(type: .transactionDetail)
    private var manageAssetTableVC: ManageAssetTableVC!
    private var isLoginRequired = false
    private let headerContainer = UIView()
    private var shouldShowStatusBar: Bool = true {
        didSet {
            if oldValue != shouldShowStatusBar {
                UIView.animate(withDuration: C.animationDuration) {
                    self.setNeedsStatusBarAppearanceUpdate()
                }
            }
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        addManageAssetView()
        addSubviews()
        addConstraints()
        setInitialData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        shouldShowStatusBar = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    // MARK: -
    
    private func setupNavigationBar() {
        
    }

    private func addSubviews() {
        view.addSubview(headerContainer)
        headerContainer.addSubview(headerView)
    }

    private func addConstraints() {
        headerContainer.constrainTopCorners(height: manageAssetHeaderHeight)
        headerView.constrain(toSuperviewEdges: nil)
    }

    private func setInitialData() {

    }

    private func addManageAssetView() {
        view.backgroundColor = .whiteTint
        addChild(manageAssetTableVC, layout: {
            if #available(iOS 11.0, *) {
                manageAssetTableVC.view.constrain([
                    manageAssetTableVC.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                manageAssetTableVC.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
                manageAssetTableVC.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                manageAssetTableVC.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
                ])
            } else {
                manageAssetTableVC.view.constrain(toSuperviewEdges: nil)
            }
        })
    }

    override var prefersStatusBarHidden: Bool {
        return !shouldShowStatusBar
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
