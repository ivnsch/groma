//
//  RemoteGroupItemsWithDependencies.swift
//  shoppin
//
//  Created by ischuetz on 22/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

struct RemoteGroupItemsWithDependencies: ResponseObjectSerializable, CustomDebugStringConvertible {
    
    let products: [RemoteProduct]
    let productsCategories: [RemoteProductCategory]
    let groupItems: [RemoteGroupItem]
    let groups: [RemoteGroup]
    
    init?(representation: AnyObject) {
        guard
            let productsObj = representation.value(forKeyPath: "products") as? [AnyObject],
            let products = RemoteProduct.collection(productsObj),
            let productsCategoriesObj = representation.value(forKeyPath: "productsCategories") as? [AnyObject],
            let productsCategories = RemoteProductCategory.collection(productsCategoriesObj),
            let groupItemsObj = representation.value(forKeyPath: "groupItems") as? [AnyObject],
            let groupItems = RemoteGroupItem.collection(groupItemsObj),
            let groupsObj = representation.value(forKeyPath: "groups") as? [AnyObject],
            let groups = RemoteGroup.collection(groupsObj)
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.products = products
        self.productsCategories = productsCategories
        self.groupItems = groupItems
        self.groups = groups
    }
    
    static func collection(response: HTTPURLResponse, representation: AnyObject) -> [RemoteInventoryWithItems]? {
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
        return "{\(type(of: self)) productsCategories: [\(productsCategories)], products: [\(products)], groupItems: [\(groupItems), groups: [\(groups)}"
    }
}
