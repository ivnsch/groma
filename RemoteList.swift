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
            let list = RemoteListNoUsers(representation: representation), // TODO list should be a field of this class don't copy the propertis like below. Maybe use computed properties
            let unserializedUsers: AnyObject = representation.valueForKeyPath("users"),
            let users = RemoteSharedUser.collection(unserializedUsers)
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.uuid = list.uuid
        self.name = list.name
        self.order = list.order
        self.users = users
        self.lastUpdate = list.lastUpdate
        self.inventoryUuid = list.inventoryUuid
        self.color = list.color
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
        return ["uuid": uuid, "lastupdate": lastUpdate, "dirty": false]
    }
}