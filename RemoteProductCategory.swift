//
//  RemoteProductCategory.swift
//  shoppin
//
//  Created by ischuetz on 20/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

struct RemoteProductCategory: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    let uuid: String
    let name: String
    var color: UIColor
    let lastUpdate: NSDate
    
    init?(representation: AnyObject) {
        guard
            let uuid = representation.valueForKeyPath("uuid") as? String,
            let name = representation.valueForKeyPath("name") as? String,
            let color = ((representation.valueForKeyPath("color") as? String).map{colorStr in
                UIColor(hexString: colorStr)
            }),
            let lastUpdate = ((representation.valueForKeyPath("lastUpdate") as? Double).map{d in NSDate(timeIntervalSince1970: d)})
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.uuid = uuid
        self.name = name
        self.color = color
        self.lastUpdate = lastUpdate
    }

    static func collection(representation: AnyObject) -> [RemoteProductCategory]? {
        var products = [RemoteProductCategory]()
        for obj in representation as! [AnyObject] {
            if let product = RemoteProductCategory(representation: obj) {
                products.append(product)
            } else {
                return nil
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
        return DBSyncable.timestampUpdateDict(uuid, lastServerUpdate: lastUpdate)
    }
}