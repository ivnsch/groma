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
    
    dynamic var listOpt: DBList? = DBList()
    dynamic var todoOrder: Int = 0
    dynamic var doneOrder: Int = 0
    dynamic var stashOrder: Int = 0

    func color() -> UIColor {
        return UIColor(hexString: bgColorHex)
    }
    
    func setColor(bgColor: UIColor) {
        bgColorHex = bgColor.hexStr
    }
    
    var list: DBList {
        get {
            return listOpt ?? DBList()
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
    
    convenience init(uuid: String, name: String, bgColorHex: String, list: DBList, todoOrder: Int, doneOrder: Int, stashOrder: Int, lastUpdate: NSDate = NSDate(), lastServerUpdate: Int64? = nil, removed: Bool = false) {
        
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
    convenience init(uuid: String, name: String, bgColorHex: String, list: DBList, order: ListItemStatusOrder, lastServerUpdate: Int64? = nil, removed: Bool = false) {
        
        let (todoOrder, doneOrder, stashOrder): (Int, Int, Int) = {
            switch order.status {
            case .Todo: return (order.order, 0, 0)
            case .Done: return (0, order.order, 0)
            case .Stash: return (0, 0, order.order)
            }
        }()
        
        self.init(uuid: uuid, name: name, bgColorHex: bgColorHex, list: list, todoOrder: todoOrder, doneOrder: doneOrder, stashOrder: stashOrder, lastServerUpdate: lastServerUpdate, removed: removed)
    }
    
    // MARK: - Filters
    
    static func createFilter(uuid: String) -> String {
        return "uuid == '\(uuid)'"
    }
    
    static func createFilterWithName(name: String) -> String {
        return "name == '\(name)'"
    }
    
    static func createFilter(name: String, listUuid: String) -> String {
        return "name == '\(name)' AND listOpt.uuid = '\(listUuid)'"
    }
    
    static func createFilterWithNames(names: [String], listUuid: String) -> String {
        let sectionsNamesStr: String = names.map{"'\($0)'"}.joinWithSeparator(",")
        return "name IN {\(sectionsNamesStr)} AND listOpt.uuid = '\(listUuid)'"
    }
    
    static func createFilterNameContains(text: String) -> String {
        return "name CONTAINS[c] '\(text)'"
    }
    
    // MARK: -
    
    static func fromDict(dict: [String: AnyObject], list: DBList) -> DBSection {
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
        dict["uuid"] = uuid
        dict["name"] = name
        dict["color"] = bgColorHex
        dict["list"] = list.toDict()        
        dict["todoOrder"] = todoOrder
        dict["doneOrder"] = doneOrder
        dict["stashOrder"] = stashOrder
        dict["listInput"] = list.toDict()
        setSyncableFieldsInDict(dict)
        return dict
    }

    override static func ignoredProperties() -> [String] {
        return ["list"]
    }
}