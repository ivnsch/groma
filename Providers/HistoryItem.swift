//
//  HistoryItem.swift
//  shoppin
//
//  Created by ischuetz on 12/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

public class HistoryItem: DBSyncable, Identifiable, WithUuid {

    @objc public dynamic var uuid: String = ""
    @objc dynamic var inventoryOpt: DBInventory? = DBInventory()
    @objc dynamic var productOpt: QuantifiableProduct? = QuantifiableProduct()
    @objc public dynamic var addedDate: Int64 = 0
    @objc public dynamic var quantity: Float = 0
    @objc dynamic var userOpt: DBSharedUser? = DBSharedUser()
    @objc public dynamic var paidPrice: Float = 0 // product price at the moment of buying the item (per unit ~ meaning price (including base, etc.) before being multiplied with quantity)
    
    public static let addedDateKey = "addedDate"
    
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
    
    public var user: DBSharedUser {
        get {
            return userOpt ?? DBSharedUser()
        }
        set(newUser) {
            userOpt = newUser
        }
    }
    
    public var totalPaidPrice: Float {
        return paidPrice * Float(quantity)
    }
    
    public convenience init(uuid: String, inventory: DBInventory, product: QuantifiableProduct, addedDate: Int64, quantity: Float, user: DBSharedUser, paidPrice: Float, lastServerUpdate: Int64? = nil, removed: Bool = false) {
        self.init()
        
        self.uuid = uuid
        self.inventory = inventory
        self.product = product
        self.addedDate = addedDate
        self.quantity = quantity
        self.user = user
        self.paidPrice = paidPrice
//        self.lastServerUpdate = lastServerUpdate
//        self.removed = removed
    }

    
    // MARK: - Filters
    
    static func createFilter(_ uuid: String) -> NSPredicate {
        return NSPredicate(format: "uuid = %@", uuid)
    }
    
    static func createFilter(quantifiableProductUuid: String) -> NSPredicate {
        return NSPredicate(format: "productOpt.uuid = %@", quantifiableProductUuid)
    }

    static func createFilter(quantifiableProductUuids: [String]) -> NSPredicate {
        return NSPredicate(format: "productOpt.uuid IN %@", quantifiableProductUuids)
    }

    static func createFilterWithInventory(_ inventoryUuid: String) -> NSPredicate {
        return NSPredicate(format: "inventoryOpt.uuid = %@", inventoryUuid)
    }

    static func createFilter(_ historyItemGroup: HistoryItemGroup) -> NSPredicate {
        return createFilter(uuids: historyItemGroup.historyItems.map{$0.uuid})
    }
    
    static func createFilter(uuids: [String]) -> NSPredicate {
        return NSPredicate(format: "uuid IN %@", uuids)
    }

    fileprivate static func createFilterAddedSameDateOrLater(date: Int64) -> NSPredicate {
        return NSPredicate(format: "addedDate >= %@", NSNumber(value: date))
    }

    fileprivate static func createFilterAddedSameDateOrBefore(date: Int64) -> NSPredicate {
        return NSPredicate(format: "addedDate <= %@", NSNumber(value: date))
    }

    static func createPredicateOlderThan(_ addedDate: Int64) -> NSPredicate {
        return NSPredicate(format: "addedDate < %@", NSNumber(value: addedDate))
    }

    static func createPredicate(_ addedDate: Int64, inventoryUuid: String) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            createFilterAddedSameDateOrLater(date: addedDate),
            createFilterWithInventory(inventoryUuid)
        ])
    }
    
    static func createPredicate(_ productName: String, addedDate: Int64, inventoryUuid: String) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "productOpt.productOpt.itemOpt.name == %@", productName),
            createFilterAddedSameDateOrLater(date: addedDate),
            createFilterWithInventory(inventoryUuid)
        ])
    }
    
    static func createPredicate(_ startAddedDate: Int64, endAddedDate: Int64, inventoryUuid: String) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            createFilterAddedSameDateOrLater(date: startAddedDate),
            createFilterAddedSameDateOrBefore(date: endAddedDate),
            createFilterWithInventory(inventoryUuid)
        ])
    }

    // MARK: -
    
    // TODO!!!! failable
    static func fromDict(_ dict: [String: AnyObject], inventory: DBInventory, product: Product) -> HistoryItem {
        let item = HistoryItem()
        // for now disabled because structural changes
//        item.uuid = dict["uuid"]! as! String
//        item.inventory = inventory
//        item.product = product
//        item.addedDate = Int64(dict["addedDate"] as! Double)
//        item.quantity = dict["quantity"]! as! Int
//        item.paidPrice = dict["paidPrice"] as! Float
//        // TODO!!!! user -> the backend sends us the uuid, we should send for now the email instead
//        let user = DBSharedUser()
//        user.email = dict["userUuid"]! as! String
//        item.user = user
//        item.setSyncableFieldswithRemoteDict(dict)
        return item
    }
    
    func toDict() -> [String: AnyObject] {
        let dict = [String: AnyObject]()
        // for now disabled because structural changes
//        dict["uuid"] = uuid as AnyObject?
//        dict["inventoryUuid"] = inventory.uuid as AnyObject?
//        dict["productInput"] = product.toDict() as AnyObject?
//        dict["addedDate"] = NSNumber(value: Int64(addedDate) as Int64)
//        dict["quantity"] = quantity as AnyObject?
//        dict["paidPrice"] = paidPrice as AnyObject?
//        dict["user"] = user.toDict() as AnyObject?
//        setSyncableFieldsInDict(&dict)
        return dict
    }

    func toRealmMigrationDict(inventory: DBInventory, quantifiableProduct: QuantifiableProduct, user: DBSharedUser) -> [String: AnyObject] {
        var dict = [String: AnyObject]()
        dict["uuid"] = uuid as AnyObject?
        dict["addedDate"] = addedDate as AnyObject?
        dict["quantity"] = quantity as AnyObject?
        dict["paidPrice"] = paidPrice as AnyObject?
        dict["userOpt"] = user
        dict["inventoryOpt"] = inventory
        dict["productOpt"] = productOpt
        return dict
    }

    public func copy(uuid: String? = nil, inventory: DBInventory? = nil, product: QuantifiableProduct? = nil, addedDate: Int64? = nil, quantity: Float? = nil, user: DBSharedUser? = nil, paidPrice: Float? = nil, lastServerUpdate: Int64? = nil, removed: Bool = false) -> HistoryItem {
        return HistoryItem(
            uuid: uuid ?? self.uuid,
            inventory: inventory ?? self.inventory.copy(),
            product: product ?? self.product.copy(),
            addedDate: addedDate ?? self.addedDate,
            quantity: quantity ?? self.quantity,
            user: user ?? self.user.copy(),
            paidPrice: paidPrice ?? self.paidPrice
        )
    }

    public override static func ignoredProperties() -> [String] {
        return ["product", "inventory", "user"]
    }
    
    public func same(_ rhs: HistoryItem) -> Bool {
        return uuid == rhs.uuid
    }
}

// convenience (redundant) holder to avoid having to iterate through historyitems to find unique products and users
// so products, users arrays are the result of extracting the unique products and users from historyItems array
public typealias HistoryItemsWithRelations = (historyItems: [HistoryItem], inventories: [DBInventory], products: [Product], users: [DBSharedUser])
