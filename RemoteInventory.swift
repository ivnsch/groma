//
//  RemoteInventory.swift
//  shoppin
//
//  Created by ischuetz on 21/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

final class RemoteInventory: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    let uuid: String
    let name: String
    let order: Int
    let color: UIColor
    let lastUpdate: NSDate
    let users: [RemoteSharedUser]

    init?(response: NSHTTPURLResponse, representation: AnyObject) {
        let inventory: AnyObject = representation.valueForKeyPath("inventory")!
        self.uuid = inventory.valueForKeyPath("uuid") as! String
        self.name = inventory.valueForKeyPath("name") as! String
        self.order = inventory.valueForKeyPath("order") as! Int
        let colorStr = representation.valueForKeyPath("color") as! String
        self.color = UIColor(hexString: colorStr) ?? {
            print("Error: RemoteList.init: Invalid color hex: \(colorStr)")
            return UIColor.blackColor()
        }()
        self.lastUpdate = NSDate(timeIntervalSince1970: inventory.valueForKeyPath("lastUpdate") as! Double)
        let unserializedUsers: AnyObject = representation.valueForKeyPath("users")!
        self.users = RemoteSharedUser.collection(response: response, representation: unserializedUsers)
    }
    
    static func collection(response response: NSHTTPURLResponse, representation: AnyObject) -> [RemoteInventory] {
        var sections = [RemoteInventory]()
        for obj in representation as! [AnyObject] {
            if let section = RemoteInventory(response: response, representation: obj) {
                sections.append(section)
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