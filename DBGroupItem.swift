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
    dynamic var productOpt: DBProduct? = DBProduct()
    dynamic var groupOpt: DBListItemGroup? = DBListItemGroup()

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
    
    var group: DBListItemGroup {
        get {
            return groupOpt ?? DBListItemGroup()
        }
        set(newGroup) {
            groupOpt = newGroup
        }
    }
    
    // MARK: - Filters
    
    static func createFilter(uuid: String) -> String {
        return "uuid == '\(uuid)'"
    }
    
    static func createFilterGroup(groupUuid: String) -> String {
        return "groupOpt.uuid = '\(groupUuid)'"
    }
    
    static func createFilterGroupAndProductName(groupUuid: String, productName: String, productBrand: String) -> String {
        return "\(createFilterGroup(groupUuid)) AND productOpt.name = '\(productName)' AND productOpt.brand = '\(productBrand)'"
    }

    
    static func createFilterGroupItemsUuids(groupItems: [GroupItem]) -> String {
        let groupItemsUuidsStr = groupItems.map{"'\($0.uuid)'"}.joinWithSeparator(",")
        return "uuid IN {\(groupItemsUuidsStr)}"
    }
    
    // MARK: -
    
    static func fromDict(dict: [String: AnyObject], product: DBProduct, group: DBListItemGroup) -> DBGroupItem {
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
        dict["uuid"] = uuid
        dict["quantity"] = quantity
        dict["product"] = product.toDict()
        dict["group"] = group.toDict()
        setSyncableFieldsInDict(&dict)
        return dict
    }
    
    override static func ignoredProperties() -> [String] {
        return ["product", "group"]
    }
}
