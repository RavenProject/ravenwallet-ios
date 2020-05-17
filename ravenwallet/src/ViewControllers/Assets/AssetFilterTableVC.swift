//
//  AssetFilterTableVC.swift
//  Ravencoin
//
//  Created by Austin Hill on 5/17/20.
//  Copyright © 2020 Medici Ventures. All rights reserved.
//

import UIKit

class AssetFilterTableVC: UITableViewController {
    
    enum Section: Int, CaseIterable {
        case inList = 0
        case excludedFromList = 1
        
        init?(for indexPath: IndexPath) {
            if let section = Section(rawValue: indexPath.section) {
                self = section
            }else {
                return nil
            }
        }
        
        var footerHeight: CGFloat {
            return 40
        }
    }
    
    internal var adapter: AssetFilterAdapterProtocol! {
        didSet {
            tableView.reloadData()
        }
    }
    
    private let emptyMessage = UILabel.wrapping(font: .customBody(size: 16.0), color: .grayTextTint)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(AssetFilterCell.self, forCellReuseIdentifier: AssetFilterCell.reuseIdentifier)

        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 60.0
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .whiteTint
        tableView.isEditing = true

        emptyMessage.textAlignment = .center
        emptyMessage.text = S.Asset.emptyMessage
        
        tableView.setEditing(false, animated: false)
        
        setContentInset()
    }
}

// MARK: - Styling
extension AssetFilterTableVC {
    
    private func setContentInset() {
        let insets = UIEdgeInsets(top: manageAssetHeaderHeight - 64.0 - (E.isIPhoneXOrLater ? 28.0 : 0.0), left: 0, bottom: C.padding[2], right: 0)
        tableView.contentInset = insets
        tableView.scrollIndicatorInsets = insets
    }
    
    private func getFooter(for section: Section) -> UIView? {
        let footerText: String
        
        switch section {
        case .inList:
            guard adapter.includedList.count == 0 else { return nil }
            footerText = adapter.emptyListText()
        case .excludedFromList:
            guard adapter.excludedList.count == 0 else { return nil }
            footerText = S.Asset.emptyMessage
        }
        
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: section.footerHeight))
        footerView.backgroundColor = UIColor.white
        
        let emptyMessage = UILabel.wrapping(font: .customBody(size: 16.0), color: .grayTextTint)
        footerView.addSubview(emptyMessage)
        emptyMessage.text = footerText
        emptyMessage.textAlignment = .center
        
        emptyMessage.constrain([
            emptyMessage.centerXAnchor.constraint(equalTo: footerView.centerXAnchor),
            emptyMessage.centerYAnchor.constraint(equalTo: footerView.centerYAnchor),
            emptyMessage.widthAnchor.constraint(equalTo: footerView.widthAnchor, constant: -C.padding[2]) ])
        
        return footerView
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let section = Section(rawValue: section) else { return nil }
        
        switch section {
        case .inList:
            return adapter.titleForList()
            
        case .excludedFromList:
            return S.Asset.availableAssets
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let section = Section(rawValue: section) else { return nil }
        
        return getFooter(for: section)
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard let section = Section(rawValue: section) else { return 0 }
        
        return getFooter(for: section)?.bounds.height ?? 0.0
    }
}

// MARK: - Data source
extension AssetFilterTableVC {

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
        guard let section = Section(rawValue: section) else { return 0 }
        
        switch section {
        case .inList:
            return adapter.includedList.count
            
        case .excludedFromList:
            return adapter.excludedList.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AssetFilterCell.reuseIdentifier, for: indexPath) as! AssetFilterCell
        
        guard let section = Section(for: indexPath) else { return cell }
        
        let assetName: String
        
        switch section {
        case .inList:
            assetName = adapter.includedList[indexPath.row]
            
        case .excludedFromList:
            assetName = adapter.excludedList[indexPath.row]
        }
        
        cell.assetName = assetName
        return cell
    }
}

// MARK: - Interaction
extension AssetFilterTableVC {

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let section = Section(for: indexPath) else { return }
        
        switch section {
        case .inList:

            let assetName = adapter.includedList[indexPath.row]
            adapter.removeFromList(assetName)
            tableView.reloadData()
            
        case .excludedFromList:
            let assetName = adapter.excludedList[indexPath.row]
            adapter.addToList(assetName)
            tableView.reloadData()
        }
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        guard let section = Section(for: indexPath) else { return false}
        switch section {
        case .inList: return true
        case .excludedFromList: return false
        }
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard let section = Section(for: indexPath) else { return }
        
        if editingStyle == .delete {
            // Delete the row from the data source
            if section == .inList {
                adapter.removeFromList(adapter.includedList[indexPath.row])
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
}
