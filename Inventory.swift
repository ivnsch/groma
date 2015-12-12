//
//  Inventory.swift
//  shoppin
//
//  Created by ischuetz on 21/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

class Inventory: Equatable, Identifiable, Hashable {
    let uuid: String
    let name: String
    
    let users: [SharedUser] // note that this will be empty if using the app offline (TODO think about showing myself in this list - right now also this will not appear offline)

    //////////////////////////////////////////////
    // sync properties - FIXME - while Realm allows to return Realm objects from async op. This shouldn't be in model objects.
    // the idea is that we can return the db objs from query and then do sync directly with these objs so no need to put sync attributes in model objs
    // we could map the db objects to other db objs in order to work around the Realm issue, but this adds even more overhead, we make a lot of mappings already
    let lastUpdate: NSDate
    let lastServerUpdate: NSDate?
    let removed: Bool
    //////////////////////////////////////////////
    
    init(uuid: String, name: String, users: [SharedUser] = [], lastUpdate: NSDate = NSDate(), lastServerUpdate: NSDate? = nil, removed: Bool = false) {
        self.uuid = uuid
        self.name = name
        self.users = users
        self.lastUpdate = lastUpdate
        self.lastServerUpdate = lastServerUpdate
        self.removed = removed
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(self.uuid), name: \(self.name), users: \(self.users), lastUpdate: \(self.lastUpdate), lastServerUpdate: \(self.lastServerUpdate), removed: \(self.removed)}"
    }
    
    func same(inventory: Inventory) -> Bool {
        return self.uuid == inventory.uuid
    }
    
    var hashValue: Int {
        return uuid.hashValue
    }
    
    func copy(uuid uuid: String? = nil, name: String? = nil, users: [SharedUser]? = nil, lastUpdate: NSDate? = nil, lastServerUpdate: NSDate? = nil, removed: Bool? = nil) -> Inventory {
        return Inventory(
            uuid: uuid ?? self.uuid,
            name: name ?? self.name,
            users: users ?? self.users,
            lastUpdate: lastUpdate ?? self.lastUpdate,
            lastServerUpdate: lastServerUpdate ?? self.lastServerUpdate,
            removed: removed ?? self.removed
        )
    }
}

func ==(lhs: Inventory, rhs: Inventory) -> Bool {
    return lhs.uuid == rhs.uuid
}