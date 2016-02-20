//
//  RemoteInventoryItemsWithDependenciesNoInventory.swift
//  shoppin
//
//  Created by ischuetz on 28/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

class RemoteInventoryItemsWithDependenciesNoInventory: ResponseObjectSerializable, CustomDebugStringConvertible {
    
    let products: [RemoteProduct]
    let productsCategories: [RemoteProductCategory]
    let inventoryItems: [RemoteInventoryItem]
    
    @objc required init?(representation: AnyObject) {
        
        let products = representation.valueForKeyPath("products") as! [AnyObject]
        self.products = RemoteProduct.collection(products)
        
        let productsCategories = representation.valueForKeyPath("productsCategories") as! [AnyObject]
        self.productsCategories = RemoteProductCategory.collection(productsCategories)
        
        let inventoryItems = representation.valueForKeyPath("items") as! [AnyObject]
        self.inventoryItems = RemoteInventoryItem.collection(inventoryItems)
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) productsCategories: [\(productsCategories)], products: [\(products)], inventoryItems: [\(inventoryItems)}"
    }
}
