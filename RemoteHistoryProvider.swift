//
//  RemoteHistoryProvider.swift
//  shoppin
//
//  Created by ischuetz on 12/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import Alamofire

class RemoteHistoryProvider {

    func historyItems(inventory: Inventory, handler: RemoteResult<RemoteHistoryItems> -> ()) {
        AlamofireHelper.authenticatedRequest(.GET, Urls.historyItems, ["inventory": inventory.uuid]).responseMyObject {(request, _, result: RemoteResult<RemoteHistoryItems>, error) in
            handler(result)
        }
    }
    
    func syncHistoryItems(historyItemsSync: HistoryItemsSync, handler: RemoteResult<RemoteSyncResult<RemoteHistoryItems>> -> ()) {
        
        let inventoriesSyncDicts: [[String: AnyObject]] = historyItemsSync.historyItems.map {historyItem in
            
            let sharedUserDict: [String: AnyObject] = self.toRequestParams(historyItem.user)
            
            // TODO refactor with product dict in other places, put all the parameters dictionaries outside the providers
            let productDict = [
                "uuid": historyItem.product.uuid,
                "name": historyItem.product.name,
                "price": historyItem.product.price
            ]
            
            var dict: [String: AnyObject] = [
                "uuid": historyItem.uuid,
                "inventoryUuid": historyItem.inventory.uuid,
                "product": productDict,
                "quantity": historyItem.quantity,
                "addedDate": NSNumber(double: historyItem.addedDate.timeIntervalSince1970).longValue,
                "user": sharedUserDict
            ]
            
            if let lastServerUpdate = historyItem.lastServerUpdate {
                dict["lastUpdate"] = NSNumber(double: lastServerUpdate.timeIntervalSince1970).longValue
            }
            
            return dict
        }
        
        let toRemoveDicts = historyItemsSync.toRemove.map{self.toRequestParamsToRemove($0)}
        
        let dictionary: [String: AnyObject] = [
            "historyItems": inventoriesSyncDicts,
            "toRemove": toRemoveDicts
        ]
        
        print("sending: \(dictionary)")
        
        AlamofireHelper.authenticatedRequest(.POST, Urls.historyItemsSync, dictionary).responseMyObject { (request, _, result: RemoteResult<RemoteSyncResult<RemoteHistoryItems>>, error) in
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