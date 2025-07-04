//
//  PlanItem.swift
//  shoppin
//
//  Created by ischuetz on 07/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

public class PlanItem: Equatable, Identifiable, CustomDebugStringConvertible {
    
    public let product: Product
    public let quantity: Float
    public let usedQuantity: Float
    public let inventory: DBInventory
    
    /** -- copied from InventoryItem --
    Quantity delta since last sync, to be able to do increment operation in server (if we would use a plain update instead we could overwrite possible quantity updates from other clients that participate in the inventory).
    This is always updated in paralel with quantity. E.g. if add 2 items to inventory, quantity as well as quantityDelta are incremented by 2.
    After a successful synchronization with the server (this may be at item level, or a full sync) quantityDelta is reset to 0
    */
    public let quantityDelta: Float
    
    //////////////////////////////////////////////
    // sync properties - FIXME - while Realm allows to return Realm objects from async op. This shouldn't be in model objects.
    // the idea is that we can return the db objs from query and then do sync directly with these objs so no need to put sync attributes in model objs
    // we could map the db objects to other db objs in order to work around the Realm issue, but this adds even more overhead, we make a lot of mappings already
    public let lastServerUpdate: Int64?
    public let removed: Bool
    //////////////////////////////////////////////
    
    // divided product in product and storeproduct so this has to be adapted
//    var totalPrice: Float {
//        return Float(quantity) * product.price / product.baseQuantity
//    }
    
    public init(inventory: DBInventory, product: Product, quantity: Float, quantityDelta: Float = 0, usedQuantity: Float, lastServerUpdate: Int64? = nil, removed: Bool = false) {
        self.inventory = inventory
        self.product = product
        self.quantity = quantity
        self.usedQuantity = usedQuantity
        self.lastServerUpdate = lastServerUpdate
        self.removed = removed
        self.quantityDelta = quantityDelta
    }
    
    public func copy(inventory: DBInventory? = nil, product: Product? = nil, quantity: Float? = nil, quantityDelta: Float? = nil, usedQuantity: Float? = nil, lastServerUpdate: Int64? = nil, removed: Bool? = nil) -> PlanItem {
        return PlanItem(
            inventory: inventory ?? self.inventory,
            product: product ?? self.product,
            quantity: quantity ?? self.quantity,
            quantityDelta: quantityDelta ?? self.quantityDelta,
            usedQuantity: usedQuantity ?? self.usedQuantity,
            lastServerUpdate: lastServerUpdate ?? self.lastServerUpdate,
            removed: removed ?? self.removed
        )
    }
    
    public func incrementQuantityCopy(_ delta: Float) -> PlanItem {
        return copy(quantity: quantity + delta, quantityDelta: quantityDelta + delta)
    }
    
    public func same(_ rhs: PlanItem) -> Bool {
        return self.product.item.name == rhs.product.item.name
    }
    
    public var debugDescription: String {
        return "{\(type(of: self)) product: \(product), quantity: \(quantity), usedQuantity: \(usedQuantity), quantityDelta: \(quantityDelta), inventory: \(inventory), lastServerUpdate: \(String(describing: lastServerUpdate))::\(String(describing: lastServerUpdate?.millisToEpochDate())), removed: \(removed)}"
    }
}

public func ==(lhs: PlanItem, rhs: PlanItem) -> Bool {
    return lhs.product.item.name == rhs.product.item.name && lhs.inventory.uuid == rhs.inventory.uuid && lhs.quantity == rhs.quantity
}


// convenience (redundant) holder to avoid having to iterate through historyitems to find unique products and users
// so products, users arrays are the result of extracting the unique products and users from historyItems array
// TODO do we need this, it's for remote parsing etc. copied from inventory item.
public typealias PlanItemsWithRelations = (planItems: [PlanItem], inventory: DBInventory, products: [Product])
