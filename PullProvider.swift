//
//  PullProvider.swift
//  shoppin
//
//  Created by ischuetz on 08/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

// Separate provider to make it easy to mock, for testing where there's no server available
protocol PullProvider {

    func pullListProducs(_ listUuid: String, srcUser: DBSharedUser, _ handler: @escaping (ProviderResult<[ListItem]>) -> Void)
    
    func pullInventoryProducs(_ listUuid: String, srcUser: DBSharedUser, _ handler: @escaping (ProviderResult<Any>) -> Void)
}
