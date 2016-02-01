//
//  RemoteGroupItemsWithDependenciesNoGroup.swift
//  shoppin
//
//  Created by ischuetz on 28/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

final class RemoteGroupItemsWithDependenciesNoGroup: ResponseObjectSerializable, CustomDebugStringConvertible {
    
    let products: [RemoteProduct]
    let productsCategories: [RemoteProductCategory]
    let groupItems: [RemoteGroupItem]
    
    @objc required init?(response: NSHTTPURLResponse, representation: AnyObject) {
        
        let products = representation.valueForKeyPath("products") as! [AnyObject]
        self.products = RemoteProduct.collection(response: response, representation: products)
        
        let productsCategories = representation.valueForKeyPath("productsCategories") as! [AnyObject]
        self.productsCategories = RemoteProductCategory.collection(response: response, representation: productsCategories)
        
        let groupItems = representation.valueForKeyPath("items") as! [AnyObject]
        self.groupItems = RemoteGroupItem.collection(response: response, representation: groupItems)
    }
    
    static func collection(response response: NSHTTPURLResponse, representation: AnyObject) -> [RemoteInventoryWithItems] {
        var listItems = [RemoteInventoryWithItems]()
        for obj in representation as! [AnyObject] {
            if let listItem = RemoteInventoryWithItems(response: response, representation: obj) {
                listItems.append(listItem)
            }
            
        }
        return listItems
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) productsCategories: [\(productsCategories)], products: [\(products)], groupItems: [\(groupItems)}"
    }
}
