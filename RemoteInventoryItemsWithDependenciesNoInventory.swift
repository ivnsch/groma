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
    
    @objc required init?(response: NSHTTPURLResponse, representation: AnyObject) {
        
        let products = representation.valueForKeyPath("products") as! [AnyObject]
        self.products = RemoteProduct.collection(response: response, representation: products)
        
        let productsCategories = representation.valueForKeyPath("productsCategories") as! [AnyObject]
        self.productsCategories = RemoteProductCategory.collection(response: response, representation: productsCategories)
        
        let inventoryItems = representation.valueForKeyPath("items") as! [AnyObject]
        self.inventoryItems = RemoteInventoryItem.collection(response: response, representation: inventoryItems)
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) productsCategories: [\(productsCategories)], products: [\(products)], inventoryItems: [\(inventoryItems)}"
    }
}
