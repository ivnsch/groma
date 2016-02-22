//
//  RemoteGroupItemsWithDependenciesNoGroup.swift
//  shoppin
//
//  Created by ischuetz on 28/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

struct RemoteGroupItemsWithDependenciesNoGroup: ResponseObjectSerializable, CustomDebugStringConvertible {
    
    let products: [RemoteProduct]
    let productsCategories: [RemoteProductCategory]
    let groupItems: [RemoteGroupItem]
    
    init?(representation: AnyObject) {
        guard
            let productsObj = representation.valueForKeyPath("products") as? [AnyObject],
            let products = RemoteProduct.collection(productsObj),
            let productsCategoriesObj = representation.valueForKeyPath("productsCategories") as? [AnyObject],
            let productsCategories = RemoteProductCategory.collection(productsCategoriesObj),
            let groupItemsObj = representation.valueForKeyPath("items") as? [AnyObject],
            let groupItems = RemoteGroupItem.collection(groupItemsObj)
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.products = products
        self.productsCategories = productsCategories
        self.groupItems = groupItems
    }
    
    static func collection(response response: NSHTTPURLResponse, representation: AnyObject) -> [RemoteInventoryWithItems]? {
        var listItems = [RemoteInventoryWithItems]()
        for obj in representation as! [AnyObject] {
            if let listItem = RemoteInventoryWithItems(representation: obj) {
                listItems.append(listItem)
            } else {
                return nil
            }
            
        }
        return listItems
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) productsCategories: [\(productsCategories)], products: [\(products)], groupItems: [\(groupItems)}"
    }
}
