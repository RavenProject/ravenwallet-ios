//
//  TxDetailDataSource.swift
//  ravenwallet
//
//  Created by Ehsan Rezaie on 2017-12-20.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit

class TxDetailDataSource: NSObject {
    
    // MARK: - Types
    
    enum Field: String {
        case amount
        case status
        case timestamp
        case address
        case startingBalance
        case endingBalance
        case blockHeight
        case transactionId
        
        var cellType: UITableViewCell.Type {
            switch self {
            case .amount:
                return TxAmountCell.self
            case .status:
                return TxStatusCell.self
            case .address, .transactionId:
                return TxAddressCell.self
            default:
                return TxLabelCell.self
            }
        }
        
        func registerCell(forTableView tableView: UITableView) {
            tableView.register(cellType, forCellReuseIdentifier: self.rawValue)
        }
    }
    
    // MARK: - Vars
    
    fileprivate var fields: [Field]
    fileprivate let viewModel: TxDetailViewModel
    
    // MARK: - Init
    
    init(viewModel: TxDetailViewModel) {
        self.viewModel = viewModel
        
        fields = [
            .amount,
            .status,
            .timestamp,
            .address,
            .startingBalance,
            .endingBalance,
            .blockHeight,
            .transactionId
        ]
        
        if let tx = viewModel.tx as? RvnTransaction {
            if AssetValidator.shared.checkInvalidAsset(asset: tx.asset) {
                fields = [
                    .amount,
                    .status,
                    .timestamp,
                    .address,
                    .blockHeight,
                    .transactionId
                ]
            }
        }
        
        if viewModel.status == .complete, let index = fields.index(of: .status) {
            fields.remove(at: index)
        }
    }
    
    func registerCells(forTableView tableView: UITableView) {
        fields.forEach { $0.registerCell(forTableView: tableView) }
    }
    
    fileprivate func title(forField field: Field) -> String {
        switch field {
        case .status:
            return S.TransactionDetails.statusHeader
        case .address:
            return viewModel.addressHeader
        case .startingBalance:
            return S.TransactionDetails.startingBalanceHeader
        case .endingBalance:
            return S.TransactionDetails.endingBalanceHeader
        case .blockHeight:
            return S.TransactionDetails.blockHeightLabel
        case .transactionId:
            return S.TransactionDetails.txHashHeader
            
        default:
            return ""
        }
    }
}

// MARK: -
extension TxDetailDataSource: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fields.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let field = fields[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: field.rawValue,
                                                 for: indexPath)
        
        if let rowCell = cell as? TxDetailRowCell {
            rowCell.title = title(forField: field)
        }

        switch field {
        case .amount:
            let amountCell = cell as! TxAmountCell
            amountCell.set(viewModel: viewModel)
            break
    
        case .status:
            let statusCell = cell as! TxStatusCell
            statusCell.set(txInfo: viewModel)
            
        case .timestamp:
            let labelCell = cell as! TxLabelCell
            labelCell.titleLabel.attributedText = viewModel.timestampHeader
            labelCell.value = viewModel.longTimestamp
            
        case .address:
            let addressCell = cell as! TxAddressCell
            addressCell.set(address: viewModel.displayAddress)
            
        case .startingBalance:
            let labelCell = cell as! TxLabelCell
            labelCell.value = viewModel.startingBalance
            
        case .endingBalance:
            let labelCell = cell as! TxLabelCell
            labelCell.value = viewModel.endingBalance

        case .blockHeight:
            let labelCell = cell as! TxLabelCell
            labelCell.value = viewModel.blockHeight
            
        case .transactionId:
            let addressCell = cell as! TxAddressCell
            addressCell.set(address: viewModel.transactionHash)
        }
        
        return cell
    }
    
}
