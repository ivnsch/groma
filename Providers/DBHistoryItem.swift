//
//  DBHistoryItem.swift
//  shoppin
//
//  Created by ischuetz on 12/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

public class DBHistoryItem: DBSyncable {

    public dynamic var uuid: String = ""
    dynamic var inventoryOpt: DBInventory? = DBInventory()
    dynamic var productOpt: Product? = Product()
    public dynamic var addedDate: Int64 = 0
    public dynamic var quantity: Int = 0
    dynamic var userOpt: DBSharedUser? = DBSharedUser()
    public dynamic var paidPrice: Float = 0 // product price at the moment of buying the item (per unit)
    
    public static let addedDateKey = "addedDate"
    
    public override static func primaryKey() -> String? {
        return "uuid"
    }
    
    public var product: Product {
        get {
            return productOpt ?? Product()
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
    
    public var user: DBSharedUser {
        get {
            return userOpt ?? DBSharedUser()
        }
        set(newUser) {
            userOpt = newUser
        }
    }
    
    // MARK: - Filters
    
    static func createFilter(_ uuid: String) -> String {
        return "uuid == '\(uuid)'"
    }
    
    static func createFilterWithProduct(_ productUuid: String) -> String {
        return "productOpt.uuid == '\(productUuid)'"
    }
    
    static func createFilterWithInventory(_ inventoryUuid: String) -> String {
        return "inventoryOpt.uuid == '\(inventoryUuid)'"
    }

    static func createFilter(_ historyItemGroup: HistoryItemGroup) -> String {
        let historyItemsUuidsStr: String = historyItemGroup.historyItems.map{"'\($0.uuid)'"}.joined(separator: ",")
        return "uuid IN {\(historyItemsUuidsStr)}"
    }
    
    static func createPredicate(_ addedDate: Int64, inventoryUuid: String) -> NSPredicate {
        return NSPredicate(format: "addedDate >= %@ AND inventoryOpt.uuid == %@", NSNumber(value: Int64(addedDate) as Int64), inventoryUuid)
    }
    
    static func createPredicate(_ productName: String, addedDate: Int64, inventoryUuid: String) -> NSPredicate {
        return NSPredicate(format: "productOpt.name == %@ AND addedDate >= %@ AND inventoryOpt.uuid == %@", productName, NSNumber(value: Int64(addedDate) as Int64), inventoryUuid)
    }
    
    static func createPredicate(_ startAddedDate: Int64, endAddedDate: Int64, inventoryUuid: String) -> NSPredicate {
        return NSPredicate(format: "addedDate >= %@ AND addedDate <= %@ AND inventoryOpt.uuid == %@", NSNumber(value: Int64(startAddedDate) as Int64), NSNumber(value: Int64(endAddedDate) as Int64), inventoryUuid)
    }
    
    static func createPredicateOlderThan(_ addedDate: Int64) -> NSPredicate {
        return NSPredicate(format: "addedDate < %@", NSNumber(value: Int64(addedDate) as Int64))
    }
    
    
    // MARK: -

    
    // TODO!!!! failable
    static func fromDict(_ dict: [String: AnyObject], inventory: DBInventory, product: Product) -> DBHistoryItem {
        let item = DBHistoryItem()
        item.uuid = dict["uuid"]! as! String
        item.inventory = inventory
        item.product = product
        item.addedDate = Int64(dict["addedDate"] as! Double)
        item.quantity = dict["quantity"]! as! Int
        item.paidPrice = dict["paidPrice"] as! Float
        // TODO!!!! user -> the backend sends us the uuid, we should send for now the email instead
        let user = DBSharedUser()
        user.email = dict["userUuid"]! as! String
        item.user = user
        item.setSyncableFieldswithRemoteDict(dict)
        return item
    }
    
    func toDict() -> [String: AnyObject] {
        var dict = [String: AnyObject]()
        dict["uuid"] = uuid as AnyObject?
        dict["inventoryUuid"] = inventory.uuid as AnyObject?
        dict["productInput"] = product.toDict() as AnyObject?
        dict["addedDate"] = NSNumber(value: Int64(addedDate) as Int64)
        dict["quantity"] = quantity as AnyObject?
        dict["paidPrice"] = paidPrice as AnyObject?
        dict["user"] = user.toDict() as AnyObject?
        setSyncableFieldsInDict(&dict)
        return dict
    }
    
    public override static func ignoredProperties() -> [String] {
        return ["product", "inventory", "user"]
    }
}
