//
//  TxListViewModel.swift
//  ravenwallet
//
//  Created by Ehsan Rezaie on 2018-01-13.
//  Copyright © 2018 breadwallet LLC. All rights reserved.
//

import UIKit
import Core

/// View model of a transaction in list view
struct TxListViewModel: TxViewModel {
    
    // MARK: - Properties
    
    let tx: Transaction
    
    var shortDescription: String {//TODO: BMEX to remove when shortAttributeDescription completed
        let isComplete = tx.status == .complete
        
        if let comment = comment, comment.count > 0, isComplete {
            return comment
        } else {
            var format: String
            switch tx.direction {
            case .sent, .moved:
                format = isComplete ? S.Transaction.sentTo : S.Transaction.sendingTo
            case .received:
                format = isComplete ? S.Transaction.receivedVia : S.Transaction.receivingVia
            }
            let address = tx.toAddress
            return String(format: format, address)
        }
    }
    
    var shortAttributeDescription: NSAttributedString {
        let isComplete = tx.status == .complete
        
        if let comment = comment, comment.count > 0, isComplete {
            return NSAttributedString(string: comment, attributes: [.foregroundColor: UIColor.lightGray])
        } else {
            let address = tx.toAddress
            var color = UIColor.lightGray
            var format: String
            switch tx.direction {
            case .sent, .moved:
                format = isComplete ? S.Transaction.sentTo : S.Transaction.sendingTo
                if(C.setBurnAddresses.contains(tx.toAddress)){
                    color = UIColor.sentRed
                    format = getShortSentDescription(isComplete: isComplete)
                    return NSAttributedString(string: format, attributes: [.foregroundColor: color])
                }
                return NSAttributedString(string: String(format: format, address), attributes: [.foregroundColor: color])
            case .received:
                format = isComplete ? S.Transaction.receivedVia : S.Transaction.receivingVia
                return NSAttributedString(string: String(format: format, address), attributes: [.foregroundColor: color])
            }
        }
    }

    func amount(rate: Rate) -> NSAttributedString {
        guard let tx = tx as? RvnTransaction else { return NSAttributedString(string: "") }
        let text = DisplayAmount(amount: Satoshis(rawValue: tx.amount),
                                 selectedRate: nil,
                                 minimumFractionDigits: nil,
                                 currency: tx.currency,
                                 negative: (tx.direction == .sent),
                                 locale: Locale(identifier: "fr_FR"),
                                 asset: tx.asset).description
        let color: UIColor = (tx.direction == .received) ? .receivedGreen : .sentRed
        
        return NSMutableAttributedString(string: text,
                                         attributes: [.foregroundColor: color])
    }
    
    func getShortSentDescription(isComplete:Bool) -> String {
        var shortSentDescription: String = isComplete ? S.Transaction.burn : S.Transaction.burning
        if tx.toAddress ==  C.strIssueAssetBurnAddress {
            shortSentDescription = isComplete ? S.Transaction.burnForCreation : S.Transaction.burningForCreation
        }
        else if tx.toAddress ==  C.strReissueAssetBurnAddress {
            shortSentDescription = isComplete ? S.Transaction.burnForReissue : S.Transaction.burningForReissue
        }
        return shortSentDescription
    }
}
