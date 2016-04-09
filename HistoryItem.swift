//
//  HistoryItem.swift
//  shoppin
//
//  Created by ischuetz on 12/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class HistoryItem: Equatable, Identifiable, CustomDebugStringConvertible {
    
    let uuid: String
    let product: Product
    let addedDate: NSDate
    let quantity: Int
    let inventory: Inventory
    let user: SharedUser // The user who added the item. This is rather "User" because there's sharing for history items doesn't make sense, but user has information (like pw) which is irrelevant for this
    let paidPrice: Float // product price at the moment of buying the item (per unit)
    //////////////////////////////////////////////
    // sync properties - FIXME - while Realm allows to return Realm objects from async op. This shouldn't be in model objects.
    // the idea is that we can return the db objs from query and then do sync directly with these objs so no need to put sync attributes in model objs
    // we could map the db objects to other db objs in order to work around the Realm issue, but this adds even more overhead, we make a lot of mappings already
    let lastUpdate: NSDate
    let lastServerUpdate: NSDate?
    let removed: Bool
    //////////////////////////////////////////////
    
    var totalPaidPrice: Float {
        return paidPrice * Float(quantity)
    }
    
    init(uuid: String, inventory: Inventory, product: Product, addedDate: NSDate, quantity: Int, user: SharedUser, paidPrice: Float, lastUpdate: NSDate = NSDate(), lastServerUpdate: NSDate? = nil, removed: Bool = false) {
        self.uuid = uuid
        self.inventory = inventory
        self.product = product
        self.addedDate = addedDate
        self.quantity = quantity
        self.user = user
        self.paidPrice = paidPrice
        self.lastUpdate = lastUpdate
        self.lastServerUpdate = lastServerUpdate
        self.removed = removed
    }
    
    func same(rhs: HistoryItem) -> Bool {
        return uuid == rhs.uuid
    }
    
    
    var debugDescription: String {
        return "[uuid: \(uuid), product: \(product), paidPrice: \(paidPrice), quantity: \(quantity), addedDate: \(addedDate), user: \(user), inventory: \(inventory)]"
    }
}

func ==(lhs: HistoryItem, rhs: HistoryItem) -> Bool {
    return lhs.uuid == rhs.uuid
}


// convenience (redundant) holder to avoid having to iterate through historyitems to find unique products and users
// so products, users arrays are the result of extracting the unique products and users from historyItems array
typealias HistoryItemsWithRelations = (historyItems: [HistoryItem], inventories: [Inventory], products: [Product], users: [SharedUser])