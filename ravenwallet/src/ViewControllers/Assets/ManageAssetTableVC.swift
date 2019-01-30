//
//  ManageAssetTableVC.swift
//  ravenwallet
//
//  Created by Bendnaiba on 2016-11-16.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit
import SafariServices

class ManageAssetTableVC : UITableViewController, Subscriber, Trackable {
    
    //MARK: - Public
    init() {
        self.db = CoreDatabase()
        super.init(nibName: nil, bundle: nil)
    }
    
    //MARK: - Private
    var db: CoreDatabase?
    
    private var allAssets: [Asset] = []
    
    private let emptyMessage = UILabel.wrapping(font: .customBody(size: 16.0), color: .grayTextTint)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(AssetManageCell.self, forCellReuseIdentifier: AssetManageCell.cellIdentifier)

        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 60.0
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .whiteTint
        tableView.isEditing = true

        emptyMessage.textAlignment = .center
        emptyMessage.text = S.Asset.emptyMessage
        
        setContentInset()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setupData()
    }
    
    public func setupData() {
        allAssets = AssetManager.shared.assetList
        self.reload()
    }
    
    private func setContentInset() {
        let insets = UIEdgeInsets(top: manageAssetHeaderHeight - 64.0 - (E.isIPhoneXOrLater ? 28.0 : 0.0), left: 0, bottom: C.padding[2], right: 0)
        tableView.contentInset = insets
        tableView.scrollIndicatorInsets = insets
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allAssets.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return assetManageCell(tableView: tableView, indexPath: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65.0
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        assetManageCell(tableView, moveRowAt: sourceIndexPath, to: destinationIndexPath)
    }
    
    private func reload() {
        tableView.reloadData()
        if allAssets.count == 0 {
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
extension ManageAssetTableVC {
    
    private func assetManageCell(tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AssetManageCell.cellIdentifier, for: indexPath)
        if let assetManageCell = cell as? AssetManageCell {
            let asset = allAssets[indexPath.row]
            let viewModel = AssetListViewModel(asset: asset)
            assetManageCell.set(viewModel: viewModel)
        }
        return cell
    }
    
    private func assetManageCell(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let rowToMove = allAssets[sourceIndexPath.row]
        allAssets.remove(at: sourceIndexPath.row)
        allAssets.insert(rowToMove, at: destinationIndexPath.row)
        AssetManager.shared.updateAssetOrder(assets: allAssets)
    }
    

}
