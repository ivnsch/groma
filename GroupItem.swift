//
//  GroupItem.swift
//  shoppin
//
//  Created by ischuetz on 15/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

class GroupItem: Equatable, Identifiable, CustomDebugStringConvertible {
    let uuid: String
    let quantity: Int
    let product: Product
    
    //////////////////////////////////////////////
    // sync properties - FIXME - while Realm allows to return Realm objects from async op. This shouldn't be in model objects.
    // the idea is that we can return the db objs from query and then do sync directly with these objs so no need to put sync attributes in model objs
    // we could map the db objects to other db objs in order to work around the Realm issue, but this adds even more overhead, we make a lot of mappings already
    let lastUpdate: NSDate
    let lastServerUpdate: NSDate?
    let removed: Bool
    //////////////////////////////////////////////
    
    
    init(uuid: String, quantity: Int, product: Product, lastUpdate: NSDate = NSDate(), lastServerUpdate: NSDate? = nil, removed: Bool = false) {
        self.uuid = uuid
        self.quantity = quantity
        self.product = product
        self.lastUpdate = lastUpdate
        self.lastServerUpdate = lastServerUpdate
        self.removed = removed
    }
    
    func same(gropItem: GroupItem) -> Bool {
        return self.uuid == gropItem.uuid
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(self.uuid), quantity: \(self.quantity), product: \(self.product), lastUpdate: \(self.lastUpdate), lastServerUpdate: \(self.lastServerUpdate), removed: \(self.removed)}"
    }
    
    func copy(uuid uuid: String? = nil, quantity: Int? = nil, product: Product? = nil, order: Int? = nil) -> GroupItem {
        return GroupItem(
            uuid: uuid ?? self.uuid,
            quantity: quantity ?? self.quantity,
            product: product ?? self.product,
            lastUpdate: self.lastUpdate,
            lastServerUpdate: self.lastServerUpdate,
            removed: self.removed
        )
    }
}

// TODO implement equality correctly, also in other model classes. Now we have identifiable for this.
func ==(lhs: GroupItem, rhs: GroupItem) -> Bool {
    return lhs.uuid == rhs.uuid
}