//
//  RemotePullProvider.swift
//  shoppin
//
//  Created by ischuetz on 08/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

class RemotePullProvider {

    func pullListProducs(listUuid: String, srcUser: SharedUser, _ handler: RemoteResult<RemoteListItems> -> Void) {
        let params: [String: AnyObject] = ["listUuid": listUuid, "srcUser": RemoteListItemProvider().toRequestParams(srcUser)]
        RemoteProvider.authenticatedRequest(.POST, Urls.pullListProducts, params) {result in
            handler(result)
        }
    }
    
    func pullInventoryProducs(inventoryUuid: String, srcUser: SharedUser, _ handler: RemoteResult<RemoteProductsWithDependencies> -> Void) {
        let params: [String: AnyObject] = ["inventoryUuid": inventoryUuid, "srcUser": RemoteListItemProvider().toRequestParams(srcUser)]
        RemoteProvider.authenticatedRequest(.POST, Urls.pullInventoryProducts, params) {result in
            handler(result)
        }
    }
}