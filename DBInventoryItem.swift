//
//  DBInventoryItem.swift
//  shoppin
//
//  Created by ischuetz on 16/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class DBInventoryItem: DBSyncable {
    
    dynamic var quantity: Int = 0
    dynamic var quantityDelta: Int = 0
    dynamic var productOpt: DBProduct? = DBProduct()
    dynamic var inventoryOpt: DBInventory? = DBInventory()
    
    dynamic lazy var compoundKey: String? = self.compoundKeyValue()

    private func compoundKeyValue() -> String? {
        let productUuid = productOpt?.uuid ?? ""
        let inventoryUuid = inventoryOpt?.uuid ?? ""
        return "\(productUuid)-\(inventoryUuid)"
    }

    override static func primaryKey() -> String {
        return "compoundKey"
    }
    
    var product: DBProduct {
        get {
            return productOpt ?? DBProduct()
        }
        set(newProduct) {
            productOpt = newProduct
        }
    }
    
    var inventory: DBInventory {
        get {
            return inventoryOpt ?? DBInventory()
        }
        set(newInventory) {
            inventoryOpt = newInventory
        }
    }
    
    // MARK: - Filters

    static func createFilter(item: InventoryItem) -> String {
        return createFilter(item.product.uuid, item.inventory.uuid)
    }
    
    static func createFilter(product: Product, _ inventory: Inventory) -> String {
        return createFilter(product.uuid, inventory.uuid)
    }
    
    static func createFilter(productUuid: String, _ inventoryUuid: String) -> String {
        return "productOpt.uuid = '\(productUuid)' AND inventoryOpt.uuid = '\(inventoryUuid)'"
    }

    static func createFilter(inventoryUuid: String) -> String {
        return "inventoryOpt.uuid = '\(inventoryUuid)'"
    }
    
    static func createFilterWithProduct(productUuid: String) -> String {
        return "productOpt.uuid == '\(productUuid)'"
    }
    
    // MARK: -
    
    static func fromDict(dict: [String: AnyObject], product: DBProduct, inventory: DBInventory) -> DBInventoryItem {
        let item = DBInventoryItem()
        item.quantity = dict["quantity"]! as! Int
        // Note: we don't set quantity delta here because when we gets objs from server it means they are synced, which means there's no quantity delta.
        item.product = product
        item.inventory = inventory
        item.setSyncableFieldswithRemoteDict(dict)
        return item
    }
    
    func toDict() -> [String: AnyObject] {
        var dict = [String: AnyObject]()
        dict["quantity"] = quantity
        dict["quantityDelta"] = quantityDelta
        dict["product"] = product.toDict()
//        dict["inventory"] = inventory.toDict()
        dict["inventoryUuid"] = inventory.uuid
        setSyncableFieldsInDict(dict)
        return dict
    }
    
    override static func ignoredProperties() -> [String] {
        return ["product", "inventory"]
    }
}