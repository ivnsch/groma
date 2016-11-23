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

    dynamic var uuid: String = ""
    dynamic var quantity: Int = 0
    dynamic var quantityDelta: Int = 0
    dynamic var productOpt: DBProduct? = DBProduct()
    dynamic var inventoryOpt: DBInventory? = DBInventory()

    static var quantityFieldName: String {
        return "quantity"
    }
    
    override static func primaryKey() -> String? {
        return "uuid"
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

    static func createFilterUuid(_ uuid: String) -> String {
        return "uuid = '\(uuid)'"
    }
    
    static func createFilter(_ item: InventoryItem) -> String {
        return createFilter(item.product.uuid, item.inventory.uuid)
    }
    
    static func createFilter(_ product: Product, _ inventory: Inventory) -> String {
        return createFilter(ProductUnique(name: product.name, brand: product.brand), inventoryUuid: inventory.uuid)
    }

    static func createFilter(_ productUnique: ProductUnique, inventoryUuid: String) -> String {
        return "\(createFilterInventory(inventoryUuid)) AND productOpt.name = '\(productUnique.name)' AND productOpt.brand = '\(productUnique.brand)'"
    }

    static func createFilter(_ productUnique: ProductUnique, inventoryUuid: String, notUuid: String) -> String {
        return "\(createFilterInventory(inventoryUuid)) AND productOpt.name = '\(productUnique.name)' AND productOpt.brand = '\(productUnique.brand)' AND uuid != '\(notUuid)'"
    }
    
    static func createFilter(_ productUuid: String, _ inventoryUuid: String) -> String {
        return "productOpt.uuid = '\(productUuid)' AND inventoryOpt.uuid = '\(inventoryUuid)'"
    }
    
    static func createFilterInventory(_ inventoryUuid: String) -> String {
        return "inventoryOpt.uuid = '\(inventoryUuid)'"
    }
    
    static func createFilterWithProduct(_ productUuid: String) -> String {
        return "productOpt.uuid == '\(productUuid)'"
    }
    
    // MARK: -
    
    static func fromDict(_ dict: [String: AnyObject], product: DBProduct, inventory: DBInventory) -> DBInventoryItem {
        let item = DBInventoryItem()
        item.uuid = dict["uuid"]! as! String
        item.quantity = dict["quantity"]! as! Int
        // Note: we don't set quantity delta here because when we gets objs from server it means they are synced, which means there's no quantity delta.
        item.product = product
        item.inventory = inventory
        item.setSyncableFieldswithRemoteDict(dict)
        return item
    }
    
    func toDict() -> [String: AnyObject] {
        var dict = [String: AnyObject]()
        dict["uuid"] = uuid as AnyObject?
        dict["quantity"] = quantity as AnyObject?
//        dict["quantityDelta"] = quantityDelta
        dict["product"] = product.toDict() as AnyObject?
//        dict["inventory"] = inventory.toDict()
        dict["inventoryUuid"] = inventory.uuid as AnyObject?
        setSyncableFieldsInDict(&dict)
        return dict
    }
    
    override static func ignoredProperties() -> [String] {
        return ["product", "inventory"]
    }
}
