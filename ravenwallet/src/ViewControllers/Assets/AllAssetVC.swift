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

let allAssetHeaderHeight: CGFloat = E.isIPhoneXOrLater ? 90 : 67.0

class AllAssetVC : UIViewController, Subscriber {

    //MARK: - Public
    
    init(didSelectAsset: @escaping (Asset) -> Void) {
        self.headerView = AllAssetHeaderView(title: S.Asset.allAssetTitle)
        super.init(nibName: nil, bundle: nil)
        self.allAssetTableVC = AllAssetTableVC(didSelectAsset: didSelectAsset)
    }

    //MARK: - Private
    private let headerView: AllAssetHeaderView
    private var allAssetTableVC: AllAssetTableVC!
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
        addAllAssetView()
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
        headerContainer.constrainTopCorners(height: addressBookHeaderHeight)
        headerView.constrain(toSuperviewEdges: nil)
    }

    private func setInitialData() {

    }

    private func addAllAssetView() {
        view.backgroundColor = .whiteTint
        addChild(allAssetTableVC, layout: {
            if #available(iOS 11.0, *) {
                allAssetTableVC.view.constrain([
                    allAssetTableVC.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                allAssetTableVC.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
                allAssetTableVC.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                allAssetTableVC.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
                ])
            } else {
                allAssetTableVC.view.constrain(toSuperviewEdges: nil)
            }
        })
    }

    override var prefersStatusBarHidden: Bool {
        return !shouldShowStatusBar
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
