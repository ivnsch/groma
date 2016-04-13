//
//  List.swift
//  shoppin
//
//  Created by ischuetz on 01.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

// Used for copy - for store which is itself an optional field, we would not be able to overwrite with a nil value (which would cause to use the value of the copied instance instead), so we wrap it instead an in another object, which correctly signalises if the caller intends to overwrite the parameter or not. If ListCopyStore is not nil, we overwrite store which whatever is passed as store, also nil.
struct ListCopyStore {
    let store: String?
    init(_ store: String?) {
        self.store = store
    }
}

class List: Equatable, Identifiable, Hashable, CustomDebugStringConvertible {
    let uuid: String
    let name: String
    let listItems: [ListItem] // TODO is this used? we get the items everywhere from the provider not the list object
    
    let users: [SharedUser] // note that this will be empty if using the app offline (TODO think about showing myself in this list - right now also this will not appear offline)
    
    let bgColor: UIColor
    var order: Int

    let store: String?
    
    let inventory: Inventory
    
    //////////////////////////////////////////////
    // sync properties - FIXME - while Realm allows to return Realm objects from async op. This shouldn't be in model objects.
    // the idea is that we can return the db objs from query and then do sync directly with these objs so no need to put sync attributes in model objs
    // we could map the db objects to other db objs in order to work around the Realm issue, but this adds even more overhead, we make a lot of mappings already
    let lastServerUpdate: Int64?
    let removed: Bool
    //////////////////////////////////////////////
    
    init(uuid: String, name: String, listItems: [ListItem] = [], users: [SharedUser] = [], bgColor: UIColor, order: Int, inventory: Inventory, store: String?, lastServerUpdate: Int64? = nil, removed: Bool = false) {
        self.uuid = uuid
        self.name = name
        self.listItems = listItems
        self.users = users
        self.bgColor = bgColor
        self.order = order
        self.inventory = inventory
        self.store = store
        self.lastServerUpdate = lastServerUpdate
        self.removed = removed
    }

    var shortDebugDescription: String {
        return "{uuid: \(uuid), name: \(name), order: \(order)}"
    }
    
    var debugDescription: String {
//        return shortDebugDescription
        return "{\(self.dynamicType) uuid: \(uuid), name: \(name), bgColor: \(bgColor), order: \(order), inventory: \(inventory), store: \(store), lastServerUpdate: \(lastServerUpdate)::\(lastServerUpdate?.millisToEpochDate()), removed: \(removed)}"
    }
    
    func same(rhs: List) -> Bool {
        return self.uuid == rhs.uuid
    }
    
    var hashValue: Int {
        return uuid.hashValue
    }
    
    func copy(uuid uuid: String? = nil, name: String? = nil, listItems: [ListItem]? = nil, users: [SharedUser]? = nil, bgColor: UIColor? = nil, order: Int? = nil, inventory: Inventory? = nil, store: ListCopyStore? = nil, lastServerUpdate: Int64? = nil, removed: Bool? = nil) -> List {
        return List(
            uuid: uuid ?? self.uuid,
            name: name ?? self.name,
            listItems: listItems ?? self.listItems,
            users: users ?? self.users,
            bgColor: bgColor ?? self.bgColor,
            order: order ?? self.order,
            inventory: inventory ?? self.inventory,
            store: store.map{$0.store} ?? self.store,
            lastServerUpdate: lastServerUpdate ?? self.lastServerUpdate,
            removed: removed ?? self.removed
        )
    }
    
    // WARN: doesn't include listItems. Actually, should we remove list items from list? this is never used?
    func equalsExcludingSyncAttributes(rhs: List) -> Bool {
        return self.uuid == rhs.uuid && self.name == rhs.name && self.bgColor == rhs.bgColor && self.order == rhs.order && self.inventory == rhs.inventory && self.store == rhs.store
    }
}

func ==(lhs: List, rhs: List) -> Bool {
    return lhs.equalsExcludingSyncAttributes(rhs) && lhs.lastServerUpdate == rhs.lastServerUpdate && lhs.removed == rhs.removed
}