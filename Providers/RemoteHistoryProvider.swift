//
//  RemoteHistoryProvider.swift
//  shoppin
//
//  Created by ischuetz on 12/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class RemoteHistoryProvider {

    func historyItems(_ inventory: DBInventory? = nil, handler: @escaping (RemoteResult<RemoteHistoryItems>) -> ()) {
        let params: [String: AnyObject] = inventory.map{["inventory": $0.uuid as AnyObject]} ?? [String: AnyObject]()
        RemoteProvider.authenticatedRequest(.get, Urls.historyItems, params) {result in
            handler(result)
        }
    }
    
    func removeHistoryItem(_ uuid: String, handler: @escaping (RemoteResult<NoOpSerializable>) -> ()) {
        RemoteProvider.authenticatedRequest(.delete, Urls.historyItem + "/\(uuid)") {result in
            handler(result)
        }
    }
    
    func removeHistoryItems(_ historyItemGroup: HistoryItemGroup, handler: @escaping (RemoteResult<NoOpSerializable>) -> ()) {
        removeHistoryItems(historyItemGroup.historyItems.map{$0.uuid}, handler: handler)
    }

    func removeHistoryItems(_ uuids: [String], handler: @escaping (RemoteResult<NoOpSerializable>) -> ()) {
        let params: [String: AnyObject] = ["uuids": uuids as AnyObject, "foo": "" as AnyObject] // foo -> server workaround for 1 element json
        RemoteProvider.authenticatedRequest(.post, Urls.historyItems, params) {result in
            handler(result)
        }
    }
    
    func toRequestParamsToRemove(_ historyItem: HistoryItem) -> [String: AnyObject] {
        var dict: [String: AnyObject] = ["uuid": historyItem.uuid as AnyObject]
        dict["lastUpdate"] = NSNumber(value: Int64(historyItem.lastServerUpdate) as Int64)
        return dict
    }
    
    fileprivate func toRequestParams(_ sharedUser: DBSharedUser) -> [String: AnyObject] {
        return [
            "email": sharedUser.email as AnyObject,
            "foo": "" as AnyObject // FIXME this is a workaround for serverside, for some reason case class & serialization didn't work with only one field
        ]
    }
}
