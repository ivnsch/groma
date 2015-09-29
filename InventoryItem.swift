//
//  InventoryItem.swift
//  shoppin
//
//  Created by ischuetz on 04.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

class InventoryItem: Equatable, Identifiable, CustomDebugStringConvertible {
    let quantity: Int // TODO?
    let product: Product
    let inventory: Inventory
    
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
    let lastUpdate: NSDate
    let lastServerUpdate: NSDate?
    let removed: Bool
    //////////////////////////////////////////////
    
    init(quantity: Int = 0, quantityDelta: Int = 0, product: Product, inventory: Inventory, lastUpdate: NSDate = NSDate(), lastServerUpdate: NSDate? = nil, removed: Bool = false) {
        self.quantity = quantity
        self.product = product
        self.inventory = inventory
        self.lastUpdate = lastUpdate
        self.lastServerUpdate = lastServerUpdate
        self.removed = removed
        self.quantityDelta = quantityDelta
    }

    var shortDebugDescription: String {
        return "{\(self.dynamicType) product: \(self.product.name), quantity: \(self.quantity), quantityDelta: \(self.quantityDelta), quantity: \(self.quantity)}"
    }

    var completeDebugDescription: String {
        return "{\(self.dynamicType) product: \(self.product), quantity: \(self.quantity), quantityDelta: \(self.quantityDelta), inventory: \(self.inventory), lastUpdate: \(self.lastUpdate), lastServerUpdate: \(self.lastServerUpdate), removed: \(self.removed)}"
    }
    
    var debugDescription: String {
        return shortDebugDescription
    }
    
    func same(inventoryItem: InventoryItem) -> Bool {
        return product.uuid == inventoryItem.product.uuid && inventory.uuid == inventoryItem.inventory.uuid
    }
    
    func copy(quantity quantity: Int? = nil, quantityDelta: Int? = nil, product: Product? = nil, inventory: Inventory? = nil, lastUpdate: NSDate? = nil, lastServerUpdate: NSDate? = nil, removed: Bool? = nil) -> InventoryItem {
        return InventoryItem(
            quantity: quantity ?? self.quantity,
            quantityDelta: quantityDelta ?? self.quantityDelta,
            product: product ?? self.product,
            inventory: inventory ?? self.inventory,
            lastUpdate: lastUpdate ?? self.lastUpdate,
            lastServerUpdate: lastServerUpdate ?? self.lastServerUpdate,
            removed: removed ?? self.removed
        )
    }
    
    func incrementQuantityCopy(delta: Int) -> InventoryItem {
        return copy(quantity: quantity + delta, quantityDelta: quantityDelta + delta)
    }
}

func ==(lhs: InventoryItem, rhs: InventoryItem) -> Bool {
    return lhs.product.uuid == rhs.product.uuid && lhs.inventory.uuid == rhs.inventory.uuid && lhs.quantity == rhs.quantity
}