//
//  RemotePlanItems.swift
//  shoppin
//
//  Created by ischuetz on 02/12/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

final class RemotePlanItems: ResponseObjectSerializable, CustomDebugStringConvertible {
    
    let planItems: [RemoteHistoryItem]
    let inventory: RemoteInventory
    let productsCategories: [RemoteProductCategory]
    let products: [RemoteProduct]
    
    init?(response: NSHTTPURLResponse, representation: AnyObject) {
        
        let historyItems = representation.valueForKeyPath("planItems") as! [AnyObject]
        self.planItems = RemoteHistoryItem.collection(response: response, representation: historyItems)
        
        let inventories = representation.valueForKeyPath("inventory") as! [AnyObject]
        self.inventory = RemoteInventory(response: response, representation: inventories)!
        
        let productsCategories = representation.valueForKeyPath("productsCategories") as! [AnyObject]
        self.productsCategories = RemoteProductCategory.collection(response: response, representation: productsCategories)
        
        let products = representation.valueForKeyPath("products") as! [AnyObject]
        self.products = RemoteProduct.collection(response: response, representation: products)
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) planItems: [\(planItems)], inventory: [\(inventory)], productsCategories: [\(productsCategories)], products: [\(products)]]}"
    }
}