//
//  RemoteListItemsWithDependenciesNoList.swift
//  shoppin
//
//  Created by ischuetz on 28/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

final class RemoteListItemsWithDependenciesNoList: ResponseObjectSerializable, CustomDebugStringConvertible {
    
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
    
    @objc required init?(response: NSHTTPURLResponse, representation: AnyObject) {
        
        let products = representation.valueForKeyPath("products") as! [AnyObject]
        self.products = RemoteProduct.collection(response: response, representation: products)
        
        let productsCategories = representation.valueForKeyPath("productsCategories") as! [AnyObject]
        self.productsCategories = RemoteProductCategory.collection(response: response, representation: productsCategories)
        
        let sections = representation.valueForKeyPath("sections") as! [AnyObject]
        self.sections = RemoteSection.collection(response: response, representation: sections)
        
        let listItems = representation.valueForKeyPath("items") as! [AnyObject]
        self.listItems = RemoteListItem.collection(response: response, representation: listItems)
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) productsCategories: [\(productsCategories)], products: [\(products)], sections: [\(sections)], listItems: [\(listItems)}"
    }
}
