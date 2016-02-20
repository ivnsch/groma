    //
//  RemoteListItems.swift
//  shoppin
//
//  Created by ischuetz on 13/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
    
final class RemoteListItems: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {

    let lists: RemoteListsWithDependencies
    let products: [RemoteProduct]
    let productsCategories: [RemoteProductCategory]
    let sections: [RemoteSection]
    let listItems: [RemoteListItem]
    
    var productsCategoriesDict: [String: RemoteProductCategory] {
        var dict = [String: RemoteProductCategory]()
        for productCategory in productsCategories {
            dict[productCategory.uuid] = productCategory
        }
        return dict
    }
    
    @objc required init?(representation: AnyObject) {
        
        let lists = representation.valueForKeyPath("lists")!
        self.lists = RemoteListsWithDependencies(representation: lists)!
        
        let products = representation.valueForKeyPath("products") as! [AnyObject]
        self.products = RemoteProduct.collection(products)

        let productsCategories = representation.valueForKeyPath("productsCategories") as! [AnyObject]
        self.productsCategories = RemoteProductCategory.collection(productsCategories)
        
        let sections = representation.valueForKeyPath("sections") as! [AnyObject]
        self.sections = RemoteSection.collection(sections)
        
        let listItems = representation.valueForKeyPath("listItems") as! [AnyObject]
        self.listItems = RemoteListItem.collection(listItems)
    }
    
    // Only for compatibility purpose with sync result, which always sends result as an array. With RemoteListItems we get always 1 element array
    static func collection(representation: AnyObject) -> [RemoteListItems] {
        var listItems = [RemoteListItems]()
        for obj in representation as! [AnyObject] {
            if let listItem = RemoteListItems(representation: obj) {
                listItems.append(listItem)
            }
            
        }
        return listItems
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) lists: \(lists), productsCategories: [\(productsCategories)], products: [\(products)], listItems: [\(listItems)}"
    }
}
