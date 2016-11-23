//
//  RemoteHistoryItems.swift
//  shoppin
//
//  Created by ischuetz on 15/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

struct RemoteHistoryItems: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    
    let historyItems: [RemoteHistoryItem]
    let inventories: [RemoteInventoryWithDependencies]
    let productsCategories: [RemoteProductCategory]
    let products: [RemoteProduct]
    let users: [RemoteSharedUser]
    
    init?(representation: AnyObject) {
        guard
            let historyItemsObj = representation.value(forKeyPath: "historyItems") as? [AnyObject],
            let historyItems = RemoteHistoryItem.collection(historyItemsObj),
            let inventoriesObj = representation.value(forKeyPath: "inventories") as? [AnyObject],
            let inventories = RemoteInventoryWithDependencies.collection(inventoriesObj),
            let productsCategoriesObj = representation.value(forKeyPath: "productsCategories") as? [AnyObject],
            let productsCategories = RemoteProductCategory.collection(productsCategoriesObj),
            let productsObj = representation.value(forKeyPath: "products") as? [AnyObject],
            let products = RemoteProduct.collection(productsObj),
            let usersObj = representation.value(forKeyPath: "users") as? [AnyObject],
            let users = RemoteSharedUser.collection(usersObj)
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.historyItems = historyItems
        self.inventories = inventories
        self.productsCategories = productsCategories
        self.products = products
        self.users = users
    }
    
    // Make it conform because of type declaration in RemoteSyncResult (TODO better way?)
    // Only for compatibility purpose with sync result, which always sends result as an array. With RemoteListItems we get always 1 element array
    static func collection(_ representation: [AnyObject]) -> [RemoteHistoryItems]? {
        var listItems = [RemoteHistoryItems]()
        for obj in representation {
            if let listItem = RemoteHistoryItems(representation: obj) {
                listItems.append(listItem)
            } else {
                return nil
            }
            
        }
        return listItems
    }
    
    
    var debugDescription: String {
        return "{\(type(of: self)) historyItems: [\(historyItems)], inventories: [\(inventories)], productsCategories: [\(productsCategories)], products: [\(products)], users: [\(users)]}"
    }
}
