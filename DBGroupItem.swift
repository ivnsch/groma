//
//  DBGroupItem.swift
//  shoppin
//
//  Created by ischuetz on 15/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class DBGroupItem: DBSyncable {
    
    dynamic var uuid: String = ""
    dynamic var quantity: Int = 0
    dynamic var productOpt: Product? = Product()
    dynamic var groupOpt: DBListItemGroup? = DBListItemGroup()

    static var quantityFieldName: String {
        return "quantity"
    }
    
    override static func primaryKey() -> String? {
        return "uuid"
    }
    
    var product: Product {
        get {
            return productOpt ?? Product()
        }
        set(newProduct) {
            productOpt = newProduct
        }
    }
    
    var group: DBListItemGroup {
        get {
            return groupOpt ?? DBListItemGroup()
        }
        set(newGroup) {
            groupOpt = newGroup
        }
    }
    
    convenience init(uuid: String, quantity: Int, product: Product, group: DBListItemGroup) {
        self.init()
        
        self.uuid = uuid
        self.quantity = quantity
        self.product = product
        self.group = group
    }
    
    // MARK: - Filters
    
    static func createFilter(_ uuid: String) -> String {
        return "uuid == '\(uuid)'"
    }
    
    static func createFilterGroup(_ groupUuid: String) -> String {
        return "groupOpt.uuid = '\(groupUuid)'"
    }

    static func createFilterProduct(_ productUuid: String) -> String {
        return "productOpt.uuid = '\(productUuid)'"
    }
    
    static func createFilter(_ product: Product, group: ListItemGroup) -> String {
        return createFilterGroupAndProductName(group.uuid, productName: product.name, productBrand: product.brand)
    }

    static func createFilterGroupAndProductName(_ groupUuid: String, productName: String, productBrand: String) -> String {
        return "\(createFilterGroup(groupUuid)) AND productOpt.name = '\(productName)' AND productOpt.brand = '\(productBrand)'"
    }

    static func createFilterGroupAndProductName(_ groupUuid: String, productName: String, productBrand: String, notUuid: String) -> String {
        return "\(createFilterGroup(groupUuid)) AND productOpt.name = '\(productName)' AND productOpt.brand = '\(productBrand)' AND uuid != '\(notUuid)'"
    }
    
    static func createFilterGroupItemsUuids(_ groupItems: [GroupItem]) -> String {
        let groupItemsUuidsStr = groupItems.map{"'\($0.uuid)'"}.joined(separator: ",")
        return "uuid IN {\(groupItemsUuidsStr)}"
    }
    
    // MARK: -
    
    static func fromDict(_ dict: [String: AnyObject], product: Product, group: DBListItemGroup) -> DBGroupItem {
        let item = DBGroupItem()
        item.uuid = dict["uuid"]! as! String
        item.quantity = dict["quantity"]! as! Int
        item.product = product
        item.group = group
        item.product = product
        item.setSyncableFieldswithRemoteDict(dict)
        return item
    }
    
    func toDict() -> [String: AnyObject] {
        var dict = [String: AnyObject]()
        dict["uuid"] = uuid as AnyObject?
        dict["quantity"] = quantity as AnyObject?
        dict["product"] = product.toDict() as AnyObject?
        dict["group"] = group.toDict() as AnyObject?
        setSyncableFieldsInDict(&dict)
        return dict
    }
    
    override static func ignoredProperties() -> [String] {
        return ["product", "group"]
    }
}
