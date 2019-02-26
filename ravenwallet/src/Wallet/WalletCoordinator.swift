//
//  WalletCoordinator.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2017-01-07.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import Foundation
import UIKit

//Coordinates the sync state of all wallet managers to
//display the activity indicator and control backtround tasks
class WalletCoordinator : Subscriber {

    // 24-hours until incremental rescan is reset
    private let incrementalRescanInterval: TimeInterval = (24*60*60)
    
    private var backgroundTaskId: UIBackgroundTaskIdentifier?
    private var reachability = ReachabilityMonitor()
    private var walletManager: WalletManager

    init(walletManager: WalletManager) {
        self.walletManager = walletManager
        addSubscriptions()
    }

    private func addSubscriptions() {
        reachability.didChange = { [weak self] isReachable in
            self?.reachabilityDidChange(isReachable: isReachable)
        }

        //Listen for sync state changes in all wallets
        Store.subscribe(self, selector: {
            if $0.walletState.syncState != $1.walletState.syncState {
                return true
            }
            return false
        }, callback: { [weak self] state in
            self?.syncStateDidChange(state: state)
        })

        Store.subscribe(self, name: .retrySync(Store.state.currency), callback: { _ in
            DispatchQueue.walletQueue.async {
                self.walletManager.peerManager?.connect()
            }
        })

        Store.subscribe(self, name: .rescan(Store.state.currency), callback: { _ in
            UserDefaults.hasRescannedBlockChain = true
            Store.perform(action: WalletChange(Store.state.currency).setRecommendScan(false))
            Store.perform(action: WalletChange(Store.state.currency).setIsRescanning(true))
            DispatchQueue.walletQueue.async {
                self.walletManager.peerManager?.rescan()
                self.walletManager.lastBlockHeight = 0
            }
        })
    }
    
    private func initiateRescan(currency: CurrencyDef) {
        guard let peerManager = self.walletManager.peerManager else { return assertionFailure() }
        peerManager.connect()

        // Rescans go deeper each time they are initiated within a 24-hour period.
        //
        // 1. Rescan goes from the last-sent tx.
        // 2. Rescan from peer manager's last checkpoint.
        // 3. Full rescan from block zero.
        //
        // Which type of rescan we perform is captured in `startingPoint`.
        
        var startingPoint = RescanState.StartingPoint.lastSentTx
        var blockHeight: UInt64?
        
        if let prevRescan = UserDefaults.rescanState(for: currency) {
            if abs(prevRescan.startTime.timeIntervalSinceNow) > incrementalRescanInterval {
                startingPoint = .lastSentTx
            } else {
                startingPoint = prevRescan.startingPoint.next
            }
        }
        
        if startingPoint == .lastSentTx {
            blockHeight = Store.state[currency].transactions
                .filter { $0.direction == .sent && $0.status == .complete }
                .map { $0.blockHeight }
                .max()
            if blockHeight == nil {
                startingPoint = startingPoint.next
            }
        }
        
        UserDefaults.setRescanState(for: currency, to: RescanState(startTime: Date(), startingPoint: startingPoint))
        
        // clear pending transactions
        //if let txs = Store.state[currency]?.transactions {
            DispatchQueue.main.async {
                Store.perform(action: WalletChange(currency).setTransactions(Store.state[currency].transactions.filter({ $0.status != .pending })))
            }
        //}
        
        switch startingPoint {
        case .lastSentTx:
            print("[\(currency.code)] initiating rescan from block #\(blockHeight!)")
            
            let scanFromBlock = UInt32(blockHeight!)
            
            // Reset the 'last sync'd block height' for the currency in question so that
            // the sync progress can be calculated correctly when we start sync'ing
            // from 'blockHeight,' which may be an earlier block. (see BtcWalletManager.updateProgress()).
            UserDefaults.setLastSyncedBlockHeight(height: scanFromBlock, for: currency)
            
            //BMEX peerManager.rescan(fromBlockHeight: scanFromBlock)
            
            // It's possible that the block we pass into rescan() will be newer than what
            // the peer manager actually ends up using as its starting point. Make sure
            // our last-sync'd-block reflects this otherwise our sync progress will be reported
            // incorrectly.
            let actualScanStartingBlock: UInt32 = (peerManager.lastBlockHeight)
            if actualScanStartingBlock != scanFromBlock {
                UserDefaults.setLastSyncedBlockHeight(height: actualScanStartingBlock, for: currency)
            }
            
        case .checkpoint:
            print("[\(currency.code)] initiating rescan from last checkpoint")
            //BMEX peerManager.rescanFromLatestCheckpoint()
            // Ensure sync progress calculated in BtcWalletManager.updateProgress() is based on
            // the checkpoint chosen by the peer manager.
            UserDefaults.setLastSyncedBlockHeight(height: (peerManager.lastBlockHeight), for: currency)
            
        case .walletCreation:
            print("[\(currency.code)] initiating rescan from earliestKeyTime")
            peerManager.rescan()
            // Ensure sync progress calculated in BtcWalletManager.updateProgress() is based on
            // the block from which it started the rescan.
            UserDefaults.setLastSyncedBlockHeight(height: (peerManager.lastBlockHeight), for: currency)
        }
    }

    private func syncStateDidChange(state: State) {
        if state.walletState.syncState == .success {
            endActivity()
            endBackgroundTask()
        } else {
            startActivity()
            startBackgroundTask()
        }
    }

    private func endBackgroundTask() {
        if let taskId = backgroundTaskId {
            UIApplication.shared.endBackgroundTask(taskId)
            backgroundTaskId = nil
        }
    }

    private func startBackgroundTask() {
        guard backgroundTaskId == nil else { return }
        backgroundTaskId = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            DispatchQueue.walletQueue.async {
                self.walletManager.peerManager?.disconnect()
            }
        })
    }

    private func reachabilityDidChange(isReachable: Bool) {
        if !isReachable {
            DispatchQueue.walletQueue.async {
                self.walletManager.peerManager?.disconnect()
                DispatchQueue.main.async {
                    Store.perform(action: WalletChange(Store.state.currency).setSyncingState(.connecting))
                }
            }
        }
    }

    private func startActivity() {
        UIApplication.shared.isIdleTimerDisabled = true
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }

    private func endActivity() {
        UIApplication.shared.isIdleTimerDisabled = false
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}

/// Rescan state of a currency - stored in UserDefaults
struct RescanState: Codable {
    enum StartingPoint: Int, Codable {
        // in order of latest to earliest
        case lastSentTx = 0
        case checkpoint
        case walletCreation
        
        var next: StartingPoint {
            return StartingPoint(rawValue: rawValue + 1) ?? .walletCreation
        }
    }
    
    var startTime: Date
    var startingPoint: StartingPoint = .lastSentTx
}
