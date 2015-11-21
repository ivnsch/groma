//
//  RemoteProduct.swift
//  shoppin
//
//  Created by ischuetz on 13/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

final class RemoteProduct: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    let uuid: String
    let name: String
    let price: Float
    var category: RemoteProductCategory
    let baseQuantity: Float
    let unit: Int
    
    init?(response: NSHTTPURLResponse, representation: AnyObject) {
        self.uuid = representation.valueForKeyPath("uuid") as! String
        self.name = representation.valueForKeyPath("name") as! String
        self.price = representation.valueForKeyPath("price") as! Float
//        self.category = representation.valueForKeyPath("category") as! String
        let unserializedCategory: AnyObject = representation.valueForKeyPath("category")!
        self.category = RemoteProductCategory(response: response, representation: unserializedCategory)!
        self.baseQuantity = representation.valueForKeyPath("baseQuantity") as! Float
        self.unit = representation.valueForKeyPath("unit") as! Int
    }
    
    static func collection(response response: NSHTTPURLResponse, representation: AnyObject) -> [RemoteProduct] {
        var products = [RemoteProduct]()
        for obj in representation as! [AnyObject] {
            if let product = RemoteProduct(response: response, representation: obj) {
                products.append(product)
            }
            
        }
        return products
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(uuid), name: \(name), price: \(price), category: \(category), baseQuantity: \(baseQuantity), unit: \(unit)}"
    }
}