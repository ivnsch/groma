//
//  RemoteInventoryItemsWithDependenciesNoInventory.swift
//  shoppin
//
//  Created by ischuetz on 28/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

struct RemoteInventoryItemsWithDependenciesNoInventory: ResponseObjectSerializable, CustomDebugStringConvertible {
    
    let products: [RemoteProduct]
    let productsCategories: [RemoteProductCategory]
    let inventoryItems: [RemoteInventoryItem]
    
    init?(representation: AnyObject) {
        guard
            let productsObj = representation.valueForKeyPath("products") as? [AnyObject],
            let products = RemoteProduct.collection(productsObj),
            let productsCategoriesObj = representation.valueForKeyPath("productsCategories") as? [AnyObject],
            let productsCategories = RemoteProductCategory.collection(productsCategoriesObj),
            let inventoryItemsObj = representation.valueForKeyPath("items") as? [AnyObject],
            let inventoryItems = RemoteInventoryItem.collection(inventoryItemsObj)
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.products = products
        self.productsCategories = productsCategories
        self.inventoryItems = inventoryItems
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) productsCategories: [\(productsCategories)], products: [\(products)], inventoryItems: [\(inventoryItems)}"
    }
}
