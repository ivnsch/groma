//
//  RemoteProduct.swift
//  shoppin
//
//  Created by ischuetz on 13/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

final class RemoteProduct: ResponseObjectSerializable, ResponseCollectionSerializable, DebugPrintable {
    let id: String
    let name: String
    let price: Float
    
    @objc required init?(response: NSHTTPURLResponse, representation: AnyObject) {
        self.id = representation.valueForKeyPath("id") as! String
        self.name = representation.valueForKeyPath("name") as! String
        self.price = representation.valueForKeyPath("price") as! Float
    }
    
    @objc static func collection(#response: NSHTTPURLResponse, representation: AnyObject) -> [RemoteProduct] {
        var products = [RemoteProduct]()
        for obj in representation as! [AnyObject] {
            if let product = RemoteProduct(response: response, representation: obj) {
                products.append(product)
            }
            
        }
        return products
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) id: \(self.id), name: \(self.name), price: \(self.price)}"
    }
}
