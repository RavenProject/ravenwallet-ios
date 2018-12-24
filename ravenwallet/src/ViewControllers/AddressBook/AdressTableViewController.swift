//
//  AdressTableViewController.swift
//  ravenwallet
//
//  Created by Ben on 2016-11-16.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit
import SafariServices
import SwipeCellKit

private let promptDelay: TimeInterval = 0.6

class AdressTableViewController : UITableViewController, Subscriber, Trackable, SwipeTableViewCellDelegate {
    
    //MARK: - Public
    init(addressBookType: AddressBookType? = .normal, didSelectAddress: @escaping ([AddressBook], Int) -> Void, didEditAddress: @escaping (AddressBook) -> Void) {
        self.didSelectAddress = didSelectAddress
        self.didEditAddress = didEditAddress
        self.db = CoreDatabase()
        self.addressBookType = addressBookType!
        super.init(nibName: nil, bundle: nil)
    }
    
    let didSelectAddress: ([AddressBook], Int) -> Void
    let didEditAddress: (AddressBook) -> Void
    
    //MARK: - Private
    var db: CoreDatabase?
    
    private let addressListCellIdentifier = "AddressListCellIdentifier"
    private var allAddress: [AddressBook] = []
    private var addressBookType: AddressBookType = .normal
    private let emptyMessage = UILabel.wrapping(font: .customBody(size: 16.0), color: .grayTextTint)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(AddressListCell.self, forCellReuseIdentifier: addressListCellIdentifier)
        
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 60.0
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .whiteTint
        
        emptyMessage.textAlignment = .center
        emptyMessage.text = S.AddressBook.emptyMessage
        
        setContentInset()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setupData()
    }
    
    public func setupData() {
        let addressBookManager = AddressBookManager()
        addressBookManager.loadAddress(callBack: {addresses in
            self.allAddress = addresses
            self.reload()
        })
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
extension AdressTableViewController {
    
    private func addressListCell(tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: addressListCellIdentifier, for: indexPath)
        if let addressListCell = cell as? AddressListCell {
            (cell as! AddressListCell).delegate = self
            let addressBook = allAddress[indexPath.row]
            addressListCell.setAddress(addressBook)
        }
        return cell
    }
    
    internal func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard addressBookType == .normal else { return nil }
        guard orientation == .right else { return nil }
        let addressBook = allAddress[indexPath.row]

        let deleteAction = SwipeAction(style: .destructive, title: "Delete") { action, indexPath in
            let addressBookManager = AddressBookManager()
            addressBookManager.deleteAddressBook(address: addressBook.address, successCallBack: {
                Store.perform(action: Alert.Show(.addressDeleted))
                self.setupData()
            }, faillerCallBack: {
                DispatchQueue.main.async {
                    self.showAlert(title: S.AddressBook.errorBaseTitle, message: S.AddressBook.errorBaseMessage, buttonLabel: S.Button.ok)
                }
            })
        }
        
        let editAction = SwipeAction(style: .default, title: "Edit") { action, indexPath in
            self.didEditAddress(self.allAddress[indexPath.row])
        }
        
        // customize the action appearance
        deleteAction.backgroundColor = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
        editAction.backgroundColor = #colorLiteral(red: 0.7803494334, green: 0.7761332393, blue: 0.7967314124, alpha: 1)
        return [deleteAction, editAction]
    }
}
