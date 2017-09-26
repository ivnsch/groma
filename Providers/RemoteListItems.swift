    //
//  RemoteListItems.swift
//  shoppin
//
//  Created by ischuetz on 13/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation


struct RemoteListItems: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {

    let lists: RemoteListsWithDependencies
    let storeProducts: [RemoteStoreProduct]
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
            let listsObj = representation.value(forKeyPath: "lists"),
            let lists = RemoteListsWithDependencies(representation: listsObj as AnyObject),
            let storeProductsObj = representation.value(forKeyPath: "storeProducts") as? [AnyObject],
            let storeProducts = RemoteStoreProduct.collection(storeProductsObj),
            let productsObj = representation.value(forKeyPath: "products") as? [AnyObject],
            let products = RemoteProduct.collection(productsObj),
            let productsCategoriesObj = representation.value(forKeyPath: "productsCategories") as? [AnyObject],
            let productsCategories = RemoteProductCategory.collection(productsCategoriesObj),
            let sectionsObj = representation.value(forKeyPath: "sections") as? [AnyObject],
            let sections = RemoteSection.collection(sectionsObj),
            let listItemsObj = representation.value(forKeyPath: "listItems") as? [AnyObject],
            let listItems = RemoteListItem.collection(listItemsObj)
            else {
                logger.e("Invalid json: \(representation)")
                return nil}
        
        self.lists = lists
        self.storeProducts = storeProducts
        self.products = products
        self.productsCategories = productsCategories
        self.sections = sections
        self.listItems = listItems
    }
    
    // Only for compatibility purpose with sync result, which always sends result as an array. With RemoteListItems we get always 1 element array
    static func collection(_ representation: [AnyObject]) -> [RemoteListItems]? {
        var listItems = [RemoteListItems]()
        for obj in representation {
            if let listItem = RemoteListItems(representation: obj) {
                listItems.append(listItem)
            } else {
                return nil
            }
            
        }
        return listItems
    }
    
    var debugDescription: String {
        return "{\(type(of: self)) lists: \(lists), storeProducts: \(storeProducts), productsCategories: [\(productsCategories)], products: [\(products)], listItems: [\(listItems)}"
    }
}
