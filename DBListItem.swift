//
//  DBListItem.swift
//  shoppin
//
//  Created by ischuetz on 14/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class DBListItem: DBSyncable {
    
    dynamic var uuid: String = ""
    dynamic var sectionOpt: DBSection? = DBSection()
    dynamic var productOpt: DBStoreProduct? = DBStoreProduct()
    dynamic var listOpt: DBList? = DBList()
    dynamic var note: String = "" // TODO review if we can use optionals in realm, if not check if in newer version
    
    dynamic var todoQuantity: Int = 0
    dynamic var todoOrder: Int = 0
    dynamic var doneQuantity: Int = 0
    dynamic var doneOrder: Int = 0
    dynamic var stashQuantity: Int = 0
    dynamic var stashOrder: Int = 0
    
    var list: DBList {
        get {
            return listOpt ?? DBList()
        }
        set(newList) {
            listOpt = newList
        }
    }
    
    var section: DBSection {
        get {
            return sectionOpt ?? DBSection()
        }
        set(newSection) {
            sectionOpt = newSection
        }
    }
    
    var product: DBStoreProduct {
        get {
            return productOpt ?? DBStoreProduct()
        }
        set(newProduct) {
            productOpt = newProduct
        }
    }
    
    override static func primaryKey() -> String? {
        return "uuid"
    }
    
    convenience init(uuid: String, product: DBStoreProduct, section: DBSection, list: DBList, note: String, todoQuantity: Int, todoOrder: Int, doneQuantity: Int, doneOrder: Int, stashQuantity: Int, stashOrder: Int, lastServerUpdate: Int64? = nil, removed: Bool = false) {
        
        self.init()
        
        self.uuid = uuid
        self.product = product
        self.section = section
        self.list = list
        self.note = note
        
        self.todoQuantity = todoQuantity
        self.todoOrder = todoOrder
        self.doneQuantity = doneQuantity
        self.doneOrder = doneOrder
        self.stashQuantity = stashQuantity
        self.stashOrder = stashOrder
        
        if let lastServerUpdate = lastServerUpdate {
            self.lastServerUpdate = lastServerUpdate
        }
        self.removed = removed
    }
    
    // Quantity of listitem in a specific status
    func quantityForStatus(status: ListItemStatus) -> Int {
        switch status {
        case .Todo: return todoQuantity
        case .Done: return doneQuantity
        case .Stash: return stashQuantity
        }
    }

    func hasStatus(status: ListItemStatus) -> Bool {
        return quantityForStatus(status) > 0
    }
    
    func increment(quantity: ListItemStatusQuantity) {
        
        switch quantity.status {
        case .Todo: todoQuantity += quantity.quantity
        case .Done: doneQuantity += quantity.quantity
        case .Stash: stashQuantity += quantity.quantity
        }
        
        // Sometimes got -1 in .Todo (no server involved) TODO find out why and fix, these checks shouldn't be necessary
        if todoQuantity < 0 {
            print("Error: ListItem.increment: New todo quantity: \(todoQuantity) for item: \(self)")
            todoQuantity = 0
        }
        if doneQuantity < 0 {
            print("Error: ListItem.increment: New done quantity: \(doneQuantity) for item: \(self)")
            doneQuantity = 0
        }
        if stashQuantity < 0 {
            print("Error: ListItem.increment: New stash quantity: \(stashQuantity) for item: \(self)")
            stashQuantity = 0
        }
    }
    
    func copy(uuid uuid: String? = nil, product: DBStoreProduct? = nil, section: DBSection? = nil, list: DBList? = nil, note: String? = nil, todoQuantity: Int? = nil, todoOrder: Int? = nil, doneQuantity: Int? = nil, doneOrder: Int? = nil, stashQuantity: Int? = nil, stashOrder: Int? = nil) -> DBListItem {
        return DBListItem(
            uuid: uuid ?? self.uuid,
            product: product ?? self.product,
            section: section ?? self.section,
            list: list ?? self.list,
            note: note ?? self.note,
            
            todoQuantity: todoQuantity ?? self.todoQuantity,
            todoOrder: todoOrder ?? self.todoOrder,
            doneQuantity: doneQuantity ?? self.doneQuantity,
            doneOrder: doneOrder ?? self.doneOrder,
            stashQuantity: stashQuantity ?? self.stashQuantity,
            stashOrder: stashOrder ?? self.stashOrder,
            
            lastServerUpdate: self.lastServerUpdate,
            removed: self.removed
        )
    }
    
    // MARK: - Filters
    
    static func createFilter(uuid: String) -> String {
        return "uuid == '\(uuid)'"
    }

    static func createFilterForUuids(uuids: [String]) -> String {
        let uuidsStr: String = uuids.map{"'\($0)'"}.joinWithSeparator(",")
        return "uuid IN {\(uuidsStr)}"
    }
    
    static func createFilterList(listUuid: String) -> String {
        return "listOpt.uuid == '\(listUuid)'"
    }
    
    static func createFilter(list: List, product: Product) -> String {
        return createFilterUniqueInList(product.name, productBrand: product.brand, list: list)
    }

    static func createFilterUniqueInList(productName: String, productBrand: String, list: List) -> String {
        return "\(createFilterList(list.uuid)) AND productOpt.productOpt.name == '\(productName)' AND productOpt.productOpt.brand == '\(productBrand)'"
    }
    
    static func createFilterWithProducts(productUuids: [String]) -> String {
        let productUuidsStr: String = productUuids.map{"'\($0)'"}.joinWithSeparator(",")
        return "productOpt.uuid IN {\(productUuidsStr)}"
    }
    
    static func createFilterWithProduct(productUuid: String) -> String {
        return "productOpt.uuid == '\(productUuid)'"
    }
    
    static func createFilterWithProductName(productName: String) -> String {
        return "productOpt.name == '\(productName)'"
    }

    static func createFilterWithSection(sectionUuid: String) -> String {
        return "sectionOpt.uuid == '\(sectionUuid)'"
    }
    
    // Finds list items that have the same product names as listItems and are in the same list
    // WARN: Assumes all the list items belong to the same list (list uuid of first list item is used)
    static func createFilter(listItems: [ListItem]) -> String {
        let productNamesStr: String = listItems.map{"'\($0.product.product.name)'"}.joinWithSeparator(",")
        let listUuid = listItems.first?.list.uuid ?? ""
        return "productOpt.name IN {\(productNamesStr)} AND listOpt.uuid = '\(listUuid)'"
    }
    
    // MARK: - CustomDebugStringConvertible
    
    override var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(uuid), \(product.product.name)], todo: \(todoQuantity), done: \(doneQuantity), stash: \(stashQuantity)}"
    }
    
    static func fromDict(dict: [String: AnyObject], section: DBSection, product: DBStoreProduct, list: DBList) -> DBListItem {
        let item = DBListItem()
        item.uuid = dict["uuid"]! as! String
        item.section = section
        item.product = product
        item.list = list
        item.note = dict["note"]! as! String
        item.todoQuantity = dict["todoQuantity"]! as! Int
        item.todoOrder = dict["todoOrder"]! as! Int
        item.doneQuantity = dict["doneQuantity"]! as! Int
        item.doneOrder = dict["doneOrder"]! as! Int
        item.stashQuantity = dict["stashQuantity"]! as! Int
        item.stashOrder = dict["stashOrder"]! as! Int
        item.setSyncableFieldswithRemoteDict(dict)
        return item
    }
    
    func toDict() -> [String: AnyObject] {
        var dict = [String: AnyObject]()
        dict["uuid"] = uuid
        dict["sectionInput"] = section.toDict()
        dict["storeProductInput"] = product.toDict()
        // TODO fix sync input models
//        dict["list"] = list.toDict()
        dict["listUuid"] = list.uuid
        dict["listName"] = list.name
        
        dict["note"] = note
        dict["todoQuantity"] = todoQuantity
        dict["todoOrder"] = todoOrder
        dict["doneQuantity"] = doneQuantity
        dict["doneOrder"] = doneOrder
        dict["stashQuantity"] = stashQuantity
        dict["stashOrder"] = stashOrder
        setSyncableFieldsInDict(&dict)
        return dict
    }
    
    static func quantityFieldName(status: ListItemStatus) -> String {
        switch status {
        case .Todo: return "todoQuantity"
        case .Done: return "doneQuantity"
        case .Stash: return "stashQuantity"
        }
    }
    override static func ignoredProperties() -> [String] {
        return ["list", "section", "product"]
    }
    
    static func timestampUpdateDict(uuid: String, lastUpdate: Int64) -> [String: AnyObject] {
        return DBSyncable.timestampUpdateDict(uuid, lastServerUpdate: lastUpdate)
    }
}
