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
    
    init?(representation: AnyObject) {
        
        let historyItems = representation.valueForKeyPath("planItems") as! [AnyObject]
        self.planItems = RemoteHistoryItem.collection(historyItems)
        
        let inventories = representation.valueForKeyPath("inventory") as! [AnyObject]
        self.inventory = RemoteInventory(representation: inventories)!
        
        let productsCategories = representation.valueForKeyPath("productsCategories") as! [AnyObject]
        self.productsCategories = RemoteProductCategory.collection(productsCategories)
        
        let products = representation.valueForKeyPath("products") as! [AnyObject]
        self.products = RemoteProduct.collection(products)
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) planItems: [\(planItems)], inventory: [\(inventory)], productsCategories: [\(productsCategories)], products: [\(products)]]}"
    }
}