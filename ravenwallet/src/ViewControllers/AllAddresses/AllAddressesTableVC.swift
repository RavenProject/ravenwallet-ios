//
//  AllAddressesTableVC.swift
//  ravenwallet
//
//  Created by Ben on 2016-11-16.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit

class AllAddressesTableVC : UITableViewController, Subscriber, Trackable {
    
    //MARK: - Public
    init(walletManager: WalletManager, didSelectAddress: @escaping ([String], Int) -> Void) {
        self.walletManager = walletManager
        self.didSelectAddress = didSelectAddress
        super.init(nibName: nil, bundle: nil)
    }
    
    let didSelectAddress: ([String], Int) -> Void
    
    //MARK: - Private
    private let walletManager: WalletManager
    private let allAddressesListCellIdentifier = "AllAddressesListCellIdentifier"
    private var allAddress: [String] = []
    private let emptyMessage = UILabel.wrapping(font: .customBody(size: 16.0), color: .grayTextTint)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(AllAddressesListCell.self, forCellReuseIdentifier: allAddressesListCellIdentifier)
        
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 60.0
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .whiteTint
        
        emptyMessage.textAlignment = .center
        emptyMessage.text = S.AllAddresses.emptyMessage
        
        setContentInset()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setupData()
    }
    
    public func setupData() {
        self.allAddress = (self.walletManager.wallet?.usedAddresses)!
        self.reload()
    }
    
    private func setContentInset() {
        let insets = UIEdgeInsets(top: addressBookHeaderHeight - 64.0 - (E.isIPhoneXOrLater ? 28.0 : 0.0), left: 0, bottom: addressBookFooterHeight + C.padding[2], right: 0)
        tableView.contentInset = insets
        tableView.scrollIndicatorInsets = insets
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allAddress.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return addressListCell(tableView: tableView, indexPath: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        didSelectAddress(allAddress, indexPath.row)
    }
    
    private func reload() {
        tableView.reloadData()
        if allAddress.count == 0 {
            if emptyMessage.superview == nil {
                tableView.addSubview(emptyMessage)
                emptyMessage.constrain([
                    emptyMessage.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
                    emptyMessage.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -addressBookHeaderHeight),
                    emptyMessage.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -C.padding[2]) ])
            }
        } else {
            emptyMessage.removeFromSuperview()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//MARK: - Cell Builders
extension AllAddressesTableVC {
    
    private func addressListCell(tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: allAddressesListCellIdentifier, for: indexPath)
        if let allAddressesListCell = cell as? AllAddressesListCell {
            let address = allAddress[indexPath.row]
            allAddressesListCell.setAddress(address)
        }
        return cell
    }
    
}
