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
    let group: ListItemGroup
    
    //////////////////////////////////////////////
    // sync properties - FIXME - while Realm allows to return Realm objects from async op. This shouldn't be in model objects.
    // the idea is that we can return the db objs from query and then do sync directly with these objs so no need to put sync attributes in model objs
    // we could map the db objects to other db objs in order to work around the Realm issue, but this adds even more overhead, we make a lot of mappings already
    let lastServerUpdate: Int64?
    let removed: Bool
    //////////////////////////////////////////////
    
    
    init(uuid: String, quantity: Int, product: Product, group: ListItemGroup, lastServerUpdate: Int64? = nil, removed: Bool = false) {
        self.uuid = uuid
        self.quantity = quantity
        self.product = product
        self.group = group
        self.lastServerUpdate = lastServerUpdate
        self.removed = removed
    }
    
    func same(_ gropItem: GroupItem) -> Bool {
        return self.uuid == gropItem.uuid
    }
    
    var shortDebugDescription: String {
        return "{\(type(of: self)) product: \(self.product.name), quantity: \(self.quantity)}"
    }
    
    var completeDebugDescription: String {
        return "{\(type(of: self)) uuid: \(self.uuid), quantity: \(self.quantity), product: \(self.product), group: \(self.group), lastServerUpdate: \(lastServerUpdate)::\(lastServerUpdate?.millisToEpochDate()), removed: \(self.removed)}"
    }
    
    var debugDescription: String {
        return shortDebugDescription
//        return completeDebugDescription
    }
    
    func copy(uuid: String? = nil, quantity: Int? = nil, product: Product? = nil, group: ListItemGroup? = nil, order: Int? = nil) -> GroupItem {
        return GroupItem(
            uuid: uuid ?? self.uuid,
            quantity: quantity ?? self.quantity,
            product: product ?? self.product.copy(),
            group: group ?? self.group,
            lastServerUpdate: self.lastServerUpdate,
            removed: self.removed
        )
    }
    
    func incrementQuantityCopy(_ delta: Int) -> GroupItem {
        return copy(quantity: quantity + delta)
    }
    
    func equalsExcludingSyncAttributes(_ rhs: GroupItem) -> Bool {
        return uuid == rhs.uuid && quantity == rhs.quantity && product == rhs.product && group == rhs.group
    }
}

// TODO implement equality correctly, also in other model classes. Now we have identifiable for this.
func ==(lhs: GroupItem, rhs: GroupItem) -> Bool {
    return lhs.equalsExcludingSyncAttributes(rhs) && lhs.lastServerUpdate == rhs.lastServerUpdate && lhs.removed == rhs.removed
}

// convenience (redundant) holder to avoid having to iterate through group items to find unique products and groups
typealias GroupItemsWithRelations = (groupItems: [GroupItem], products: [Product], groups: [ListItemGroup])
