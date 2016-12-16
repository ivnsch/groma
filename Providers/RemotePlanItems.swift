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
    let inventory: RemoteInventoryWithDependencies
    let productsCategories: [RemoteProductCategory]
    let products: [RemoteProduct]
    
    init?(representation: AnyObject) {
        guard
            let planItemsObj = representation.value(forKeyPath: "planItems") as? [AnyObject],
            let planItems = RemoteHistoryItem.collection(planItemsObj),
            let inventoriesObj = representation.value(forKeyPath: "inventory") as? [AnyObject],
            let inventory = RemoteInventoryWithDependencies(representation: inventoriesObj as AnyObject),
            let productsCategoriesObj = representation.value(forKeyPath: "productsCategories") as? [AnyObject],
            let productsCategories = RemoteProductCategory.collection(productsCategoriesObj),
            let productsObj = representation.value(forKeyPath: "products") as? [AnyObject],
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
        return "{\(type(of: self)) planItems: [\(planItems)], inventory: [\(inventory)], productsCategories: [\(productsCategories)], products: [\(products)]]}"
    }
}
