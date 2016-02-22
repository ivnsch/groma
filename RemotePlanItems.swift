//
//  RemotePlanItems.swift
//  shoppin
//
//  Created by ischuetz on 02/12/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

struct RemotePlanItems: ResponseObjectSerializable, CustomDebugStringConvertible {
    
    let planItems: [RemoteHistoryItem]
    let inventory: RemoteInventory
    let productsCategories: [RemoteProductCategory]
    let products: [RemoteProduct]
    
    init?(representation: AnyObject) {
        guard
            let planItemsObj = representation.valueForKeyPath("planItems") as? [AnyObject],
            let planItems = RemoteHistoryItem.collection(planItemsObj),
            let inventoriesObj = representation.valueForKeyPath("inventory") as? [AnyObject],
            let inventory = RemoteInventory(representation: inventoriesObj),
            let productsCategoriesObj = representation.valueForKeyPath("productsCategories") as? [AnyObject],
            let productsCategories = RemoteProductCategory.collection(productsCategoriesObj),
            let productsObj = representation.valueForKeyPath("products") as? [AnyObject],
            let products = RemoteProduct.collection(productsObj)
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.planItems = planItems
        self.inventory = inventory
        self.productsCategories = productsCategories
        self.products = products
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) planItems: [\(planItems)], inventory: [\(inventory)], productsCategories: [\(productsCategories)], products: [\(products)]]}"
    }
}