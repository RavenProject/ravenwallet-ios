//
//  AllAssetTableVC.swift
//  ravenwallet
//
//  Created by Ben on 2016-11-16.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit
import SafariServices

class AllAssetTableVC : UITableViewController, Subscriber, Trackable {
    
    //MARK: - Public
    init(didSelectAsset: @escaping (Asset) -> Void) {
        self.didSelectAsset = didSelectAsset
        super.init(nibName: nil, bundle: nil)
    }
    
    let didSelectAsset: (Asset) -> Void
    
    //MARK: - Private
    
    private let emptyMessage = UILabel.wrapping(font: .customBody(size: 16.0), color: .grayTextTint)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(AssetHomeCell.self, forCellReuseIdentifier: AssetHomeCell.cellIdentifier)
        
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 60.0
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .whiteTint
        
        emptyMessage.textAlignment = .center
        emptyMessage.text = S.Asset.allAssetEmptyMessage
        
        setContentInset()
        
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
    
    override func viewDidAppear(_ animated: Bool) {
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
        return AssetManager.shared.showedAssetList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return assetCell(tableView: tableView, indexPath: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return C.padding[2];
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        didSelectAsset(AssetManager.shared.showedAssetList[indexPath.row])
    }
    
    private func reload() {
        tableView.reloadData()
        if AssetManager.shared.showedAssetList.count == 0 {
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
extension AllAssetTableVC {
    
    private func assetCell(tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AssetHomeCell.cellIdentifier, for: indexPath)
        if let assetHomeCell = cell as? AssetHomeCell {
            let asset = AssetManager.shared.showedAssetList[indexPath.row]
            let viewModel = AssetListViewModel(asset: asset)
            assetHomeCell.set(viewModel: viewModel)
        }
        return cell
    }
}
