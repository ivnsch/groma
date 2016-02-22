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
    let lastUpdate: NSDate
    let users: [RemoteSharedUser]

    init?(representation: AnyObject) {
        guard
            let inventory: AnyObject = representation.valueForKeyPath("inventory")!,
            let uuid = inventory.valueForKeyPath("uuid") as? String,
            let name = inventory.valueForKeyPath("name") as? String,
            let order = inventory.valueForKeyPath("order") as? Int,
            let color = ((inventory.valueForKeyPath("color") as? String).map{colorStr in
                UIColor(hexString: colorStr)
            }),
            let lastUpdate = ((inventory.valueForKeyPath("lastUpdate") as? Double).map{d in NSDate(timeIntervalSince1970: d)}),
            let unserializedUsers = representation.valueForKeyPath("users"),
            let users = RemoteSharedUser.collection(unserializedUsers)
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.uuid = uuid
        self.name = name
        self.order = order
        self.color = color
        self.lastUpdate = lastUpdate
        self.users = users
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
        return "{\(self.dynamicType) uuid: \(uuid), name: \(name), order: \(order), color: \(color.hexStr), lastUpdate: \(lastUpdate), users: \(users)}"
    }
}

extension RemoteInventory {
    var timestampUpdateDict: [String: AnyObject] {
        return ["uuid": uuid, "lastupdate": lastUpdate]
    }
}