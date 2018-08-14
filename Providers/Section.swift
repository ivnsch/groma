//
//  Section.swift
//  shoppin
//
//  Created by ischuetz on 14/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

public struct SectionUnique: Equatable {
    let name: String
    let listUuid: String
    let status: ListItemStatus
    
    init(name: String, listUuid: String, status: ListItemStatus) {
        self.name = name
        self.listUuid = listUuid
        self.status = status
    }

    public func toString() -> String {
        return "\(name)-\(listUuid)-\(status.rawValue)"
    }

    public static func ==(lhs: SectionUnique, rhs: SectionUnique) -> Bool {
        return lhs.name == rhs.name && lhs.listUuid == rhs.listUuid && lhs.status == rhs.status
    }
}

public class Section: DBSyncable, Identifiable {

//    @objc public dynamic var uuid: String = ""
    @objc public dynamic var name: String = "" {
        didSet {
            updateCompoundKey()
        }
    }
    @objc dynamic var bgColorHex: String = "000000"
    
//    let listItems = RealmSwift.List<String>()
    
    @objc dynamic var listOpt: List? = List() {
        didSet {
            updateCompoundKey()
        }
    }

    // TODO remove
    @objc public dynamic var todoOrder: Int = 0
    @objc public dynamic var doneOrder: Int = 0
    @objc public dynamic var stashOrder: Int = 0

    public let listItems = RealmSwift.List<ListItem>()
    
    @objc public dynamic var statusVal: Int = 0

    @objc public dynamic var compoundKey: String = "0-0-0"

    public var unique: SectionUnique {
        return SectionUnique(name: name, listUuid: list.uuid, status: status)
    }

    public var status: ListItemStatus {
        get {
            return ListItemStatus(rawValue: statusVal)!
        }
        set {
            statusVal = status.rawValue
            updateCompoundKey()
        }
    }
    
    public var color: UIColor {
        get {
            return UIColor(hexString: bgColorHex)
        }
        set {
            bgColorHex = newValue.hexStr
        }
    }
    
    public var list: List {
        get {
            return listOpt ?? List()
        }
        set(newList) {
            listOpt = newList
        }
    }
    
    public override static func primaryKey() -> String? {
        return "compoundKey"
    }
    
    public override class func indexedProperties() -> [String] {
        return ["name", "status"]
    }

    func compoundKeyValue() -> String {
        return "\(name)-\(list.uuid)-\(statusVal)"
    }

    fileprivate func updateCompoundKey() {
        compoundKey = compoundKeyValue()
    }

    public convenience init(name: String, color: UIColor, list: List, todoOrder: Int, doneOrder: Int, stashOrder: Int, status: ListItemStatus, lastUpdate: Date = Date(), lastServerUpdate: Int64? = nil, removed: Bool = false) {
        
        self.init()
        
        self.name = name
        self.color = color
        self.list = list
        
        self.todoOrder = todoOrder
        self.doneOrder = doneOrder
        self.stashOrder = stashOrder
        self.statusVal = status.rawValue
        
        if let lastServerUpdate = lastServerUpdate {
            self.lastServerUpdate = lastServerUpdate
        }
        self.removed = removed

        updateCompoundKey()
    }
    
    // NOTE: we reuse ListItemStatusOrder from list items, as content is what we need here also, maybe we should rename it
    public convenience init(name: String, color: UIColor, list: List, order: ListItemStatusOrder, status: ListItemStatus, lastServerUpdate: Int64? = nil, removed: Bool = false) {
        
        let (todoOrder, doneOrder, stashOrder): (Int, Int, Int) = {
            switch order.status {
            case .todo: return (order.order, 0, 0)
            case .done: return (0, order.order, 0)
            case .stash: return (0, 0, order.order)
            }
        }()
        
        self.init(name: name, color: color, list: list, todoOrder: todoOrder, doneOrder: doneOrder, stashOrder: stashOrder, status: status, lastServerUpdate: lastServerUpdate, removed: removed)
    }
    
    // MARK: - Filters
    
    // TODO review why this is used
    static func createFilterWithName(_ name: String) -> NSPredicate {
        return NSPredicate(format: "name = %@", name)
    }

