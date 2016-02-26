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
    let lastUpdate: NSDate
    let order: Int
    let color: UIColor
    let fav: Int
    
    init?(representation: AnyObject) {
        guard
            let uuid = representation.valueForKeyPath("uuid") as? String,
            let name = representation.valueForKeyPath("name") as? String,
            let lastUpdate = ((representation.valueForKeyPath("lastUpdate") as? Double).map{d in NSDate(timeIntervalSince1970: d)}),
            let order = representation.valueForKeyPath("order") as? Int,
            let color = ((representation.valueForKeyPath("color") as? String).map{colorStr in
                UIColor(hexString: colorStr)
            }),
            let fav = representation.valueForKeyPath("fav") as? Int
            else {
                print("Invalid json: \(representation)")
                return nil}
        
        self.uuid = uuid
        self.name = name
        self.lastUpdate = lastUpdate
        self.order = order
        self.color = color
        self.fav = fav
    }
    
    static func collection(representation: AnyObject) -> [RemoteGroup]? {
        var items = [RemoteGroup]()
        for obj in representation as! [AnyObject] {
            if let item = RemoteGroup(representation: obj) {
                items.append(item)
            } else {
                return nil
            }
            
        }
        return items
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(uuid), name: \(name), order: \(order), color: \(color.hexStr), lastUpdate: \(lastUpdate), fav: \(fav)}"
    }
}

extension RemoteGroup {
    var timestampUpdateDict: [String: AnyObject] {
        return ["uuid": uuid, "lastupdate": lastUpdate, "dirty": false]
    }
}