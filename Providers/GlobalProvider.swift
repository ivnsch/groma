//
//  GlobalProvider.swift
//  shoppin
//
//  Created by ischuetz on 28/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

// Cross-provider services
public protocol GlobalProvider {

    // isMathSync: If we are doing a sync because we received a websocket notification of another user (a user we share something with) having done a sync.
    func sync(_ isMatchSync: Bool, handler: @escaping (ProviderResult<SyncResult>) -> Void)
    
    func clearAllData(_ remote: Bool, handler: @escaping (ProviderResult<Any>) -> Void)
    
    func fullDownload(_ handler: @escaping (ProviderResult<SyncResult>) -> Void)
    
    func initContainers(handler: @escaping (ProviderResult<Any>) -> Void)
}
