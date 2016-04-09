//
//  RemoteHistoryProvider.swift
//  shoppin
//
//  Created by ischuetz on 12/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class RemoteHistoryProvider {

    func historyItems(inventory: Inventory? = nil, handler: RemoteResult<RemoteHistoryItems> -> ()) {
        let params: [String: AnyObject] = inventory.map{["inventory": $0.uuid]} ?? [String: AnyObject]()
        RemoteProvider.authenticatedRequest(.GET, Urls.historyItems, params) {result in
            handler(result)
        }
    }
    
    func removeHistoryItem(uuid: String, handler: RemoteResult<NoOpSerializable> -> ()) {
        RemoteProvider.authenticatedRequest(.DELETE, Urls.historyItems + "/\(uuid)") {result in
            handler(result)
        }
    }
    
    func removeHistoryItems(historyItemGroup: HistoryItemGroup, handler: RemoteResult<NoOpSerializable> -> ()) {
        let params: [String: AnyObject] = ["uuids": historyItemGroup.historyItems.map{$0.uuid}, "foo": ""] // foo -> server workaround for 1 element json
        RemoteProvider.authenticatedRequest(.DELETE, Urls.historyItems, params) {result in
            handler(result)
        }
    }
    
    func toRequestParamsToRemove(historyItem: HistoryItem) -> [String: AnyObject] {
        var dict: [String: AnyObject] = ["uuid": historyItem.uuid]
        if let lastServerUpdate = historyItem.lastServerUpdate {
            dict["lastUpdate"] = NSNumber(double: lastServerUpdate.timeIntervalSince1970).longValue
        }
        return dict
    }
    
    private func toRequestParams(sharedUser: SharedUser) -> [String: AnyObject] {
        return [
            "email": sharedUser.email,
            "foo": "" // FIXME this is a workaround for serverside, for some reason case class & serialization didn't work with only one field
        ]
    }
}