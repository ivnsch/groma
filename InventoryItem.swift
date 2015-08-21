//
//  InventoryItem.swift
//  shoppin
//
//  Created by ischuetz on 04.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

class InventoryItem: Equatable {
    let quantity: Int // TODO?
    let product: Product
    let inventory: Inventory
    
    let quantityDelta: Int // quantity delta since last sync, to be able to do increment operation in server. I we would use a plain update instead we could overwrite possible quantity updates from other clients that participate in the inventory)
    
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
    
    var debugDescription: String {
        return "{\(self.dynamicType) quantity: \(self.quantity), product: \(self.product), inventory: \(self.inventory), lastUpdate: \(self.lastUpdate), lastServerUpdate: \(self.lastServerUpdate), removed: \(self.removed)}"
    }
}

func ==(lhs: InventoryItem, rhs: InventoryItem) -> Bool {
    return lhs.product.uuid == rhs.product.uuid && lhs.inventory.uuid == rhs.inventory.uuid && lhs.quantity == rhs.quantity
}