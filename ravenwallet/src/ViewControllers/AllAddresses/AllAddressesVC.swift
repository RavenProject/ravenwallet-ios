//
//  AccountViewController.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2016-11-16.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit
import Core

class AllAddressesVC : UIViewController, Subscriber {
    
    init(walletManager: WalletManager) {
        self.walletManager = walletManager
        self.headerView = AddressBookHeaderView(title: S.AllAddresses.title)
        super.init(nibName: nil, bundle: nil)
        self.allAddressesTableVC = AllAddressesTableVC(walletManager: walletManager, didSelectAddress: didSelectAddress)
    }

    //MARK: - Private
    private let walletManager: WalletManager
    private let headerView: AddressBookHeaderView
    private let transitionDelegate = ModalTransitionDelegate(type: .transactionDetail)
    private var allAddressesTableVC: AllAddressesTableVC!
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
        addAllAddressesView()
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

    private func addAllAddressesView() {
        view.backgroundColor = .whiteTint
        addChild(allAddressesTableVC, layout: {
            if #available(iOS 11.0, *) {
                allAddressesTableVC.view.constrain([
                    allAddressesTableVC.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                allAddressesTableVC.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
                allAddressesTableVC.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                allAddressesTableVC.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
                ])
            } else {
                allAddressesTableVC.view.constrain(toSuperviewEdges: nil)
            }
        })
    }
    
    private func didSelectAddress(allAddress: [String], selectedIndex: Int) -> Void {
        Store.perform(action: RootModalActions.Present(modal: .receive(currency: walletManager.currency, isRequestAmountVisible: false, initialAddress: allAddress[selectedIndex])))
    }

    override var prefersStatusBarHidden: Bool {
        return !shouldShowStatusBar
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AllAddressesVC : ModalDisplayable {
    var faqArticleId: String? {
        return nil
    }
    
    var modalTitle: String {
        return "\(S.AllAddresses.title)"
    }
}
