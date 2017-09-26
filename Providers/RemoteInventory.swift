//
//  RemoteInventory.swift
//  shoppin
//
//  Created by ischuetz on 21/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation


public struct RemoteInventory: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    public let uuid: String
    public let name: String
    public let order: Int
    public let color: UIColor
    public let lastUpdate: Int64

    public init?(representation: AnyObject) {
        guard
            let uuid = representation.value(forKeyPath: "uuid") as? String,
            let name = representation.value(forKeyPath: "name") as? String,
            let order = representation.value(forKeyPath: "order") as? Int,
            let color = ((representation.value(forKeyPath: "color") as? String).map{colorStr in
                UIColor(hexString: colorStr)
            }),
            let lastUpdate = representation.value(forKeyPath: "lastUpdate") as? Double
            else {
                logger.e("Invalid json: \(representation)")
                return nil}
        
        self.uuid = uuid
        self.name = name
        self.order = order
        self.color = color
        self.lastUpdate = Int64(lastUpdate)
    }

    public static func collection(_ representation: [AnyObject]) -> [RemoteInventory]? {
        var sections = [RemoteInventory]()
        for obj in representation {
            if let section = RemoteInventory(representation: obj) {
                sections.append(section)
            } else {
                return nil
            }
            
        }
        return sections
    }
    
    public var debugDescription: String {
        return "{\(type(of: self)) uuid: \(uuid), name: \(name), order: \(order), color: \(color.hexStr), lastUpdate: \(lastUpdate)}"
    }
}

public extension RemoteInventory {
    var timestampUpdateDict: [String: AnyObject] {
        return DBSyncable.timestampUpdateDict(uuid, lastServerUpdate: lastUpdate)
    }
}
