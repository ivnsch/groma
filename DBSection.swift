//
//  DBSection.swift
//  shoppin
//
//  Created by ischuetz on 14/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class DBSection: DBSyncable {

    dynamic var uuid: String = ""
    dynamic var name: String = ""
    dynamic var bgColorHex: String = "000000"
    
//    let listItems = RealmSwift.List<String>()
    
    dynamic var listOpt: List? = List()
    dynamic var todoOrder: Int = 0
    dynamic var doneOrder: Int = 0
    dynamic var stashOrder: Int = 0

    func color() -> UIColor {
        return UIColor(hexString: bgColorHex)
    }
    
    func setColor(_ bgColor: UIColor) {
        bgColorHex = bgColor.hexStr
    }
    
    var list: List {
        get {
            return listOpt ?? List()
        }
        set(newList) {
            listOpt = newList
        }
    }
    
    override static func primaryKey() -> String? {
        return "uuid"
    }
    
    override class func indexedProperties() -> [String] {
        return ["name"]
    }
    
    convenience init(uuid: String, name: String, bgColorHex: String, list: List, todoOrder: Int, doneOrder: Int, stashOrder: Int, lastUpdate: Date = Date(), lastServerUpdate: Int64? = nil, removed: Bool = false) {
        
        self.init()
        
        self.uuid = uuid
        self.name = name
        self.bgColorHex = bgColorHex        
        self.list = list
        
        self.todoOrder = todoOrder
        self.doneOrder = doneOrder
        self.stashOrder = stashOrder
        
        if let lastServerUpdate = lastServerUpdate {
            self.lastServerUpdate = lastServerUpdate
        }
        self.removed = removed
    }
    
    // NOTE: we reuse ListItemStatusOrder from list items, as content is what we need here also, maybe we should rename it
    convenience init(uuid: String, name: String, bgColorHex: String, list: List, order: ListItemStatusOrder, lastServerUpdate: Int64? = nil, removed: Bool = false) {
        
        let (todoOrder, doneOrder, stashOrder): (Int, Int, Int) = {
            switch order.status {
            case .todo: return (order.order, 0, 0)
            case .done: return (0, order.order, 0)
            case .stash: return (0, 0, order.order)
            }
        }()
        
        self.init(uuid: uuid, name: name, bgColorHex: bgColorHex, list: list, todoOrder: todoOrder, doneOrder: doneOrder, stashOrder: stashOrder, lastServerUpdate: lastServerUpdate, removed: removed)
    }
    
    // MARK: - Filters
    
    static func createFilter(_ uuid: String) -> String {
        return "uuid == '\(uuid)'"
    }
    
    static func createFilterWithName(_ name: String) -> String {
        return "name == '\(name)'"
    }
    
    static func createFilter(_ name: String, listUuid: String) -> String {
        return "name == '\(name)' AND listOpt.uuid = '\(listUuid)'"
    }
    
    static func createFilterWithNames(_ names: [String], listUuid: String) -> String {
        let sectionsNamesStr: String = names.map{"'\($0)'"}.joined(separator: ",")
        return "name IN {\(sectionsNamesStr)} AND listOpt.uuid = '\(listUuid)'"
    }
    
    static func createFilterNameContains(_ text: String) -> String {
        return "name CONTAINS[c] '\(text)'"
    }
    
    static func createFilterList(_ listUuid: String) -> String {
        return "listOpt.uuid == '\(listUuid)'"
    }
    
    // MARK: -
    
    static func fromDict(_ dict: [String: AnyObject], list: List) -> DBSection {
        let item = DBSection()
        item.uuid = dict["uuid"]! as! String
        item.name = dict["name"]! as! String
        let colorStr = dict["color"]! as! String
        let color = UIColor(hexString: colorStr)
        item.setColor(color)
        item.list = list
        item.todoOrder = dict["todoOrder"]! as! Int
        item.doneOrder = dict["doneOrder"]! as! Int
        item.stashOrder = dict["stashOrder"]! as! Int
        item.setSyncableFieldswithRemoteDict(dict)
        return item
    }
    
    func toDict() -> [String: AnyObject] {
        var dict = [String: AnyObject]()
        dict["uuid"] = uuid as AnyObject?
        dict["name"] = name as AnyObject?
        dict["color"] = bgColorHex as AnyObject?
        dict["list"] = list.toDict() as AnyObject?        
        dict["todoOrder"] = todoOrder as AnyObject?
        dict["doneOrder"] = doneOrder as AnyObject?
        dict["stashOrder"] = stashOrder as AnyObject?
        dict["listInput"] = list.toDict() as AnyObject?
        setSyncableFieldsInDict(&dict)
        return dict
    }

    override static func ignoredProperties() -> [String] {
        return ["list"]
    }
    
    override func deleteWithDependenciesSync(_ realm: Realm, markForSync: Bool) {
        _ = RealmSectionProvider().removeSectionDependenciesSync(realm, sectionUuid: uuid, markForSync: markForSync)
        realm.delete(self)
    }
}
