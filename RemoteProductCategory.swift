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
    let lastUpdate: NSDate
    
    init?(representation: AnyObject) {
        self.uuid = representation.valueForKeyPath("uuid") as! String
        self.name = representation.valueForKeyPath("name") as! String
        let colorStr = representation.valueForKeyPath("color") as! String
        self.color = UIColor(hexString: colorStr) ?? {
            print("Error: RemoteProductCategory.init: Invalid color hex: \(colorStr)")
            return UIColor.blackColor()
        }()
        self.lastUpdate = NSDate(timeIntervalSince1970: representation.valueForKeyPath("lastUpdate") as! Double)        
    }
    
    static func collection(representation: AnyObject) -> [RemoteProductCategory] {
        var products = [RemoteProductCategory]()
        for obj in representation as! [AnyObject] {
            if let product = RemoteProductCategory(representation: obj) {
                products.append(product)
            }
            
        }
        return products
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(uuid), name: \(name), color: \(color), listUpdate: \(lastUpdate)}"
    }
}

extension RemoteProductCategory {
    var timestampUpdateDict: [String: AnyObject] {
        return ["uuid": uuid, "lastupdate": lastUpdate]
    }
}