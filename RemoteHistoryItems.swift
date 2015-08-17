//
//  RemoteHistoryItems.swift
//  shoppin
//
//  Created by ischuetz on 15/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

final class RemoteHistoryItems: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    
    let historyItems: [RemoteHistoryItem]
    let inventories: [RemoteInventory]
    let products: [RemoteProduct]
    let users: [RemoteSharedUser]
    
    @objc required init?(response: NSHTTPURLResponse, representation: AnyObject) {
        
        let historyItems = representation.valueForKeyPath("historyItems") as! [AnyObject]
        self.historyItems = RemoteHistoryItem.collection(response: response, representation: historyItems)

        let inventories = representation.valueForKeyPath("inventories") as! [AnyObject]
        self.inventories = RemoteInventory.collection(response: response, representation: inventories)
        
        let products = representation.valueForKeyPath("products") as! [AnyObject]
        self.products = RemoteProduct.collection(response: response, representation: products)
        
        let users = representation.valueForKeyPath("users") as! [AnyObject]
        self.users = RemoteSharedUser.collection(response: response, representation: users)
    }
    
    // Make it conform because of type declaration in RemoteSyncResult (TODO better way?)
    // Only for compatibility purpose with sync result, which always sends result as an array. With RemoteListItems we get always 1 element array
    @objc static func collection(response response: NSHTTPURLResponse, representation: AnyObject) -> [RemoteHistoryItems] {
        var listItems = [RemoteHistoryItems]()
        for obj in representation as! [AnyObject] {
            if let listItem = RemoteHistoryItems(response: response, representation: obj) {
                listItems.append(listItem)
            }
            
        }
        return listItems
    }
    
    
    var debugDescription: String {
        return "{\(self.dynamicType) historyItems: [\(self.historyItems)], inventories: [\(self.inventories)], products: [\(self.products)], users: [\(self.users)]}"
    }
}