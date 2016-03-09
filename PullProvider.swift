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

    func pullListProducs(listUuid: String, srcUser: SharedUser, _ handler: ProviderResult<[ListItem]> -> Void)
    
    func pullInventoryProducs(listUuid: String, srcUser: SharedUser, _ handler: ProviderResult<Any> -> Void)
}
