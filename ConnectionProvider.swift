//
//  ConnectionProvider.swift
//  shoppin
//
//  Created by ischuetz on 20/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import Reachability

class ConnectionProvider {

    static var connected: Bool {
        let reachability = Reachability.reachabilityForInternetConnection()
        let internetStatus = reachability.currentReachabilityStatus()
        return internetStatus != .NotReachable
    }
    
    static var connectedAndLoggedIn: Bool {
        return ConnectionProvider.connected && Providers.userProvider.loggedIn
    }
}
