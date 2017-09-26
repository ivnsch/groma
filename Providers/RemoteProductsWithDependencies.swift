//
//  RemoteProductsWithDependencies.swift
//  shoppin
//
//  Created by ischuetz on 08/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation


struct RemoteProductsWithDependencies: ResponseObjectSerializable, CustomDebugStringConvertible {
    
    let products: [RemoteProduct]
    let categories: [RemoteProductCategory]
    
    init?(representation: AnyObject) {
        guard
            let productsObj = representation.value(forKeyPath: "products") as? [AnyObject],
            let products = RemoteProduct.collection(productsObj),
            let categoriesObj = representation.value(forKeyPath: "categories") as? [AnyObject],
            let categories = RemoteProductCategory.collection(categoriesObj)
            else {
                logger.e("Invalid json: \(representation)")
                return nil}
        
        self.products = products
        self.categories = categories
    }
    
    var debugDescription: String {
        return "{\(type(of: self)) products: \(products), categories: \(categories)}"
    }
}
