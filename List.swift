//
//  List.swift
//  shoppin
//
//  Created by ischuetz on 01.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

class List: Equatable, Identifiable, Hashable, CustomDebugStringConvertible {
    let uuid: String
    let name: String
    let listItems: [ListItem] // TODO is this used? we get the items everywhere from the provider not the list object
    
    let users: [SharedUser] // note that this will be empty if using the app offline (TODO think about showing myself in this list - right now also this will not appear offline)
    
    let bgColor: UIColor
    var order: Int

    let inventory: Inventory
    
    //////////////////////////////////////////////
    // sync properties - FIXME - while Realm allows to return Realm objects from async op. This shouldn't be in model objects.
    // the idea is that we can return the db objs from query and then do sync directly with these objs so no need to put sync attributes in model objs
    // we could map the db objects to other db objs in order to work around the Realm issue, but this adds even more overhead, we make a lot of mappings already
    let lastUpdate: NSDate
    let lastServerUpdate: NSDate?
    let removed: Bool
    //////////////////////////////////////////////
    
    init(uuid: String, name: String, listItems: [ListItem] = [], users: [SharedUser] = [], bgColor: UIColor, order: Int, inventory: Inventory, lastUpdate: NSDate = NSDate(), lastServerUpdate: NSDate? = nil, removed: Bool = false) {
        self.uuid = uuid
        self.name = name
        self.listItems = listItems
        self.users = users
        self.bgColor = bgColor
        self.order = order
        self.inventory = inventory
        self.lastUpdate = lastUpdate
        self.lastServerUpdate = lastServerUpdate
        self.removed = removed
    }

    var shortDebugDescription: String {
        return "{uuid: \(uuid), name: \(name), order: \(order)}"
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(uuid), name: \(name), bgColor: \(bgColor), order: \(order), inventory: \(inventory), lastUpdate: \(lastUpdate), lastServerUpdate: \(lastServerUpdate), removed: \(removed)}"
    }
    
    func same(rhs: List) -> Bool {
        return self.uuid == rhs.uuid
    }
    
    var hashValue: Int {
        return uuid.hashValue
    }
    
    func copy(uuid uuid: String? = nil, name: String? = nil, listItems: [ListItem]? = nil, users: [SharedUser]? = nil, bgColor: UIColor? = nil, order: Int? = nil, inventory: Inventory? = nil, lastUpdate: NSDate? = nil, lastServerUpdate: NSDate? = nil, removed: Bool? = nil) -> List {
        return List(
            uuid: uuid ?? self.uuid,
            name: name ?? self.name,
            listItems: listItems ?? self.listItems,
            users: users ?? self.users,
            bgColor: bgColor ?? self.bgColor,
            order: order ?? self.order,
            inventory: inventory ?? self.inventory,
            lastUpdate: lastUpdate ?? self.lastUpdate,
            lastServerUpdate: lastServerUpdate ?? self.lastServerUpdate,
            removed: removed ?? self.removed
        )
    }
}

// TODO implement equality correctly, also in other model classes. Now we have identifiable for this.
func ==(lhs: List, rhs: List) -> Bool {
    return lhs.uuid == rhs.uuid
}
