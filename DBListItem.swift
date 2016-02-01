//
//  DBListItem.swift
//  shoppin
//
//  Created by ischuetz on 14/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class DBListItem: DBSyncable, CustomDebugStringConvertible {
    
    dynamic var uuid: String = ""
    dynamic var section: DBSection = DBSection()
    dynamic var product: DBProduct = DBProduct()
    dynamic var list: DBList = DBList()
    dynamic var note: String = "" // TODO review if we can use optionals in realm, if not check if in newer version
    
    dynamic var todoQuantity: Int = 0
    dynamic var todoOrder: Int = 0
    dynamic var doneQuantity: Int = 0
    dynamic var doneOrder: Int = 0
    dynamic var stashQuantity: Int = 0
    dynamic var stashOrder: Int = 0
    
    override static func primaryKey() -> String? {
        return "uuid"
    }
    
    // Quantity of listitem in a specific status
    private func quantityForStatus(status: ListItemStatus) -> Int {
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

    static func createFilter(list: List) -> String {
        return "list.uuid == '\(list.uuid)'"
    }
    
    static func createFilter(list: List, product: Product) -> String {
        let brand = product.brand ?? ""
        return "\(createFilter(list)) && product.name == '\(product.name)' && product.brand == '\(brand)'"
    }
    
    // MARK: - CustomDebugStringConvertible
    
    override var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(uuid), \(product.name)], todo: \(todoQuantity), done: \(doneQuantity), stash: \(stashQuantity)}"
    }
    
    static func fromDict(dict: [String: AnyObject], section: DBSection, product: DBProduct, list: DBList) -> DBListItem {
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
        dict["productInput"] = product.toDict()
        
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
        setSyncableFieldsInDict(dict)
        return dict
    }
}
