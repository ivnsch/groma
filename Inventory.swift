//
//  Inventory.swift
//  shoppin
//
//  Created by ischuetz on 21/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

class Inventory: Equatable, Hashable {
    let uuid: String
    let name: String
    
    let users: [SharedUser] // note that this will be empty if using the app offline (TODO think about showing myself in this list - right now also this will not appear offline)

    let bgColor: UIColor
    var order: Int
    
    //////////////////////////////////////////////
    // sync properties - FIXME - while Realm allows to return Realm objects from async op. This shouldn't be in model objects.
    // the idea is that we can return the db objs from query and then do sync directly with these objs so no need to put sync attributes in model objs
    // we could map the db objects to other db objs in order to work around the Realm issue, but this adds even more overhead, we make a lot of mappings already
    let lastServerUpdate: Int64?
    let removed: Bool
    //////////////////////////////////////////////
    
    init(uuid: String, name: String, users: [SharedUser] = [], bgColor: UIColor, order: Int, lastServerUpdate: Int64? = nil, removed: Bool = false) {
        self.uuid = uuid
        self.name = name
        self.users = users
        self.bgColor = bgColor
        self.order = order
        self.lastServerUpdate = lastServerUpdate
        self.removed = removed
    }

    var shortDebugDescription: String {
        return "{uuid: \(uuid), name: \(name), order: \(order)}"
    }
    
    var debugDescription: String {
        return "{\(type(of: self)) uuid: \(uuid), name: \(name), users: \(users), bgColor: \(bgColor), order: \(order), lastServerUpdate: \(lastServerUpdate)::\(lastServerUpdate?.millisToEpochDate()), removed: \(removed)}"
    }
    
    func same(_ inventory: Inventory) -> Bool {
        return self.uuid == inventory.uuid
    }
    
    var hashValue: Int {
        return uuid.hashValue
    }
    
    func copy(uuid: String? = nil, name: String? = nil, users: [SharedUser]? = nil, bgColor: UIColor? = nil, order: Int? = nil, lastServerUpdate: Int64? = nil, removed: Bool? = nil) -> Inventory {
        return Inventory(
            uuid: uuid ?? self.uuid,
            name: name ?? self.name,
            users: users ?? self.users,
            bgColor: bgColor ?? self.bgColor,
            order: order ?? self.order,
            lastServerUpdate: lastServerUpdate ?? self.lastServerUpdate,
            removed: removed ?? self.removed
        )
    }
    
    func equalsExcludingSyncAttributes(_ rhs: Inventory) -> Bool {
        return uuid == rhs.uuid && name == rhs.name && bgColor == rhs.bgColor && order == rhs.order && users == rhs.users
    }
}

func ==(lhs: Inventory, rhs: Inventory) -> Bool {
    return lhs.equalsExcludingSyncAttributes(rhs) && lhs.lastServerUpdate == rhs.lastServerUpdate && lhs.removed == rhs.removed
}
