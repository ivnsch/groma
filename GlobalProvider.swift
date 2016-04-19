//
//  GlobalProvider.swift
//  shoppin
//
//  Created by ischuetz on 28/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

// Cross-provider services
protocol GlobalProvider {

    // isMathSync: If we are doing a sync because we received a websocket notification of another user (a user we share something with) having done a sync.
    func sync(isMatchSync: Bool, handler: ProviderResult<SyncResult> -> Void)
    
    func clearAllData(handler: ProviderResult<Any> -> Void)
    
    func fullDownload(handler: ProviderResult<SyncResult> -> Void)
}