    static func createFilter(unique: SectionUnique) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "name = %@", unique.name),
            NSPredicate(format: "listOpt.uuid = %@", unique.listUuid),
            NSPredicate(format: "statusVal = %@", unique.status.rawValue)
        ])
    }

    // TODO review why this is used
    static func createFilterWithNames(_ names: [String], listUuid: String) -> NSPredicate {
        let sectionsNamesStr: String = names.map{"'\($0)'"}.joined(separator: ",")
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "name IN {%@}", sectionsNamesStr),
            NSPredicate(format: "listOpt.uuid = %@", listUuid)
        ])
    }
    
    static func createFilterNameContains(_ text: String) -> NSPredicate {
        return NSPredicate(format: "name CONTAINS[c] %@", text)
    }
    
    static func createFilterList(_ listUuid: String) -> NSPredicate {
        return NSPredicate(format: "listOpt.uuid = %@", listUuid)
    }

    static func createFilter(inventoryUuid: String) -> NSPredicate {
        return NSPredicate(format: "listOpt.inventoryOpt.uuid = %@", inventoryUuid)
    }

    static func createFilterListStatus(listUuid: String, status: ListItemStatus) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "listOpt.uuid = %@", listUuid),
            NSPredicate(format: "statusVal = %@", status.rawValue)
        ])
    }

    static func createFilterListItemsIsEmpty() -> NSPredicate {
        return NSPredicate(format: "listItems.@count == 0")
    }
    
    // MARK: -

    static func fromDict(_ dict: [String: AnyObject], list: List) -> Section {
        let item = Section()
        item.name = dict["name"]! as! String
        let colorStr = dict["color"]! as! String
        let color = UIColor(hexString: colorStr)
        item.color = color
        item.list = list
        item.todoOrder = dict["todoOrder"]! as! Int
        item.doneOrder = dict["doneOrder"]! as! Int
        item.stashOrder = dict["stashOrder"]! as! Int
        item.setSyncableFieldswithRemoteDict(dict)
        return item
    }
    
    func toDict() -> [String: AnyObject] {
        var dict = [String: AnyObject]()
        dict["name"] = name as AnyObject?
        dict["bgColorHex"] = bgColorHex as AnyObject?
        dict["list"] = list.toDict() as AnyObject?        
        dict["todoOrder"] = todoOrder as AnyObject?
        dict["doneOrder"] = doneOrder as AnyObject?
        dict["stashOrder"] = stashOrder as AnyObject?
        dict["listInput"] = list.toDict() as AnyObject?
        setSyncableFieldsInDict(&dict)
        return dict
    }

    func toRealmMigrationDict(list: List) -> [String: Any] {

        var dict = [String: Any]()
        dict["name"] = name as AnyObject?
        dict["bgColorHex"] = bgColorHex as AnyObject?

        dict["listOpt"] = list

        dict["todoOrder"] = todoOrder as AnyObject?
        dict["doneOrder"] = doneOrder as AnyObject?
        dict["stashOrder"] = stashOrder as AnyObject?

        dict["statusVal"] = statusVal as AnyObject?

        dict["compoundKey"] = compoundKey as AnyObject?

        return dict
    }

    func toRealmMigrationDict2(listDict: Dictionary<String, Any>) -> [String: Any] {

        var dict = [String: Any]()
        dict["name"] = name as AnyObject?
        dict["bgColorHex"] = bgColorHex as AnyObject?

        dict["listOpt"] = listDict

        dict["todoOrder"] = todoOrder as AnyObject?
        dict["doneOrder"] = doneOrder as AnyObject?
        dict["stashOrder"] = stashOrder as AnyObject?

        return dict
    }

    public override static func ignoredProperties() -> [String] {
        return ["list", "color"]
    }
    
    override func deleteWithDependenciesSync(_ realm: Realm, markForSync: Bool) {
        _ = RealmSectionProvider().removeSectionDependenciesSync(realm, sectionUnique: unique, markForSync: markForSync)
        realm.delete(self)
    }
    
    public func same(_ section: Section) -> Bool {
        return section.unique == self.unique
    }

    public func order(_ status: ListItemStatus) -> Int {
        switch status {
        case .todo: return todoOrder
        case .done: return doneOrder
        case .stash: return stashOrder
        }
    }

    public func updateOrderMutable(_ order: ListItemStatusOrder) {
        switch order.status {
        case .todo: todoOrder = order.order
        case .done: doneOrder = order.order
        case .stash: stashOrder = order.order
        }
    }

    public func updateOrder(_ order: ListItemStatusOrder) -> Section {
        return copy(
            todoOrder: order.status == .todo ? order.order : todoOrder,
            doneOrder: order.status == .done ? order.order : doneOrder,
            stashOrder: order.status == .stash ? order.order : stashOrder
        )
    }
    
    public func copy(uuid: String? = nil, name: String? = nil, color: UIColor? = nil, list: List? = nil, todoOrder: Int? = nil, doneOrder: Int? = nil, stashOrder: Int? = nil, status: ListItemStatus? = nil, lastServerUpdate: Int64? = nil, removed: Bool? = nil) -> Section {
        return Section(
            name: name ?? self.name,
            color: color ?? self.color,
            list: list ?? self.list.copy(),

            todoOrder: todoOrder ?? self.todoOrder,
            doneOrder: doneOrder ?? self.doneOrder,
            stashOrder: stashOrder ?? self.stashOrder,

            status: status ?? self.status,
            
            lastServerUpdate: lastServerUpdate ?? self.lastServerUpdate,
            removed: removed ?? self.removed
        )
    }
    
    public var shortOrderDebugDescription: String {
        return "[\(name)], todo: \(todoOrder), done: \(doneOrder), stash: \(stashOrder)"
    }

    public override var debugDescription: String {
        return "{\(type(of: self)) name: \(name), color: \(color), listUuid: \(list), todoOrder: \(todoOrder), doneOrder: \(doneOrder), stashOrder: \(stashOrder)}}"
    }
    
    public static func orderFieldName(_ status: ListItemStatus) -> String {
        switch status {
        case .todo: return "todoOrder"
        case .done: return "doneOrder"
        case .stash: return "stashOrder"
        }
    }
}



