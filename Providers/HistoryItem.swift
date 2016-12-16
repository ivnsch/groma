//
//  HistoryItem.swift
//  shoppin
//
//  Created by ischuetz on 12/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

public class HistoryItem: Equatable, Identifiable, CustomDebugStringConvertible {
    
    public let uuid: String
    public let product: Product
    public let addedDate: Int64
    public let quantity: Int
    public let inventory: DBInventory
    public let user: DBSharedUser // The user who added the item. This is rather "User" because there's sharing for history items doesn't make sense, but user has information (like pw) which is irrelevant for this
    public let paidPrice: Float // product price at the moment of buying the item (per unit)
    //////////////////////////////////////////////
    // sync properties - FIXME - while Realm allows to return Realm objects from async op. This shouldn't be in model objects.
    // the idea is that we can return the db objs from query and then do sync directly with these objs so no need to put sync attributes in model objs
    // we could map the db objects to other db objs in order to work around the Realm issue, but this adds even more overhead, we make a lot of mappings already
    public let lastServerUpdate: Int64?
    public let removed: Bool
    //////////////////////////////////////////////
    
    public var totalPaidPrice: Float {
        return paidPrice * Float(quantity)
    }
    
    public init(uuid: String, inventory: DBInventory, product: Product, addedDate: Int64, quantity: Int, user: DBSharedUser, paidPrice: Float, lastServerUpdate: Int64? = nil, removed: Bool = false) {
        self.uuid = uuid
        self.inventory = inventory
        self.product = product
        self.addedDate = addedDate
        self.quantity = quantity
        self.user = user
        self.paidPrice = paidPrice
        self.lastServerUpdate = lastServerUpdate
        self.removed = removed
    }
    
    public func same(_ rhs: HistoryItem) -> Bool {
        return uuid == rhs.uuid
    }
    
    
    public var debugDescription: String {
        return "[uuid: \(uuid), product: \(product), paidPrice: \(paidPrice), quantity: \(quantity), addedDate: \(addedDate), user: \(user), inventory: \(inventory)]"
    }
    
    public func equalsExcludingSyncAttributes(_ rhs: HistoryItem) -> Bool {
        return uuid == rhs.uuid && product == rhs.product && addedDate == rhs.addedDate && quantity == rhs.quantity && inventory == rhs.inventory && user == rhs.user && paidPrice == rhs.paidPrice
    }
}

public func ==(lhs: HistoryItem, rhs: HistoryItem) -> Bool {
    return lhs.equalsExcludingSyncAttributes(rhs) && lhs.lastServerUpdate == rhs.lastServerUpdate && lhs.removed == rhs.removed
}

// convenience (redundant) holder to avoid having to iterate through historyitems to find unique products and users
// so products, users arrays are the result of extracting the unique products and users from historyItems array
public typealias HistoryItemsWithRelations = (historyItems: [HistoryItem], inventories: [DBInventory], products: [Product], users: [DBSharedUser])
