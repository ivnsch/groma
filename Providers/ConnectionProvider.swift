//
//  ConnectionProvider.swift
//  shoppin
//
//  Created by ischuetz on 20/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import Reachability


public class ConnectionProvider {

    public static var connected: Bool {
        if let reachability = Reachability.forInternetConnection() {
            let internetStatus = reachability.currentReachabilityStatus()
            logger.v("internetStatus: \(internetStatus.rawValue)")
            return internetStatus != NetworkStatus.NotReachable

        } else {
            logger.e("Reachability is nil, returning false")
            return false
        }
    }
    
    public static var connectedAndLoggedIn: Bool {
//        return Prov.userProvider.hasLoginToken // testing (together with UserProviderMock)
        return ConnectionProvider.connected && Prov.userProvider.hasLoginToken
    }
}
