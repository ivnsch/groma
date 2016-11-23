//
//  RemotePullProvider.swift
//  shoppin
//
//  Created by ischuetz on 08/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

class RemotePullProvider {

    func pullListProducs(_ listUuid: String, srcUser: SharedUser, _ handler: @escaping (RemoteResult<RemoteListItems>) -> Void) {
        let params: [String: AnyObject] = ["listUuid": listUuid as AnyObject, "srcUser": RemoteListItemProvider().toRequestParams(srcUser) as AnyObject]
        RemoteProvider.authenticatedRequest(.post, Urls.pullListProducts, params) {result in
            handler(result)
        }
    }
    
    func pullInventoryProducs(_ inventoryUuid: String, srcUser: SharedUser, _ handler: @escaping (RemoteResult<RemoteProductsWithDependencies>) -> Void) {
        let params: [String: AnyObject] = ["inventoryUuid": inventoryUuid as AnyObject, "srcUser": RemoteListItemProvider().toRequestParams(srcUser) as AnyObject]
        RemoteProvider.authenticatedRequest(.post, Urls.pullInventoryProducts, params) {result in
            handler(result)
        }
    }
}
