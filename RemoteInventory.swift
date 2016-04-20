//
//  RemoteInventory.swift
//  shoppin
//
//  Created by ischuetz on 21/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

struct RemoteInventory: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    let uuid: String
    let name: String
    let order: Int
    let color: UIColor
    let lastUpdate: Int64

    init?(representation: AnyObject) {
        guard
            let uuid = representation.valueForKeyPath("uuid") as? String,
            let name = representation.valueForKeyPath("name") as? String,
            let order = representation.valueForKeyPath("order") as? Int,
            let color = ((representation.valueForKeyPath("color") as? String).map{colorStr in
                UIColor(hexString: colorStr)
            }),
            let lastUpdate = representation.valueForKeyPath("lastUpdate") as? Double
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.uuid = uuid
        self.name = name
        self.order = order
        self.color = color
        self.lastUpdate = Int64(lastUpdate)
    }

    static func collection(representation: AnyObject) -> [RemoteInventory]? {
        var sections = [RemoteInventory]()
        for obj in representation as! [AnyObject] {
            if let section = RemoteInventory(representation: obj) {
                sections.append(section)
            } else {
                return nil
            }
            
        }
        return sections
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(uuid), name: \(name), order: \(order), color: \(color.hexStr), lastUpdate: \(lastUpdate)}"
    }
}

extension RemoteInventory {
    var timestampUpdateDict: [String: AnyObject] {
        return DBSyncable.timestampUpdateDict(uuid, lastServerUpdate: lastUpdate)
    }
}