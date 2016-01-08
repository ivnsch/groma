//
//  RemoteList.swift
//  shoppin
//
//  Created by ischuetz on 13/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

final class RemoteList: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    let uuid: String
    let name: String
    let order: Int
    let users: [RemoteSharedUser]
    let lastUpdate: NSDate
    let inventoryUuid: String
    
    init?(response: NSHTTPURLResponse, representation: AnyObject) {
        
        let list: AnyObject = representation.valueForKeyPath("list")!
        self.uuid = list.valueForKeyPath("uuid") as! String
        self.name = list.valueForKeyPath("name") as! String
        self.order = list.valueForKeyPath("order") as! Int
        let unserializedUsers: AnyObject = representation.valueForKeyPath("users")!
        self.users = RemoteSharedUser.collection(response: response, representation: unserializedUsers)
        self.lastUpdate = NSDate(timeIntervalSince1970: list.valueForKeyPath("lastUpdate") as! Double)
        self.inventoryUuid = list.valueForKeyPath("inventoryUuid") as! String
    }
    
    static func collection(response response: NSHTTPURLResponse, representation: AnyObject) -> [RemoteList] {
        var lists = [RemoteList]()
        for obj in representation as! [AnyObject] {
            if let list = RemoteList(response: response, representation: obj) {
                lists.append(list)
            }
            
        }
        return lists
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(uuid), name: \(name), order: \(order), users: \(users), inventoryUuid: \(inventoryUuid), lastUpdate: \(lastUpdate)}"
    }
}