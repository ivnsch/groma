//
//  RemoteInventory.swift
//  shoppin
//
//  Created by ischuetz on 21/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

final class RemoteInventory: ResponseObjectSerializable, ResponseCollectionSerializable, DebugPrintable {
    let uuid: String
    let name: String
    let users: [RemoteSharedUser]

    @objc required init?(response: NSHTTPURLResponse, representation: AnyObject) {
        let inventory: AnyObject = representation.valueForKeyPath("inventory")!
        self.uuid = inventory.valueForKeyPath("uuid") as! String
        self.name = inventory.valueForKeyPath("name") as! String
        let unserializedUsers: AnyObject = representation.valueForKeyPath("users")!
        self.users = RemoteSharedUser.collection(response: response, representation: unserializedUsers)
    }
    
    @objc static func collection(#response: NSHTTPURLResponse, representation: AnyObject) -> [RemoteInventory] {
        var sections = [RemoteInventory]()
        for obj in representation as! [AnyObject] {
            if let section = RemoteInventory(response: response, representation: obj) {
                sections.append(section)
            }
            
        }
        return sections
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(self.uuid), name: \(self.name)}, users: \(self.users)}"
    }
}