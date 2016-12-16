//
//  RemoteInventoryItemsWithDependenciesNoInventory.swift
//  shoppin
//
//  Created by ischuetz on 28/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

public struct RemoteInventoryItemsWithDependenciesNoInventory: ResponseObjectSerializable, CustomDebugStringConvertible {
    
    public let products: [RemoteProduct]
    public let productsCategories: [RemoteProductCategory]
    public let inventoryItems: [RemoteInventoryItem]
    
    public init?(representation: AnyObject) {
        guard
            let productsObj = representation.value(forKeyPath: "products") as? [AnyObject],
            let products = RemoteProduct.collection(productsObj),
            let productsCategoriesObj = representation.value(forKeyPath: "productsCategories") as? [AnyObject],
            let productsCategories = RemoteProductCategory.collection(productsCategoriesObj),
            let inventoryItemsObj = representation.value(forKeyPath: "items") as? [AnyObject],
            let inventoryItems = RemoteInventoryItem.collection(inventoryItemsObj)
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.products = products
        self.productsCategories = productsCategories
        self.inventoryItems = inventoryItems
    }
    
    public var debugDescription: String {
        return "{\(type(of: self)) productsCategories: [\(productsCategories)], products: [\(products)], inventoryItems: [\(inventoryItems)}"
    }
}
