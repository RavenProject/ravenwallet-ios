//
//  TransactionsTableViewController.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2016-11-16.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit
import SafariServices

class TransactionsTableViewController : UITableViewController, Subscriber, Trackable {

    //MARK: - Public
    init(walletManager: WalletManager, didSelectTransaction: @escaping ([Transaction], Int) -> Void) {
        self.walletManager = walletManager
        self.currency = walletManager.currency
        self.didSelectTransaction = didSelectTransaction
        self.isSwapped = Store.state.isSwapped
        super.init(nibName: nil, bundle: nil)
    }

    let didSelectTransaction: ([Transaction], Int) -> Void

    var filters: [TransactionFilter] = [] {
        didSet {
            transactions = filters.reduce(allTransactions, { $0.filter($1) })
            tableView.reloadData()
        }
    }

    //MARK: - Private
    private let walletManager: WalletManager
    private let currency: CurrencyDef
    
    private let headerCellIdentifier = "HeaderCellIdentifier"
    private let transactionCellIdentifier = "TransactionCellIdentifier"
    private var transactions: [Transaction] = []
    private var allTransactions: [Transaction] = [] {
        didSet { transactions = allTransactions }
    }
    private var isSwapped: Bool {
        didSet { reload() }
    }
    private var rate: Rate? {
        didSet { reload() }
    }
    private let emptyMessage = UILabel.wrapping(font: .customBody(size: 16.0), color: .grayTextTint)
    private let emptyImage = UIImageView(image: #imageLiteral(resourceName: "EmptyTxs"))

    private var currentPrompt: Prompt? {
        didSet {
            if currentPrompt != nil && oldValue == nil {
                tableView.beginUpdates()
                tableView.insertSections(IndexSet(integer: 0), with: .automatic)
                tableView.endUpdates()
            } else if currentPrompt == nil && oldValue != nil {
                tableView.beginUpdates()
                tableView.deleteSections(IndexSet(integer: 0), with: .automatic)
                tableView.endUpdates()
            }
        }
    }
    private var hasExtraSection: Bool {
        return (currentPrompt != nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(TxListCell.self, forCellReuseIdentifier: transactionCellIdentifier)
        tableView.register(TxListCell.self, forCellReuseIdentifier: headerCellIdentifier)

        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 60.0
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .whiteTint
        
        emptyMessage.textAlignment = .center
        emptyMessage.text = S.TransactionDetails.emptyMessage
        
        emptyImage.contentMode = .scaleAspectFit
        
        //setContentInset()

        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        Store.subscribe(self,
                        selector: { $0.isSwapped != $1.isSwapped },
                        callback: { self.isSwapped = $0.isSwapped })
        Store.subscribe(self,
                        selector: { $0[self.currency].currentRate != $1[self.currency].currentRate},
                        callback: {
                            self.rate = $0[self.currency].currentRate
        })
        Store.subscribe(self, selector: { $0[self.currency].maxDigits != $1[self.currency].maxDigits }, callback: {_ in
            self.reload()
        })
        
        Store.subscribe(self, selector: { $0[self.currency].recommendRescan != $1[self.currency].recommendRescan }, callback: { _ in
        })
                
        Store.subscribe(self, selector: {
            $0[self.currency].transactions != $1[self.currency].transactions
        },
                        callback: { state in
                            self.allTransactions = state[self.currency].transactions
                            self.reload()
        })
    }

    private func setContentInset() {
        let insets = UIEdgeInsets(top: accountHeaderHeight - 64.0 - (E.isIPhoneXOrLater ? 28.0 : 0.0), left: 0, bottom: accountFooterHeight + C.padding[2], right: 0)
        tableView.contentInset = insets
        tableView.scrollIndicatorInsets = insets
    }

    private func reload(txHash: String) {
        self.transactions.enumerated().forEach { i, tx in
            if tx.hash == txHash {
                DispatchQueue.main.async {
                    self.tableView.reload(row: i, section: self.hasExtraSection ? 1 : 0)
                }
            }
        }
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return hasExtraSection ? 2 : 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if hasExtraSection && section == 0 {
            return 1
        } else {
            return transactions.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if hasExtraSection && indexPath.section == 0 {
            return headerCell(tableView: tableView, indexPath: indexPath)
        } else {
            return transactionCell(tableView: tableView, indexPath: indexPath)
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if hasExtraSection && section == 1 {
            return C.padding[2]
        } else {
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if hasExtraSection && section == 1 {
            return UIView(color: .clear)
        } else {
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if hasExtraSection && indexPath.section == 0 { return }
        didSelectTransaction(transactions, indexPath.row)
    }

    private func reload() {
        tableView.reloadData()
        if transactions.count == 0 {
            if emptyMessage.superview == nil {
                tableView.addSubview(emptyMessage)
                emptyMessage.constrain([
                    emptyMessage.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
                    emptyMessage.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -accountHeaderHeight),
                    emptyMessage.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -C.padding[2]) ])
            }
            emptyMessage.isHidden = true
            if emptyImage.superview == nil {
                tableView.addSubview(emptyImage)
                emptyImage.constrain([
                    emptyImage.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
                    emptyImage.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -(accountHeaderHeight/2)),
                    emptyImage.widthAnchor.constraint(equalTo: view.widthAnchor) ])
            }
        } else {
            emptyMessage.removeFromSuperview()
            emptyImage.removeFromSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//MARK: - Cell Builders
extension TransactionsTableViewController {

    private func headerCell(tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: headerCellIdentifier, for: indexPath)
        if let containerCell = cell as? TxListCell {
            if let prompt = currentPrompt {
                containerCell.contentView.addSubview(prompt)
                prompt.constrain(toSuperviewEdges: nil)
            }
        }
        return cell
    }

    private func transactionCell(tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: transactionCellIdentifier, for: indexPath)
        if let transactionCell = cell as? TxListCell,
            let rate = rate {
            let viewModel = TxListViewModel(tx: transactions[indexPath.row])
            transactionCell.setTransaction(viewModel,
                                           isBtcSwapped: isSwapped,
                                           rate: rate,
                                           maxDigits: currency.state.maxDigits,
                                           isSyncing: currency.state.syncState != .success)
        }
        return cell
    }
}
