//
//  InventoryItem.swift
//  shoppin
//
//  Created by ischuetz on 04.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

class InventoryItem: Equatable, Identifiable, CustomDebugStringConvertible {
    let uuid: String
    let quantity: Int // TODO?
    let product: Product
    let inventory: DBInventory
    
    /** 
    Quantity delta since last sync, to be able to do increment operation in server (if we would use a plain update instead we could overwrite possible quantity updates from other clients that participate in the inventory).
    This is always updated in paralel with quantity. E.g. if add 2 items to inventory, quantity as well as quantityDelta are incremented by 2.
    After a successful synchronization with the server (this may be at item level, or a full sync) quantityDelta is reset to 0
    */
    let quantityDelta: Int
    
    //////////////////////////////////////////////
    // sync properties - FIXME - while Realm allows to return Realm objects from async op. This shouldn't be in model objects.
    // the idea is that we can return the db objs from query and then do sync directly with these objs so no need to put sync attributes in model objs
    // we could map the db objects to other db objs in order to work around the Realm issue, but this adds even more overhead, we make a lot of mappings already
    let lastServerUpdate: Int64?
    let removed: Bool
    //////////////////////////////////////////////
    
    init(uuid: String, quantity: Int = 0, quantityDelta: Int = 0, product: Product, inventory: DBInventory, lastServerUpdate: Int64? = nil, removed: Bool = false) {
        self.uuid = uuid
        self.quantity = quantity
        self.product = product
        self.inventory = inventory
        self.lastServerUpdate = lastServerUpdate
        self.removed = removed
        self.quantityDelta = quantityDelta
    }

    var shortDebugDescription: String {
        return "{\(type(of: self)) uuid: \(uuid), product: \(product.name), quantity: \(quantity), quantityDelta: \(quantityDelta), quantity: \(quantity)}"
    }

    var completeDebugDescription: String {
        return "{\(type(of: self)) product: \(product), quantity: \(quantity), quantityDelta: \(quantityDelta), inventory: \(inventory), lastServerUpdate: \(lastServerUpdate)::\(lastServerUpdate?.millisToEpochDate()), removed: \(removed)}"
    }
    
    var debugDescription: String {
        return shortDebugDescription
    }
    
    func same(_ inventoryItem: InventoryItem) -> Bool {
        return uuid == inventoryItem.uuid
    }
    
    func copy(uuid: String? = nil, quantity: Int? = nil, quantityDelta: Int? = nil, product: Product? = nil, inventory: DBInventory? = nil, lastServerUpdate: Int64? = nil, removed: Bool? = nil) -> InventoryItem {
        return InventoryItem(
            uuid: uuid ?? self.uuid,
            quantity: quantity ?? self.quantity,
            quantityDelta: quantityDelta ?? self.quantityDelta,
            product: product ?? self.product,
            inventory: inventory ?? self.inventory,
            lastServerUpdate: lastServerUpdate ?? self.lastServerUpdate,
            removed: removed ?? self.removed
        )
    }
    
    func incrementQuantityCopy(_ delta: Int) -> InventoryItem {
        return copy(quantity: quantity + delta, quantityDelta: quantityDelta + delta)
    }
    
    func equalsExcludingSyncAttributes(_ rhs: InventoryItem) -> Bool {
        return uuid == rhs.uuid && product == rhs.product && inventory.uuid == rhs.inventory.uuid && quantity == rhs.quantity
    }
}

func ==(lhs: InventoryItem, rhs: InventoryItem) -> Bool {
    return lhs.equalsExcludingSyncAttributes(rhs) && lhs.lastServerUpdate == rhs.lastServerUpdate && lhs.removed == rhs.removed
}
