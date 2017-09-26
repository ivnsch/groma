//
//  RemoteListItemsWithDependenciesNoList.swift
//  shoppin
//
//  Created by ischuetz on 28/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation


struct RemoteListItemsWithDependenciesNoList: ResponseObjectSerializable, CustomDebugStringConvertible {
    
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
            let productsObj = representation.value(forKeyPath: "products") as? [AnyObject],
            let products = RemoteProduct.collection(productsObj),
            let productsCategoriesObj = representation.value(forKeyPath: "productsCategories") as? [AnyObject],
            let productsCategories = RemoteProductCategory.collection(productsCategoriesObj),
            let sectionsObj = representation.value(forKeyPath: "sections") as? [AnyObject],
            let sections = RemoteSection.collection(sectionsObj),
            let listItemsObj = representation.value(forKeyPath: "items") as? [AnyObject],
            let listItems = RemoteListItem.collection(listItemsObj)
            else {
                logger.e("Invalid json: \(representation)")
                return nil}
        
        self.products = products
        self.productsCategories = productsCategories
        self.sections = sections
        self.listItems = listItems
    }
    
    var debugDescription: String {
        return "{\(type(of: self)) productsCategories: [\(productsCategories)], products: [\(products)], sections: [\(sections)], listItems: [\(listItems)}"
    }
}
