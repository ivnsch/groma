//
//  ConnectionProvider.swift
//  shoppin
//
//  Created by ischuetz on 20/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import Reachability
import QorumLogs

class ConnectionProvider {

    static var connected: Bool {
        let reachability = Reachability.reachabilityForInternetConnection()
        let internetStatus = reachability.currentReachabilityStatus()
        QL1("internetStatus: \(internetStatus)")
        return internetStatus != .NotReachable
    }
    
    static var connectedAndLoggedIn: Bool {
        return ConnectionProvider.connected && Providers.userProvider.hasLoginToken
    }
}
