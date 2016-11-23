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
        if let reachability = Reachability.forInternetConnection() {
            let internetStatus = reachability.currentReachabilityStatus()
            QL1("internetStatus: \(internetStatus.rawValue)")
            return internetStatus != NetworkStatus.NotReachable

        } else {
            QL4("Reachability is nil, returning false")
            return false
        }
    }
    
    static var connectedAndLoggedIn: Bool {
//        return Providers.userProvider.hasLoginToken // testing (together with UserProviderMock)
        return ConnectionProvider.connected && Providers.userProvider.hasLoginToken
    }
}
