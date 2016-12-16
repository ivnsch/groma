//
//  RemoteProductCategory.swift
//  shoppin
//
//  Created by ischuetz on 20/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

public struct RemoteProductCategory: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    public let uuid: String
    public let name: String
    public var color: UIColor
    public let lastUpdate: Int64
    
    public init?(representation: AnyObject) {
        guard
            let uuid = representation.value(forKeyPath: "uuid") as? String,
            let name = representation.value(forKeyPath: "name") as? String,
            let color = ((representation.value(forKeyPath: "color") as? String).map{colorStr in
                UIColor(hexString: colorStr)
            }),
            let lastUpdate = representation.value(forKeyPath: "lastUpdate") as? Double
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.uuid = uuid
        self.name = name
        self.color = color
        self.lastUpdate = Int64(lastUpdate)
    }

    public static func collection(_ representation: [AnyObject]) -> [RemoteProductCategory]? {
        var products = [RemoteProductCategory]()
        for obj in representation {
            if let product = RemoteProductCategory(representation: obj) {
                products.append(product)
            } else {
                return nil
            }
            
        }
        return products
    }
    
    public var debugDescription: String {
        return "{\(type(of: self)) uuid: \(uuid), name: \(name), color: \(color), listUpdate: \(lastUpdate)}"
    }
}

public extension RemoteProductCategory {
    var timestampUpdateDict: [String: AnyObject] {
        return DBSyncable.timestampUpdateDict(uuid, lastServerUpdate: lastUpdate)
    }
}
