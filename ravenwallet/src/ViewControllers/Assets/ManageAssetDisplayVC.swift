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
    
    //MARK: - Private
    private let headerView: ManageAssetHeaderView
    private let transitionDelegate = ModalTransitionDelegate(type: .transactionDetail)
    private var assetFilterListVC: AssetFilterTableVC!
    private var isLoginRequired = false
    private let headerContainer = UIView()
    
    private let filters: [AssetManager.AssetFilter] = [
        .blacklist,
        .whitelist
    ]
    private let filterSelectorView = UIView()
    private let filterSelectorControl: UISegmentedControl
    
    private let whitelistAdapter: WhitelistAdapter
    private let blacklistAdapter: BlacklistAdapter
    
    private var shouldShowStatusBar: Bool = true {
        didSet {
            if oldValue != shouldShowStatusBar {
                UIView.animate(withDuration: C.animationDuration) {
                    self.setNeedsStatusBarAppearanceUpdate()
                }
            }
        }
    }
    
    init() {
        self.headerView = ManageAssetHeaderView(title: S.Asset.settingTitle)
        self.assetFilterListVC = AssetFilterTableVC()
        self.whitelistAdapter = WhitelistAdapter(assetManager: AssetManager.shared)
        self.blacklistAdapter = BlacklistAdapter(assetManager: AssetManager.shared)
        
        // Filter setup
        self.filterSelectorControl = UISegmentedControl(items: filters.map({$0.displayString}))
        
        super.init(nibName: nil, bundle: nil)
        
        let assetFilter = AssetManager.shared.assetFilter
        filterSelectorControl.selectedSegmentIndex = filters.firstIndex(of: assetFilter)!
        filterSelectorControl.valueChanged = filterSelectorDidChange
        showFilterList(assetFilter)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//MARK: - UIViewController
extension ManageAssetDisplayVC {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addSubviews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        shouldShowStatusBar = true
    }
}

//MARK: - View Setup
extension ManageAssetDisplayVC {
    
    private func addSubviews() {
        
        // Style
        view.backgroundColor = .whiteTint
        
        // Header container
        view.addSubview(headerContainer)
        headerContainer.constrainTopCorners(height: manageAssetHeaderHeight)
        
        // Header
        headerContainer.addSubview(headerView)
        headerView.constrain(toSuperviewEdges: nil)
        
        // Selector container
        view.addSubview(filterSelectorView)
        filterSelectorView.constrain([
            filterSelectorView.topAnchor.constraint(equalTo: headerContainer.bottomAnchor),
            filterSelectorView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            filterSelectorView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            filterSelectorView.heightAnchor.constraint(equalToConstant: 40.0)
        ])
        
        // Selector
        filterSelectorView.addSubview(filterSelectorControl)
        filterSelectorControl.constrain([
            filterSelectorControl.rightAnchor.constraint(equalTo: filterSelectorView.rightAnchor, constant: -C.padding[1]),
            filterSelectorControl.centerYAnchor.constraint(equalTo: filterSelectorView.centerYAnchor),
            filterSelectorControl.leftAnchor.constraint(equalTo: filterSelectorView.leftAnchor, constant: C.padding[1]),
            filterSelectorControl.topAnchor.constraint(equalTo: filterSelectorView.topAnchor, constant: C.padding[1]),
            filterSelectorControl.bottomAnchor.constraint(equalTo: filterSelectorView.bottomAnchor, constant: -C.padding[1])
            
        ])
        
        // Filter list view controller
        addChild(assetFilterListVC, layout: {
            if #available(iOS 11.0, *) {
                assetFilterListVC.view.constrain([
                assetFilterListVC.view.topAnchor.constraint(equalTo: filterSelectorView.bottomAnchor),
                assetFilterListVC.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
                assetFilterListVC.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                assetFilterListVC.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
                ])
            } else {
                assetFilterListVC.view.constrain(toSuperviewEdges: nil)
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
    
    private func showFilterList(_ filter: AssetManager.AssetFilter) {
        switch filter {
        case .whitelist:
            self.assetFilterListVC.adapter = self.whitelistAdapter
        case .blacklist:
            self.assetFilterListVC.adapter = self.blacklistAdapter
        }
    }
}

//MARK: - Handlers
extension ManageAssetDisplayVC {
    func filterSelectorDidChange() {
        
        let index = filterSelectorControl.selectedSegmentIndex
        let filter = filters[index]
        
        AssetManager.shared.setAssetFilter(filter)
        
        showFilterList(filter)
    }
}
