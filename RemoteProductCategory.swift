//
//  RemoteProductCategory.swift
//  shoppin
//
//  Created by ischuetz on 20/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

final class RemoteProductCategory: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    let uuid: String
    let name: String
    var color: UIColor
    
    init?(response: NSHTTPURLResponse, representation: AnyObject) {
        self.uuid = representation.valueForKeyPath("uuid") as! String
        self.name = representation.valueForKeyPath("name") as! String
//        self.color = representation.valueForKeyPath("color") as! // TODO
        self.color = UIColor.purpleColor()
    }
    
    static func collection(response response: NSHTTPURLResponse, representation: AnyObject) -> [RemoteProductCategory] {
        var products = [RemoteProductCategory]()
        for obj in representation as! [AnyObject] {
            if let product = RemoteProductCategory(response: response, representation: obj) {
                products.append(product)
            }
            
        }
        return products
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(uuid), name: \(name), color: \(color)}"
    }
}
