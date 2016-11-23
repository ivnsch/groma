//
//  RemoteGroup.swift
//  shoppin
//
//  Created by ischuetz on 21/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

struct RemoteGroup: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    let uuid: String
    let name: String
    let lastUpdate: Int64
    let order: Int
    let color: UIColor
    let fav: Int
    
    init?(representation: AnyObject) {
        guard
            let uuid = representation.value(forKeyPath: "uuid") as? String,
            let name = representation.value(forKeyPath: "name") as? String,
            let lastUpdate = representation.value(forKeyPath: "lastUpdate") as? Double,
            let order = representation.value(forKeyPath: "order") as? Int,
            let color = ((representation.value(forKeyPath: "color") as? String).map{colorStr in
                UIColor(hexString: colorStr)
            }),
            let fav = representation.value(forKeyPath: "fav") as? Int
            else {
                print("Invalid json: \(representation)")
                return nil}
        
        self.uuid = uuid
        self.name = name
        self.lastUpdate = Int64(lastUpdate)
        self.order = order
        self.color = color
        self.fav = fav
    }
    
    static func collection(_ representation: [AnyObject]) -> [RemoteGroup]? {
        var items = [RemoteGroup]()
        for obj in representation {
            if let item = RemoteGroup(representation: obj) {
                items.append(item)
            } else {
                return nil
            }
            
        }
        return items
    }
    
    var debugDescription: String {
        return "{\(type(of: self)) uuid: \(uuid), name: \(name), order: \(order), color: \(color.hexStr), lastUpdate: \(lastUpdate), fav: \(fav)}"
    }
}

extension RemoteGroup {
    var timestampUpdateDict: [String: AnyObject] {
        return DBSyncable.timestampUpdateDict(uuid, lastServerUpdate: lastUpdate)
    }
}
