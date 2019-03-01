//
//  AddressBookVC.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2016-11-16.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit
import Core
import MachO

let addressBookHeaderHeight: CGFloat = E.isIPhoneXOrLater ? 90 : 67.0
let addressBookFooterHeight: CGFloat = 67.0

enum AddressBookType: Int {
    case normal
    case select
}

class AddressBookVC : UIViewController, Subscriber {

    //MARK: - Public
    
    init(walletManager: WalletManager, addressBookType: AddressBookType? = .normal, callback: ((String) -> Void)? = nil) {
        self.walletManager = walletManager
        self.headerView = AddressBookHeaderView(title: S.AddressBook.title)
        self.footerView = AddressBookFooterView()
        self.addressBookType = addressBookType!
        self.didSelectAddress = callback
        super.init(nibName: nil, bundle: nil)
        self.adressBookTableVC = AdressBookTableVC(addressBookType: addressBookType, didSelectAddress: didSelectAddress, didEditAddress: didEditAddress)
        
        footerView.addAddressCallback     = {
            Store.perform(action: RootModalActions.Present(modal: .addressBook(currency: walletManager.currency, initialAddress: nil, type: .add, callback: {
            self.adressBookTableVC.setupData()
        }))) }
        footerView.receiveCallback  = {
            Store.perform(action: RootModalActions.Present(modal: .receive(currency: walletManager.currency, isRequestAmountVisible: true, initialAddress: nil)))
        }
    }

    //MARK: - Private
    private let walletManager: WalletManager
    private let headerView: AddressBookHeaderView
    private let footerView: AddressBookFooterView
    private let transitionDelegate = ModalTransitionDelegate(type: .transactionDetail)
    private var adressBookTableVC: AdressBookTableVC!
    private var isLoginRequired = false
    private let headerContainer = UIView()
    private var addressBookType: AddressBookType = .normal
    private let didSelectAddress: ((String) -> Void)?
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
        addAddressBookView()
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
        view.addSubview(footerView)
    }

    private func addConstraints() {
        headerContainer.constrainTopCorners(height: addressBookHeaderHeight)
        headerView.constrain(toSuperviewEdges: nil)

        if #available(iOS 11.0, *) {
            footerView.constrain([
                footerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
                footerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: -C.padding[1]),
                footerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: C.padding[1]),
                footerView.heightAnchor.constraint(equalToConstant: addressBookType == .select ? 0 : addressBookFooterHeight)
                ])
        } else {
            footerView.constrain([
                footerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                footerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -C.padding[1]),
                footerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: C.padding[1]),
                footerView.heightAnchor.constraint(equalToConstant: addressBookFooterHeight)
                ])
        }
    }

    private func setInitialData() {

    }

    private func addAddressBookView() {
        view.backgroundColor = .whiteTint
        addChild(adressBookTableVC, layout: {
            if #available(iOS 11.0, *) {
                adressBookTableVC.view.constrain([
                    adressBookTableVC.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                adressBookTableVC.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
                adressBookTableVC.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                adressBookTableVC.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
                ])
            } else {
                adressBookTableVC.view.constrain(toSuperviewEdges: nil)
            }
        })
    }
    
    private func didSelectAddress(allAddress: [AddressBook], selectedIndex: Int) -> Void {
        switch addressBookType {
        case .normal:
            Store.perform(action: RootModalActions.Present(modal: .sendWithAddress(currency: walletManager.currency, initialAddress: allAddress[selectedIndex].address)))
            break
        case .select:
            didSelectAddress!(allAddress[selectedIndex].address)
            dismiss(animated: true, completion: nil)
            break
        }
    }
    
    private func didEditAddress(addressBook: AddressBook) -> Void {
        Store.perform(action: RootModalActions.Present(modal: .addressBook(currency: walletManager.currency, initialAddress: addressBook.address, type: .update, callback: {
            self.adressBookTableVC.setupData()
        })))
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

extension AddressBookVC : ModalDisplayable {
    var faqArticleId: String? {
        return nil
    }
    
    var modalTitle: String {
        return "\(S.AddressBook.title)"
    }
}
