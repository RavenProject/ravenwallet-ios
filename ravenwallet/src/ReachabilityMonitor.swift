//
//  ReachabilityManager.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2017-06-17.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import Foundation
import SystemConfiguration

enum ReachabilityStatus {
    case notReachable
    case reachableViaWiFi
    case reachableViaWWAN
}

private func callback(reachability:SCNetworkReachability, flags: SCNetworkReachabilityFlags, info: UnsafeMutableRawPointer?) {
    guard let info = info else { return }
    let reachability = Unmanaged<ReachabilityMonitor>.fromOpaque(info).takeUnretainedValue()
    reachability.notify()
}

class ReachabilityMonitor : Trackable {

    init() {
        networkReachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, "google.com")
        start()
    }

    var didChange: ((Bool) -> Void)?

    private var networkReachability: SCNetworkReachability?
    private let reachabilitySerialQueue = DispatchQueue(label: "com.breadwallet.reachabilityQueue")

    func notify() {
        DispatchQueue.main.async {
            self.didChange?(self.isReachable)
            self.saveEvent(self.isReachable ? "reachability.isReachble" : "reachability.isNotReachable")
        }
    }

    var isReachable: Bool {
        return flags.contains(.reachable)
    }

    private func start() {
        var context = SCNetworkReachabilityContext()
        context.info = UnsafeMutableRawPointer(Unmanaged<ReachabilityMonitor>.passUnretained(self).toOpaque())
        guard let reachability = networkReachability else { return }
        SCNetworkReachabilitySetCallback(reachability, callback, &context)
        SCNetworkReachabilitySetDispatchQueue(reachability, reachabilitySerialQueue)
    }

    private var flags: SCNetworkReachabilityFlags {
        var flags = SCNetworkReachabilityFlags(rawValue: 0)
        if let reachability = networkReachability, withUnsafeMutablePointer(to: &flags, { SCNetworkReachabilityGetFlags(reachability, UnsafeMutablePointer($0)) }) == true {
            return flags
        }
        else {
            return []
        }
    }
    
    var currentReachabilityStatus: ReachabilityStatus {
        if flags.contains(.reachable) == false {
            // The target host is not reachable.
            return .notReachable
        }
        else if flags.contains(.isWWAN) == true {
            // WWAN connections are OK if the calling application is using the CFNetwork APIs.
            return .reachableViaWWAN
        }
        else if flags.contains(.connectionRequired) == false {
            // If the target host is reachable and no connection is required then we'll assume that you're on Wi-Fi...
            return .reachableViaWiFi
        }
        else if (flags.contains(.connectionOnDemand) == true || flags.contains(.connectionOnTraffic) == true) && flags.contains(.interventionRequired) == false {
            // The connection is on-demand (or on-traffic) if the calling application is using the CFSocketStream or higher APIs and no [user] intervention is needed
            return .reachableViaWiFi
        }
        else {
            return .notReachable
        }
    }
}
