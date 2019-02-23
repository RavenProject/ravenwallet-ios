//
//  AssetListTableView.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2017-12-04.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit

private let countToShowMore:Int = 3

class AssetListTableView: UITableViewController, Subscriber {

    var didSelectCurrency: ((CurrencyDef) -> Void)?
    var didSelectAsset: ((Asset) -> Void)?
    var didSelectShowMoreAsset: (() -> Void)?
    var didTapSecurity: (() -> Void)?
    var didTapSupport: (() -> Void)?
    var didTapSettings: (() -> Void)?
    var didTapCreateAsset: (() -> Void)?
    var didTapAddressBook: ((CurrencyDef) -> Void)?
    var didTapTutorial: (() -> Void)?

    // MARK: - Init
    
    init() {
        super.init(style: .grouped)
    }
    
    override func viewDidLoad() {
        tableView.backgroundColor = .whiteBackground
        tableView.register(HomeScreenCell.self, forCellReuseIdentifier: HomeScreenCell.cellIdentifier)
        tableView.register(AssetHomeCell.self, forCellReuseIdentifier: AssetHomeCell.cellIdentifier)
        tableView.register(ShowMoreCell.self, forCellReuseIdentifier: ShowMoreCell.cellIdentifier)
        
        tableView.register(MenuCell.self, forCellReuseIdentifier: MenuCell.cellIdentifier)
        tableView.separatorStyle = .none
        
        tableView.reloadData()
        
        
        Store.subscribe(self, selector: {
            var result = false
            let oldState = $0
            let newState = $1
            if oldState[$0.currency].balance != newState[$0.currency].balance
                || oldState[$0.currency].currentRate?.rate != newState[$0.currency].currentRate?.rate
                || oldState[$0.currency].maxDigits != newState[$0.currency].maxDigits {
                result = true
            }
            return result
        }, callback: { _ in
            self.tableView.reloadData()
        })
        //BMEX detect transactions changes
        Store.subscribe(self, selector: {
            $0[Store.state.currency].transactions != $1[Store.state.currency].transactions
        },
                        callback: { state in
                            AssetManager.shared.loadAsset { assets in
                                self.reload()
                            }
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.visibleCells.forEach {
            if let cell = $0 as? HomeScreenCell {
                cell.refreshAnimations()
            }
        }
        AssetManager.shared.loadAsset { assets in
            self.reload()
        }
    }
    
    func reload() {
        tableView.reloadData()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Data Source
    
    enum Section: Int {
        case wallet
        case asset
        case menu
    }
    
    enum Menu: Int {
        case createAsset
        case settings
        case addressBook
        case security
        case support
        case tutorial

        var content: (String, UIImage) {
            switch self {
            case .createAsset:
                return (S.MenuButton.createAsset, #imageLiteral(resourceName: "CreateAsset"))
            case .settings:
                return (S.MenuButton.settings, #imageLiteral(resourceName: "Settings"))
            case .addressBook:
                return (S.MenuButton.addressBook, #imageLiteral(resourceName: "AddressBook"))
            case .security:
                return (S.MenuButton.security, #imageLiteral(resourceName: "Shield"))
            case .support:
                return (S.MenuButton.support, #imageLiteral(resourceName: "Faq"))
            case .tutorial:
                return (S.MenuButton.tutorial, #imageLiteral(resourceName: "Faq"))
            }
        }
        
        static let allItems: [Menu] = [ .createAsset, .settings, .security, .support, .addressBook, .tutorial]
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else { return 0 }
        
        switch section {
        case .wallet:
            return 1
        case .asset:
            return AssetManager.shared.showedAssetList.count > 3 ? 4 : AssetManager.shared.showedAssetList.count
        case .menu:
            return Menu.allItems.count
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let section = Section(rawValue: indexPath.section) else { return 0 }

        switch section {
        case .wallet:
            return E.isIPhoneXOrLater ? 260.0 : 260.0
        case .asset:
            return 60.0
        case .menu:
            return 53.0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Section(rawValue: indexPath.section) else { return UITableViewCell() }
        
        switch section {
        case .wallet:
            let currency = Store.state.currency
            let viewModel = WalletListViewModel(currency: currency)
            let cell = tableView.dequeueReusableCell(withIdentifier: HomeScreenCell.cellIdentifier, for: indexPath) as! HomeScreenCell
            cell.set(viewModel: viewModel)
            return cell
            
        case .asset:
            if (indexPath.row == countToShowMore)
            {
                let cell = tableView.dequeueReusableCell(withIdentifier: ShowMoreCell.cellIdentifier, for: indexPath) as! ShowMoreCell
                return cell
            }else {
                let asset = AssetManager.shared.showedAssetList[indexPath.row]
                let viewModel = AssetListViewModel(asset: asset)
                let cell = tableView.dequeueReusableCell(withIdentifier: AssetHomeCell.cellIdentifier, for: indexPath) as! AssetHomeCell
                cell.set(viewModel: viewModel)
                return cell
            }
        case .menu:
            let cell = tableView.dequeueReusableCell(withIdentifier: MenuCell.cellIdentifier, for: indexPath) as! MenuCell
            guard let item = Menu(rawValue: indexPath.row) else { return cell }
            let content = item.content
            cell.set(title: content.0, icon: content.1)
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let section = Section(rawValue: section) else { return C.padding[2] }
        switch section {
        case .wallet:
            return 0
        case .asset:
            return AssetManager.shared.showedAssetList.count == 0 ? 0 : C.padding[1]
        case .menu:
            return C.padding[1]
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let section = Section(rawValue: section) else { return nil }
        switch section {
        case .wallet:
            return S.HomeScreen.portfolio
        case .asset:
            return S.HomeScreen.asset
        case .menu:
            return S.HomeScreen.admin
        
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView,
            let label = header.textLabel else { return }
        label.text = label.text?.capitalized
        label.textColor = .mediumGray
        label.font = .customBody(size: 12.0)
        header.tintColor = tableView.backgroundColor
    }
    
    // MARK: - Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let section = Section(rawValue: indexPath.section) else { return }
        
        switch section {
        case .wallet:
            didSelectCurrency?(Store.state.currency)
        case .asset:
            if (indexPath.row == countToShowMore)
            {
                didSelectShowMoreAsset?()
            }else {
                didSelectAsset?(AssetManager.shared.showedAssetList[indexPath.row])
            }
        case .menu:
            guard let item = Menu(rawValue: indexPath.row) else { return }
            switch item {
            case .createAsset:
                didTapCreateAsset?()
            case .settings:
                didTapSettings?()
            case .security:
                didTapSecurity?()
            case .support:
                didTapSupport?()
            case .addressBook:
                didTapAddressBook?(Store.state.currency)
            case .tutorial:
                didTapTutorial?()
            }
            
        
        }
    }
}
