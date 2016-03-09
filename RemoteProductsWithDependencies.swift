//
//  RemoteProductsWithDependencies.swift
//  shoppin
//
//  Created by ischuetz on 08/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

struct RemoteProductsWithDependencies: ResponseObjectSerializable, CustomDebugStringConvertible {
    
    let products: [RemoteProduct]
    let categories: [RemoteProductCategory]
    
    init?(representation: AnyObject) {
        guard
            let productsObj = representation.valueForKeyPath("products"),
            let products = RemoteProduct.collection(productsObj),
            let categoriesObj = representation.valueForKeyPath("categories"),
            let categories = RemoteProductCategory.collection(categoriesObj)
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.products = products
        self.categories = categories
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) products: \(products), categories: \(categories)}"
    }
}