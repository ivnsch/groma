//
//  RemoteInventoryItemsWithHistoryAndDependencies.swift
//  shoppin
//
//  Created by ischuetz on 26/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

struct RemoteInventoryItemsWithDependencies: ResponseObjectSerializable, CustomDebugStringConvertible {
    
    let inventoryItems: [RemoteInventoryItem]
    let products: [RemoteProduct]
    let productsCategories: [RemoteProductCategory]
    let inventories: [RemoteInventoryWithDependencies]
    
    init?(representation: AnyObject) {
        guard
            let inventoryItemsObj = representation.value(forKeyPath: "inventoryItems") as? [AnyObject],
            let inventoryItems = RemoteInventoryItem.collection(inventoryItemsObj),
            let productsObj = representation.value(forKeyPath: "products") as? [AnyObject],
            let products = RemoteProduct.collection(productsObj),
            let productsCategoriesObj = representation.value(forKeyPath: "productsCategories") as? [AnyObject],
            let productsCategories = RemoteProductCategory.collection(productsCategoriesObj),
            let inventoriesObj = representation.value(forKeyPath: "inventories") as? [AnyObject],
            let inventories = RemoteInventoryWithDependencies.collection(inventoriesObj)
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.inventoryItems = inventoryItems
        self.products = products
        self.productsCategories = productsCategories
        self.inventories = inventories
    }
    
    var debugDescription: String {
        return "{\(type(of: self)) inventoryItems: \(inventoryItems), products: \(products), productsCategories: \(productsCategories), inventories: \(inventories)}"
    }
}
