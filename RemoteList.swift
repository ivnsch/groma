//
//  RemoteList.swift
//  shoppin
//
//  Created by ischuetz on 13/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

struct RemoteList: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    let uuid: String
    let name: String
    let order: Int
    var color: UIColor    
    let users: [RemoteSharedUser]
    let lastUpdate: NSDate
    let inventoryUuid: String
    
    init?(representation: AnyObject) {
        guard
            let list: AnyObject = representation.valueForKeyPath("list"),
            let uuid = list.valueForKeyPath("uuid") as? String,
            let name = list.valueForKeyPath("name") as? String,
            let order = list.valueForKeyPath("order") as? Int,
            let unserializedUsers: AnyObject = representation.valueForKeyPath("users"),
            let users = RemoteSharedUser.collection(unserializedUsers),
            let lastUpdate = ((list.valueForKeyPath("lastUpdate") as? Double).map{d in NSDate(timeIntervalSince1970: d)}),
            let inventoryUuid = list.valueForKeyPath("inventoryUuid") as? String,
            let color = ((list.valueForKeyPath("color") as? String).map{colorStr in
                UIColor(hexString: colorStr)
            })
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.uuid = uuid
        self.name = name
        self.order = order
        self.users = users
        self.lastUpdate = lastUpdate
        self.inventoryUuid = inventoryUuid
        self.color = color
    }
    
    static func collection(representation: AnyObject) -> [RemoteList]? {
        var lists = [RemoteList]()
        for obj in representation as! [AnyObject] {
            if let list = RemoteList(representation: obj) {
                lists.append(list)
            } else {
                return nil
            }
            
        }
        return lists
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(uuid), name: \(name), order: \(order), users: \(users), inventoryUuid: \(inventoryUuid), lastUpdate: \(lastUpdate), color: \(color)}"
    }
}

extension RemoteList {
    var timestampUpdateDict: [String: AnyObject] {
        return ["uuid": uuid, "lastupdate": lastUpdate]
    }
}