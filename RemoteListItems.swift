    //
//  RemoteListItems.swift
//  shoppin
//
//  Created by ischuetz on 13/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

struct RemoteListItems: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {

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
    
    init?(representation: AnyObject) {
        guard
            let listsObj = representation.valueForKeyPath("lists"),
            let lists = RemoteListsWithDependencies(representation: listsObj),
            let productsObj = representation.valueForKeyPath("products") as? [AnyObject],
            let products = RemoteProduct.collection(productsObj),
            let productsCategoriesObj = representation.valueForKeyPath("productsCategories") as? [AnyObject],
            let productsCategories = RemoteProductCategory.collection(productsCategoriesObj),
            let sectionsObj = representation.valueForKeyPath("sections") as? [AnyObject],
            let sections = RemoteSection.collection(sectionsObj),
            let listItemsObj = representation.valueForKeyPath("listItems") as? [AnyObject],
            let listItems = RemoteListItem.collection(listItemsObj)
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.lists = lists
        self.products = products
        self.productsCategories = productsCategories
        self.sections = sections
        self.listItems = listItems
    }
    
    // Only for compatibility purpose with sync result, which always sends result as an array. With RemoteListItems we get always 1 element array
    static func collection(representation: AnyObject) -> [RemoteListItems]? {
        var listItems = [RemoteListItems]()
        for obj in representation as! [AnyObject] {
            if let listItem = RemoteListItems(representation: obj) {
                listItems.append(listItem)
            } else {
                return nil
            }
            
        }
        return listItems
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) lists: \(lists), productsCategories: [\(productsCategories)], products: [\(products)], listItems: [\(listItems)}"
    }
}
