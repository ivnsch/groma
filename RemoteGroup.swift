//
//  RemoteGroup.swift
//  shoppin
//
//  Created by ischuetz on 21/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

final class RemoteGroup: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    let uuid: String
    let name: String
    let lastUpdate: NSDate
    
    init?(response: NSHTTPURLResponse, representation: AnyObject) {
        self.uuid = representation.valueForKeyPath("uuid") as! String
        self.name = representation.valueForKeyPath("name") as! String
        self.lastUpdate = NSDate(timeIntervalSince1970: representation.valueForKeyPath("lastUpdate") as! Double)
    }
    
    static func collection(response response: NSHTTPURLResponse, representation: AnyObject) -> [RemoteGroup] {
        var items = [RemoteGroup]()
        for obj in representation as! [AnyObject] {
            if let item = RemoteGroup(response: response, representation: obj) {
                items.append(item)
            }
            
        }
        return items
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(uuid), name: \(name)}, lastUpdate: \(lastUpdate)}"
    }
}