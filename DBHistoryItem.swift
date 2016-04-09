//
//  DBHistoryItem.swift
//  shoppin
//
//  Created by ischuetz on 12/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class DBHistoryItem: DBSyncable {

    dynamic var uuid: String = ""
    dynamic var inventoryOpt: DBInventory? = DBInventory()
    dynamic var productOpt: DBProduct? = DBProduct()
    dynamic var addedDate: NSDate = NSDate()
    dynamic var quantity: Int = 0
    dynamic var userOpt: DBSharedUser? = DBSharedUser()
    dynamic var paidPrice: Float = 0 // product price at the moment of buying the item (per unit)
    
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
    
    var user: DBSharedUser {
        get {
            return userOpt ?? DBSharedUser()
        }
        set(newUser) {
            userOpt = newUser
        }
    }
    
    // MARK: - Filters
    
    static func createFilter(uuid: String) -> String {
        return "uuid == '\(uuid)'"
    }
    
    static func createFilterWithProduct(productUuid: String) -> String {
        return "productOpt.uuid == '\(productUuid)'"
    }
    
    static func createFilterWithInventory(inventoryUuid: String) -> String {
        return "inventoryOpt.uuid == '\(inventoryUuid)'"
    }

    static func createFilter(historyItemGroup: HistoryItemGroup) -> String {
        let historyItemsUuidsStr: String = historyItemGroup.historyItems.map{"'\($0.uuid)'"}.joinWithSeparator(",")
        return "uuid IN {\(historyItemsUuidsStr)}"
    }
    
    static func createPredicate(addedDate: NSDate, inventoryUuid: String) -> NSPredicate {
        return NSPredicate(format: "addedDate >= %@ AND inventoryOpt.uuid == %@", addedDate, inventoryUuid)
    }
    
    static func createPredicate(productName: String, addedDate: NSDate, inventoryUuid: String) -> NSPredicate {
        return NSPredicate(format: "productOpt.name == %@ AND addedDate >= %@ AND inventoryOpt.uuid == %@", productName, addedDate, inventoryUuid)
    }
    
    static func createPredicate(startAddedDate: NSDate, endAddedDate: NSDate, inventoryUuid: String) -> NSPredicate {
        return NSPredicate(format: "addedDate >= %@ AND addedDate <= %@ AND inventoryOpt.uuid == %@", startAddedDate, endAddedDate, inventoryUuid)
    }
    
    // MARK: -

    
    static func fromDict(dict: [String: AnyObject], inventory: DBInventory, product: DBProduct) -> DBHistoryItem {
        let item = DBHistoryItem()
        item.uuid = dict["uuid"]! as! String
        item.inventory = inventory
        item.product = product
        item.addedDate = NSDate(timeIntervalSince1970: dict["addedDate"] as! Double)
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
        dict["uuid"] = uuid
        dict["inventoryUuid"] = inventory.uuid
        dict["productInput"] = product.toDict()
        dict["addedDate"] = NSNumber(double: addedDate.timeIntervalSince1970).longValue
        dict["quantity"] = quantity
        dict["paidPrice"] = paidPrice
        dict["user"] = user.toDict()
        setSyncableFieldsInDict(dict)
        return dict
    }
    
    override static func ignoredProperties() -> [String] {
        return ["product", "inventory", "user"]
    }
}