//
//import Foundation
//
//public final class Section: Identifiable, CustomDebugStringConvertible {
//    public let uuid: String
//    public let name: String
////    let order: Int
//    public let color: UIColor
//    public var list: List
//
//    public var todoOrder: Int
//    public var doneOrder: Int
//    public var stashOrder: Int
//
//    // TODO! list reference - a section belongs to a list
//
//    //////////////////////////////////////////////
//    // sync properties - FIXME - while Realm allows to return Realm objects from async op. This shouldn't be in model objects.
//    // the idea is that we can return the db objs from query and then do sync directly with these objs so no need to put sync attributes in model objs
//    // we could map the db objects to other db objs in order to work around the Realm issue, but this adds even more overhead, we make a lot of mappings already
//    public let lastServerUpdate: Int64?
//    public let removed: Bool
//    //////////////////////////////////////////////
//
//    public init(uuid: String, name: String, color: UIColor, list: List, todoOrder: Int, doneOrder: Int, stashOrder: Int, lastServerUpdate: Int64? = nil, removed: Bool = false) {
//        self.uuid = uuid
//        self.name = name
//        self.color = color
//        self.list = list
//
//        self.todoOrder = todoOrder
//        self.doneOrder = doneOrder
//        self.stashOrder = stashOrder
//
//        self.lastServerUpdate = lastServerUpdate
//        self.removed = removed
//    }
//
//    public convenience init(uuid: String, name: String, color: UIColor, list: List, order: ListItemStatusOrder, lastServerUpdate: Int64? = nil, removed: Bool = false) {
//        let (todoOrder, doneOrder, stashOrder): (Int, Int, Int) = {
//            switch(order.status) {
//            case .todo: return (order.order, 0, 0)
//            case .done: return (0, order.order, 0)
//            case .stash: return (0, 0, order.order)
//            }
//        }()
//        self.init(uuid: uuid, name: name, color: color, list: list, todoOrder: todoOrder, doneOrder: doneOrder, stashOrder: stashOrder, lastServerUpdate: lastServerUpdate, removed: removed)
//    }
//
//    public var shortOrderDebugDescription: String {
//        return "[\(name)], todo: \(todoOrder), done: \(doneOrder), stash: \(stashOrder)"
//    }
//
//    public var debugDescription: String {
//        return "{\(type(of: self)) uuid: \(uuid), name: \(name), color: \(color), listUuid: \(list), todoOrder: \(todoOrder), doneOrder: \(doneOrder), stashOrder: \(stashOrder), lastServerUpdate: \(lastServerUpdate)::\(lastServerUpdate?.millisToEpochDate()), removed: \(removed)}}"
//    }
//
//    public func copy(uuid: String? = nil, name: String? = nil, color: UIColor? = nil, list: List? = nil, todoOrder: Int? = nil, doneOrder: Int? = nil, stashOrder: Int? = nil, lastServerUpdate: Int64? = nil, removed: Bool? = nil) -> Section {
//        return Section(
//            uuid: uuid ?? self.uuid,
//            name: name ?? self.name,
//            color: color ?? self.color,
//            list: list ?? self.list.copy(),
//
//            todoOrder: todoOrder ?? self.todoOrder,
//            doneOrder: doneOrder ?? self.doneOrder,
//            stashOrder: stashOrder ?? self.stashOrder,
//
//            lastServerUpdate: lastServerUpdate ?? self.lastServerUpdate,
//            removed: removed ?? self.removed
//        )
//    }
//
//    public func same(_ section: Section) -> Bool {
//        return section.uuid == self.uuid
//    }
//
//    public func order(_ status: ListItemStatus) -> Int {
//        switch status {
//        case .todo: return todoOrder
//        case .done: return doneOrder
//        case .stash: return stashOrder
//        }
//    }
//
//    public func updateOrderMutable(_ order: ListItemStatusOrder) {
//        switch order.status {
//        case .todo: todoOrder = order.order
//        case .done: doneOrder = order.order
//        case .stash: stashOrder = order.order
//        }
//    }
//
//    public func updateOrder(_ order: ListItemStatusOrder) -> Section {
//        return copy(
//            todoOrder: order.status == .todo ? order.order : todoOrder,
//            doneOrder: order.status == .done ? order.order : doneOrder,
//            stashOrder: order.status == .stash ? order.order : stashOrder
//        )
//    }
//
//    public func equalsExcludingSyncAttributes(_ rhs: Section) -> Bool {
//        return uuid == rhs.uuid && name == rhs.name && color == rhs.color && list == rhs.list && todoOrder == rhs.todoOrder && doneOrder == rhs.doneOrder && stashOrder == rhs.stashOrder
//    }
//}
//
//public func ==(lhs: Section, rhs: Section) -> Bool {
//    return lhs.equalsExcludingSyncAttributes(rhs) && lhs.lastServerUpdate == rhs.lastServerUpdate && lhs.removed == rhs.removed
//}
