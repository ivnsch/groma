//
//  RemoteInventoryItemsWithHistoryAndDependencies.swift
//  shoppin
//
//  Created by ischuetz on 26/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

struct RemoteInventoryItemsWithHistoryAndDependencies: ResponseObjectSerializable, CustomDebugStringConvertible {
    
    let inventoryItems: [RemoteInventoryItem]
    let historyItems: [RemoteHistoryItem]
    let products: [RemoteProduct]
    let productsCategories: [RemoteProductCategory]
    let inventories: [RemoteInventoryWithDependencies]
    let users: [RemoteSharedUser]
    
    // TODO After porting to Swift 2.0 catch exception in these initializers and show msg to client accordingly, or don't use force unwrap
    // if server for some reason doesn't send a field the app currently crashes
    init?(representation: AnyObject) {
        guard
            let inventoryItemsObj = representation.valueForKeyPath("inventoryItems"),
            let inventoryItems = RemoteInventoryItem.collection(inventoryItemsObj),
            let historyItemsObj = representation.valueForKeyPath("historyItems"),
            let historyItems = RemoteHistoryItem.collection(historyItemsObj),
            let productsObj = representation.valueForKeyPath("products"),
            let products = RemoteProduct.collection(productsObj),
            let productsCategoriesObj = representation.valueForKeyPath("productsCategories"),
            let productsCategories = RemoteProductCategory.collection(productsCategoriesObj),
            let inventoriesObj = representation.valueForKeyPath("inventories"),
            let inventories = RemoteInventoryWithDependencies.collection(inventoriesObj),
            let usersObj = representation.valueForKeyPath("users"),
            let users = RemoteSharedUser.collection(usersObj)
            else {
                QL4("Invalid json: \(representation)")
                return nil}

        self.inventoryItems = inventoryItems
        self.historyItems = historyItems
        self.products = products
        self.productsCategories = productsCategories
        self.inventories = inventories
        self.users = users
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) inventoryItems: \(inventoryItems), historyItems: \(historyItems), products: \(products), productsCategories: \(productsCategories), inventories: \(inventories), users: \(users)}"
    }
}