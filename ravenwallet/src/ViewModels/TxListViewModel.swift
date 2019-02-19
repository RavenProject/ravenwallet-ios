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
                let rvnTx = self.tx as? RvnTransaction
                if(C.setBurnAddresses.contains(tx.toAddress) && (rvnTx?.amount == C.creatAssetFee || rvnTx?.amount == C.manageAssetFee || rvnTx?.amount == C.uniqueAssetFee || rvnTx?.amount == C.subAssetFee)){
                    color = UIColor.sentRed
                    format = getShortSentBurnDescription(isComplete: isComplete)
                    return NSAttributedString(string: format, attributes: [.foregroundColor: color])
                }
                return NSAttributedString(string: String(format: format, address), attributes: [.foregroundColor: color])
            case .received:
                format = isComplete ? S.Transaction.receivedVia : S.Transaction.receivingVia
                return NSAttributedString(string: String(format: format, address), attributes: [.foregroundColor: color])
            }
        }
    }

    func amount(rate: Rate, isBtcSwapped: Bool) -> NSAttributedString {
        guard let tx = tx as? RvnTransaction else { return NSAttributedString(string: "") }
        let text = DisplayAmount(amount: Satoshis(rawValue: tx.amount),
                                 selectedRate: nil,
                                 minimumFractionDigits: nil,
                                 currency: tx.currency,
                                 negative: (tx.direction == .sent),
                                 locale: Locale(identifier: "fr_FR"),
                                 asset: tx.asset).description(isBtcSwapped: isBtcSwapped)
        let color: UIColor = (tx.direction == .received) ? .receivedGreen : .sentRed
        
        return NSMutableAttributedString(string: text,
                                         attributes: [.foregroundColor: color])
    }
    
    func getShortSentBurnDescription(isComplete:Bool) -> String {
        var shortSentDescription: String = isComplete ? S.Transaction.burn : S.Transaction.burning
        if tx.toAddress ==  C.strIssueAssetBurnAddress {
            shortSentDescription = isComplete ? S.Transaction.burnForCreation : S.Transaction.burningForCreation
        }
        else if tx.toAddress ==  C.strReissueAssetBurnAddress {
            shortSentDescription = isComplete ? S.Transaction.burnForReissue : S.Transaction.burningForReissue
        }
        else if tx.toAddress ==  C.strIssueSubAssetBurnAddress {
            shortSentDescription = isComplete ? S.Transaction.burnForSub : S.Transaction.burningForSub
        }
        else if tx.toAddress ==  C.strIssueUniqueAssetBurnAddress {
            shortSentDescription = isComplete ? S.Transaction.burnForUnique : S.Transaction.burningForUnique
        }
        return shortSentDescription
    }
}
