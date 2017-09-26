//
//  RemoteInventoryItemWithProduct.swift
//  shoppin
//
//  Created by ischuetz on 16/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation


// TODO review this, seems sync sends us redundant objects? This should not be the case - it should be like in list items response
struct RemoteInventoryItemWithProduct: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    let inventoryItem: RemoteInventoryItem
    let product: RemoteProduct
    let productCategory: RemoteProductCategory
    let inventory: RemoteInventory
    
    // TODO After porting to Swift 2.0 catch exception in these initializers and show msg to client accordingly, or don't use force unwrap
    // if server for some reason doesn't send a field the app currently crashes
    init?(representation: AnyObject) {
        guard
            let inventoryItemObj = representation.value(forKeyPath: "inventoryItem"),
            let inventoryItem = RemoteInventoryItem(representation: inventoryItemObj as AnyObject),
            let productCategoryObj = representation.value(forKeyPath: "productCategory"),
            let productCategory = RemoteProductCategory(representation: productCategoryObj as AnyObject),
            let productObj = representation.value(forKeyPath: "product"),
            let product = RemoteProduct(representation: productObj as AnyObject),
            let inventoryObj = representation.value(forKeyPath: "inventory"),
            let inventory = RemoteInventory(representation: inventoryObj as AnyObject)
            else {
                logger.e("Invalid json: \(representation)")
                return nil}
        
        self.inventoryItem = inventoryItem
        self.productCategory = productCategory
        self.product = product
        self.inventory = inventory
    }
    
    static func collection(_ representation: [AnyObject]) -> [RemoteInventoryItemWithProduct]? {
        var items = [RemoteInventoryItemWithProduct]()
        for obj in representation {
            if let item = RemoteInventoryItemWithProduct(representation: obj) {
                items.append(item)
            } else {
                return nil
            }
        }
        return items
    }
    
    var debugDescription: String {
        return "{\(type(of: self)) inventoryItem: \(inventoryItem), productCategory: \(productCategory), product: \(product), inventory: \(inventory)}"
    }
}
