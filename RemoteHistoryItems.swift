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
    let productsCategories: [RemoteProductCategory]
    let products: [RemoteProduct]
    let users: [RemoteSharedUser]
    
    init?(representation: AnyObject) {
        
        let historyItems = representation.valueForKeyPath("historyItems") as! [AnyObject]
        self.historyItems = RemoteHistoryItem.collection(historyItems)
        
        let inventories = representation.valueForKeyPath("inventories") as! [AnyObject]
        self.inventories = RemoteInventory.collection(inventories)
        
        let productsCategories = representation.valueForKeyPath("productsCategories") as! [AnyObject]
        self.productsCategories = RemoteProductCategory.collection(productsCategories)

        let products = representation.valueForKeyPath("products") as! [AnyObject]
        self.products = RemoteProduct.collection(products)
        
        let users = representation.valueForKeyPath("users") as! [AnyObject]
        self.users = RemoteSharedUser.collection(users)
    }
    
    // Make it conform because of type declaration in RemoteSyncResult (TODO better way?)
    // Only for compatibility purpose with sync result, which always sends result as an array. With RemoteListItems we get always 1 element array
    static func collection(representation: AnyObject) -> [RemoteHistoryItems] {
        var listItems = [RemoteHistoryItems]()
        for obj in representation as! [AnyObject] {
            if let listItem = RemoteHistoryItems(representation: obj) {
                listItems.append(listItem)
            }
            
        }
        return listItems
    }
    
    
    var debugDescription: String {
        return "{\(self.dynamicType) historyItems: [\(self.historyItems)], inventories: [\(self.inventories)], productsCategories: [\(self.productsCategories)], products: [\(self.products)], users: [\(self.users)]}"
    }
}