//
//  GroupItem.swift
//  shoppin
//
//  Created by ischuetz on 15/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

// TODO order?
public final class GroupItem: DBSyncable, ProductWithQuantity2, WithUuid {
    @objc public dynamic var uuid: String = ""
    @objc public dynamic var quantity: Float = 0
    @objc dynamic var productOpt: QuantifiableProduct? = QuantifiableProduct()
    @objc dynamic var groupOpt: ProductGroup? = ProductGroup()

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
    
    public var group: ProductGroup {
        get {
            return groupOpt ?? ProductGroup()
        }
        set(newGroup) {
            groupOpt = newGroup
        }
    }
    
    public convenience init(uuid: String, quantity: Float, product: QuantifiableProduct, group: ProductGroup) {
        self.init()
        
        self.uuid = uuid
        self.quantity = quantity
        self.product = product
        self.group = group
    }
    
    // MARK: - Filters
    
    static func createFilter(_ uuid: String) -> NSPredicate {
        return NSPredicate(format: "uuid = %@", uuid)
    }
    
    static func createFilterGroup(_ groupUuid: String) -> NSPredicate {
        return NSPredicate(format: "groupOpt.uuid = %@", groupUuid)
    }

    static func createFilterProduct(_ productUuid: String) -> NSPredicate {
        return NSPredicate(format: "productOpt.uuid = %@", productUuid)
    }
    
    static func createFilter(_ product: QuantifiableProduct, group: ProductGroup) -> NSPredicate {
        return createFilter(groupUuid: group.uuid, quantifiableProductUnique: product.unique)
    }

    static func createFilter(groupUuid: String, quantifiableProductUnique unique: QuantifiableProductUnique) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            createFilterGroup(groupUuid),
            NSPredicate(format: "productOpt.productOpt.itemOpt.name == %@", unique.name),
            NSPredicate(format: "productOpt.productOpt.brand == %@", unique.brand),
            NSPredicate(format: "productOpt.unitOpt.name == %@", unique.unit),
            NSPredicate(format: "productOpt.baseQuantity == %@", unique.baseQuantity),
        ])
    }

    static func createFilter(groupUuid: String, quantifiableProductUnique unique: QuantifiableProductUnique, notUuid: String) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            createFilter(groupUuid: groupUuid, quantifiableProductUnique: unique),
            NSPredicate(format: "uuid != %@", notUuid)
        ])
    }
    
    static func createFilterGroupItemsUuids(_ groupItems: [GroupItem]) -> NSPredicate {
        let groupItemsUuidsStr = groupItems.map{"'\($0.uuid)'"}.joined(separator: ",")
        return NSPredicate(format: "uuid IN {%@}", groupItemsUuidsStr)
    }
    
    // MARK: -
    
    static func fromDict(_ dict: [String: AnyObject], product: Product, group: ProductGroup) -> GroupItem {
        let item = GroupItem()
        // Commented because structural changes
//        item.uuid = dict["uuid"]! as! String
//        item.quantity = dict["quantity"]! as! Int
//        item.product = product
//        item.group = group
//        item.product = product
//        item.setSyncableFieldswithRemoteDict(dict)
        return item
    }
    
    func toDict() -> [String: AnyObject] {
        return [:]
        // Commented because structural changes
//        var dict = [String: AnyObject]()
//        dict["uuid"] = uuid as AnyObject?
//        dict["quantity"] = quantity as AnyObject?
//        dict["product"] = product.toDict() as AnyObject?
//        dict["group"] = group.toDict() as AnyObject?
//        setSyncableFieldsInDict(&dict)
//        return dict
    }
    
    public override static func ignoredProperties() -> [String] {
        return ["product", "group"]
    }
    
    // MARK: - ProductWithQuantity2
    
    public func copy(uuid: String? = nil, quantity: Float? = nil, product: QuantifiableProduct? = nil, group: ProductGroup? = nil) -> GroupItem {
        return GroupItem(
            uuid: uuid ?? self.uuid,
            quantity: quantity ?? self.quantity,
            product: product ?? self.product.copy(),
            group: group ?? self.group.copy()
        )
    }
    
    public func incrementQuantityCopy(_ delta: Float) -> GroupItem {
        return copy(quantity: quantity + delta)
    }
    
    public func updateQuantityCopy(_ quantity: Float) -> GroupItem {
        return copy(quantity: quantity)
    }
    
    // MARK: - Identifiable
    
    /**
     If objects have the same semantic identity. Identity is equivalent to a primary key in a database.
     */
    public func same(_ rhs: GroupItem) -> Bool {
        return uuid == rhs.uuid
    }
}

//// convenience (redundant) holder to avoid having to iterate through group items to find unique products and groups
public typealias GroupItemsWithRelations = (groupItems: [GroupItem], products: [Product], groups: [ProductGroup])
