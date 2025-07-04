//
//  InventoryItem.swift
//  shoppin
//
//  Created by ischuetz on 16/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

public final class InventoryItem: DBSyncable, Identifiable, ProductWithQuantity2, WithUuid {

    @objc public dynamic var uuid: String = ""
    @objc public dynamic var quantity: Float = 0
    @objc dynamic var productOpt: QuantifiableProduct? = QuantifiableProduct()
    @objc dynamic var inventoryOpt: DBInventory? = DBInventory()

    public static var quantityFieldName: String {
        return "quantity"
    }
    
    public override static func primaryKey() -> String? {
        return "uuid"
    }
    
    public var product: QuantifiableProduct {
        get {
            return productOpt ?? QuantifiableProduct()
        }
        set(newProduct) {
            productOpt = newProduct
        }
    }
    
    public var inventory: DBInventory {
        get {
            return inventoryOpt ?? DBInventory()
        }
        set(newInventory) {
            inventoryOpt = newInventory
        }
    }
    
    public convenience init(uuid: String, quantity: Float = 0, product: QuantifiableProduct, inventory: DBInventory, lastServerUpdate: Int64? = nil, removed: Bool = false) {
        self.init()
        
        self.uuid = uuid
        self.quantity = quantity
        self.product = product
        self.inventory = inventory
        
        if let lastServerUpdate = lastServerUpdate {
            self.lastServerUpdate = lastServerUpdate
        }
        self.removed = removed
    }
    
    // MARK: - Filters

    static func createFilterUuid(_ uuid: String) -> NSPredicate {
        return NSPredicate(format: "uuid = %@", uuid)
    }

    static func createFilterInventory(_ inventoryUuid: String) -> NSPredicate {
        return NSPredicate(format: "inventoryOpt.uuid = %@", inventoryUuid)
    }

    static func createFilter(quantifiableProductUuid: String) -> NSPredicate {
        return NSPredicate(format: "productOpt.uuid = %@", quantifiableProductUuid)
    }

    static func createFilterUuids(_ uuids: [String]) -> NSPredicate {
        return NSPredicate(format: "uuid IN %@", uuids)
    }

    fileprivate static func createFilter(itemName: String) -> NSPredicate {
        return NSPredicate(format: "productOpt.productOpt.itemOpt.name = %@", itemName)
    }

    fileprivate static func createFilter(brand: String) -> NSPredicate {
        return NSPredicate(format: "productOpt.productOpt.brand = %@", brand)
    }

    static func createFilter(quantifiableProductUnique: QuantifiableProductUnique, inventoryUuid: String) -> NSPredicate {
        let productUnique = ProductUnique(name: quantifiableProductUnique.name, brand: quantifiableProductUnique.brand)
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            createFilter(productUnique, inventoryUuid: inventoryUuid),
            NSPredicate(format: "productOpt.unitOpt.name = %@", quantifiableProductUnique.unit),
            NSPredicate(format: "productOpt.baseQuantity = %f", quantifiableProductUnique.baseQuantity),
            NSPredicate(format: "productOpt.secondBaseQuantity = %f", quantifiableProductUnique.secondBaseQuantity)
        ])
    }
    
    static func createFilter(_ productUnique: ProductUnique, inventoryUuid: String) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            createFilterInventory(inventoryUuid),
            createFilter(itemName: productUnique.name),
            createFilter(brand: productUnique.brand)
        ])
    }

    static func createFilter(_ productUnique: ProductUnique, inventoryUuid: String, notUuid: String) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            createFilterInventory(inventoryUuid),
            createFilter(itemName: productUnique.name),
            createFilter(brand: productUnique.brand),
            NSPredicate(format: "uuid != %@", notUuid)
        ])
    }
    
    static func createFilter(productUuid: String, inventoryUuid: String) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "productOpt.productOpt.uuid = %@", productUuid),
            NSPredicate(format: "inventoryOpt.uuid = %@", inventoryUuid)
        ])
    }

    static func createFilter(_ item: InventoryItem) -> NSPredicate {
        return createFilter(productUuid: item.product.uuid, inventoryUuid: item.inventory.uuid)
    }

    static func createFilter(_ product: QuantifiableProduct, _ inventory: DBInventory) -> NSPredicate {
        return createFilter(quantifiableProductUnique: product.unique, inventoryUuid: inventory.uuid)
    }

    // MARK: -
    
    static func fromDict(_ dict: [String: AnyObject], product: QuantifiableProduct, inventory: DBInventory) -> InventoryItem {
        let item = InventoryItem()
        item.uuid = dict["uuid"]! as! String
        item.quantity = dict["quantity"]! as! Float
        // Note: we don't set quantity delta here because when we gets objs from server it means they are synced, which means there's no quantity delta.
        item.product = product
        item.inventory = inventory
        item.setSyncableFieldswithRemoteDict(dict)
        return item
    }
    
    public func toDict() -> [String: AnyObject] {
        let dict = [String: AnyObject]()
        // Disabled because structural changes
//        dict["uuid"] = uuid as AnyObject?
//        dict["quantity"] = quantity as AnyObject?
////        dict["quantityDelta"] = quantityDelta
//        dict["product"] = product.toDict() as AnyObject?
////        dict["inventory"] = inventory.toDict()
//        dict["inventoryUuid"] = inventory.uuid as AnyObject?
//        setSyncableFieldsInDict(&dict)
        return dict
    }
    
    public override static func ignoredProperties() -> [String] {
        return ["product", "inventory"]
    }
    
    public func copy(uuid: String? = nil, quantity: Float? = nil, product: QuantifiableProduct? = nil, inventory: DBInventory? = nil, lastServerUpdate: Int64? = nil, removed: Bool? = nil) -> InventoryItem {
        return InventoryItem(
            uuid: uuid ?? self.uuid,
            quantity: quantity ?? self.quantity,
            product: product ?? self.product.copy(),
            inventory: inventory ?? self.inventory.copy(),
            lastServerUpdate: lastServerUpdate ?? self.lastServerUpdate,
            removed: removed ?? self.removed
        )
    }

    
    
    
    public func incrementQuantityCopy(_ delta: Float) -> InventoryItem {
        return copy(quantity: quantity + delta)
    }
    
    public func same(_ inventoryItem: InventoryItem) -> Bool {
        return uuid == inventoryItem.uuid
    }

    func toRealmMigrationDict(product: QuantifiableProduct, inventory: DBInventory) -> [String: Any] {
        var dict = [String: Any]()
        dict["uuid"] = uuid
        dict["quantity"] = quantity as AnyObject?

        dict["productOpt"] = product
        dict["inventoryOpt"] = inventory

        return dict
    }
    
    // MARK: - ProductWithQuantity2
    
    public func updateQuantityCopy(_ quantity: Float) -> InventoryItem {
        return copy(quantity: quantity)
    }
}
