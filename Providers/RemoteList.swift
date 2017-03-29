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
    let store: String?
    let users: [RemoteSharedUser]
    let lastUpdate: Int64
    let inventoryUuid: String
    
    init?(representation: AnyObject) {
        guard
            let listObj = representation.value(forKeyPath: "list"),
            let list = RemoteListNoUsers(representation: listObj as AnyObject), // TODO list should be a field of this class don't copy the propertis like below. Maybe use computed properties
            let unserializedUsers = representation.value(forKeyPath: "users") as? [AnyObject],
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
        self.store = list.store
    }
    
    static func collection(_ representation: [AnyObject]) -> [RemoteList]? {
        var lists = [RemoteList]()
        for obj in representation {
            if let list = RemoteList(representation: obj) {
                lists.append(list)
            } else {
                return nil
            }
            
        }
        return lists
    }
    
    var debugDescription: String {
        return "{\(type(of: self)) uuid: \(uuid), name: \(name), order: \(order), users: \(users), inventoryUuid: \(inventoryUuid), lastUpdate: \(lastUpdate), color: \(color), store: \(String(describing: store))}"
    }
}

extension RemoteList {
    var timestampUpdateDict: [String: AnyObject] {
        return DBSyncable.timestampUpdateDict(uuid, lastServerUpdate: lastUpdate)
    }
}
