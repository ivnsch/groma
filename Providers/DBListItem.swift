//
//  DBListItem.swift
//  shoppin
//
//  Created by ischuetz on 14/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

public class DBListItem: DBSyncable {
    
    public dynamic var uuid: String = ""
    dynamic var sectionOpt: Section? = Section()
    dynamic var productOpt: DBStoreProduct? = DBStoreProduct()
    dynamic var listOpt: List? = List()
    public dynamic var note: String = "" // TODO review if we can use optionals in realm, if not check if in newer version
    
    public dynamic var todoQuantity: Int = 0
    public dynamic var todoOrder: Int = 0
    public dynamic var doneQuantity: Int = 0
    public dynamic var doneOrder: Int = 0
    public dynamic var stashQuantity: Int = 0
    public dynamic var stashOrder: Int = 0
    
    public var list: List {
        get {
            return listOpt ?? List()
        }
        set(newList) {
            listOpt = newList
        }
    }
    
    public var section: Section {
        get {
            return sectionOpt ?? Section()
        }
        set(newSection) {
            sectionOpt = newSection
        }
    }
    
    public var product: DBStoreProduct {
        get {
            return productOpt ?? DBStoreProduct()
        }
        set(newProduct) {
            productOpt = newProduct
        }
    }
    
    public override static func primaryKey() -> String? {
        return "uuid"
    }
    
    public convenience init(uuid: String, product: DBStoreProduct, section: Section, list: List, note: String, todoQuantity: Int, todoOrder: Int, doneQuantity: Int, doneOrder: Int, stashQuantity: Int, stashOrder: Int, lastServerUpdate: Int64? = nil, removed: Bool = false) {
        
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
    public func quantityForStatus(_ status: ListItemStatus) -> Int {
        switch status {
        case .todo: return todoQuantity
        case .done: return doneQuantity
        case .stash: return stashQuantity
        }
    }

    public func hasStatus(_ status: ListItemStatus) -> Bool {
        return quantityForStatus(status) > 0
    }
    
    public func increment(_ quantity: ListItemStatusQuantity) {
        
        switch quantity.status {
        case .todo: todoQuantity += quantity.quantity
        case .done: doneQuantity += quantity.quantity
        case .stash: stashQuantity += quantity.quantity
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
    
    public func copy(uuid: String? = nil, product: DBStoreProduct? = nil, section: Section? = nil, list: List? = nil, note: String? = nil, todoQuantity: Int? = nil, todoOrder: Int? = nil, doneQuantity: Int? = nil, doneOrder: Int? = nil, stashQuantity: Int? = nil, stashOrder: Int? = nil) -> DBListItem {
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
    
    static func createFilter(_ uuid: String) -> String {
        return "uuid == '\(uuid)'"
    }

    static func createFilterForUuids(_ uuids: [String]) -> String {
        let uuidsStr: String = uuids.map{"'\($0)'"}.joined(separator: ",")
        return "uuid IN {\(uuidsStr)}"
    }
    
    static func createFilterList(_ listUuid: String) -> String {
        return "listOpt.uuid == '\(listUuid)'"
    }
    
    static func createFilter(_ list: List, product: Product) -> String {
        return createFilterUniqueInList(product.name, productBrand: product.brand, list: list)
    }

    static func createFilterUniqueInList(_ productName: String, productBrand: String, list: List) -> String {
        return "\(createFilterList(list.uuid)) AND productOpt.productOpt.name == '\(productName)' AND productOpt.productOpt.brand == '\(productBrand)'"
    }

    static func createFilterUniqueInListNotUuid(_ productName: String, productBrand: String, notUuid: String, list: List) -> String {
        return "\(createFilterList(list.uuid)) AND productOpt.productOpt.name == '\(productName)' AND productOpt.productOpt.brand == '\(productBrand)' AND uuid != '\(notUuid)'"
    }
    
    static func createFilterWithProducts(_ productUuids: [String]) -> String {
        let productUuidsStr: String = productUuids.map{"'\($0)'"}.joined(separator: ",")
        return "productOpt.uuid IN {\(productUuidsStr)}"
    }
    
    static func createFilterWithProduct(_ productUuid: String) -> String {
        return "productOpt.uuid == '\(productUuid)'"
    }
    
    static func createFilterWithProductName(_ productName: String) -> String {
        return "productOpt.name == '\(productName)'"
    }

    static func createFilterWithSection(_ sectionUuid: String) -> String {
        return "sectionOpt.uuid == '\(sectionUuid)'"
    }
    
    // Finds list items that have the same product names as listItems and are in the same list
    // WARN: Assumes all the list items belong to the same list (list uuid of first list item is used)
    public static func createFilter(_ listItems: [ListItem]) -> String {
        let productNamesStr: String = listItems.map{"'\($0.product.product.name)'"}.joined(separator: ",")
        let listUuid = listItems.first?.list.uuid ?? ""
        return "productOpt.name IN {\(productNamesStr)} AND listOpt.uuid = '\(listUuid)'"
    }
    
    // MARK: - CustomDebugStringConvertible
    
    public override var debugDescription: String {
        return "{\(type(of: self)) uuid: \(uuid), \(product.product.name)], todo: \(todoQuantity), done: \(doneQuantity), stash: \(stashQuantity)}"
    }
    
    static func fromDict(_ dict: [String: AnyObject], section: Section, product: DBStoreProduct, list: List) -> DBListItem {
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
        dict["uuid"] = uuid as AnyObject?
        dict["sectionInput"] = section.toDict() as AnyObject?
        dict["storeProductInput"] = product.toDict() as AnyObject?
        // TODO fix sync input models
//        dict["list"] = list.toDict()
        dict["listUuid"] = list.uuid as AnyObject?
        dict["listName"] = list.name as AnyObject?
        
        dict["note"] = note as AnyObject?
        dict["todoQuantity"] = todoQuantity as AnyObject?
        dict["todoOrder"] = todoOrder as AnyObject?
        dict["doneQuantity"] = doneQuantity as AnyObject?
        dict["doneOrder"] = doneOrder as AnyObject?
        dict["stashQuantity"] = stashQuantity as AnyObject?
        dict["stashOrder"] = stashOrder as AnyObject?
        setSyncableFieldsInDict(&dict)
        return dict
    }
    
    public static func quantityFieldName(_ status: ListItemStatus) -> String {
        switch status {
        case .todo: return "todoQuantity"
        case .done: return "doneQuantity"
        case .stash: return "stashQuantity"
        }
    }
    public override static func ignoredProperties() -> [String] {
        return ["list", "section", "product"]
    }
    
    static func timestampUpdateDict(_ uuid: String, lastUpdate: Int64) -> [String: AnyObject] {
        return DBSyncable.timestampUpdateDict(uuid, lastServerUpdate: lastUpdate)
    }
}
