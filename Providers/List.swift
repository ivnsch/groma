//
//  List.swift
//  shoppin
//
//  Created by ischuetz on 14/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

public struct ListCopyStore {
    public let store: String?
    public init(_ store: String?) {
        self.store = store
    }
}

public class List: DBSyncable, Identifiable {
    
    @objc public dynamic var uuid: String = ""
    @objc public dynamic var name: String = ""
    @objc dynamic var bgColorHex: String = "000000"
    @objc public dynamic var order: Int = 0
    @objc dynamic var inventoryOpt: DBInventory? = DBInventory()
    @objc public dynamic var store: String?
    
    public var inventory: DBInventory {
        get {
            return inventoryOpt ?? DBInventory()
        }
        set(newInventory) {
            inventoryOpt = newInventory
        }
    }
    
    public var users = RealmSwift.List<DBSharedUser>()

    public var color: UIColor {
        get {
            return UIColor(hexString: bgColorHex)
        }
        set {
            bgColorHex = newValue.hexStr
        }
    }

    public var todoSections = RealmSwift.List<Section>()
    public var doneListItems = RealmSwift.List<ListItem>()
    public var stashListItems = RealmSwift.List<ListItem>()
    
    public convenience init(uuid: String, name: String, users: [DBSharedUser] = [], color: UIColor, order: Int, inventory: DBInventory, store: String?, lastServerUpdate: Int64? = nil, removed: Bool = false) {
        self.init()
        
        self.uuid = uuid
        self.name = name
        self.users = RealmSwift.List.list(users)
        self.color = color
        self.order = order
        self.inventory = inventory
        self.store = store
//        self.lastServerUpdate = lastServerUpdate
//        self.removed = removed
    }
    
    public override static func primaryKey() -> String? {
        return "uuid"
    }
        
    // MARK: - Filters
    
    static func createFilter(uuid: String) -> String {
        return "uuid == '\(uuid)'"
    }

    static func createFilter(name: String) -> String {
        return "name == '\(name)'"
    }

    static func createInventoryFilter(_ inventoryUuid: String) -> String {
        return "inventoryOpt.uuid == '\(inventoryUuid)'"
    }
    
    // MARK: - Update
    
    // Creates dictionary to update database entry for an order update
    static func createOrderUpdateDict(_ orderUpdate: OrderUpdate, dirty: Bool) -> [String: AnyObject] {
        return ["uuid": orderUpdate.uuid as AnyObject, "order": orderUpdate.order as AnyObject, DBSyncable.dirtyFieldName: dirty as AnyObject]
    }
    
    static func timestampUpdateDict(_ uuid: String, lastUpdate: Int64) -> [String: AnyObject] {
        return DBSyncable.timestampUpdateDict(uuid, lastServerUpdate: lastUpdate)
    }
    
    // MARK: -
    
    static func fromDict(_ dict: [String: AnyObject], inventory: DBInventory) -> List {
        let item = List()
        let listDict = dict["list"] as! [String: AnyObject]
        item.uuid = listDict["uuid"]! as! String
        item.name = listDict["name"]! as! String
        let colorStr = listDict["color"]! as! String
        let color = UIColor(hexString: colorStr)
        item.color = color
        item.order = listDict["order"]! as! Int
        item.store = listDict["store"] as? String
        item.inventory = inventory
        
        let usersDict = dict["users"] as! [[String: AnyObject]]
        let users = usersDict.map{DBSharedUser.fromDict($0)}
        for user in users {
            item.users.append(user)
        }
        
        item.setSyncableFieldswithRemoteDict(listDict)
        return item
    }
    
    func toDict() -> [String: AnyObject] {
        var dict = [String: AnyObject]()
        dict["uuid"] = uuid as AnyObject?
        dict["name"] = name as AnyObject?
        dict["color"] = bgColorHex as AnyObject?
        dict["order"] = order as AnyObject?
        dict["inventory"] = inventory.toDict() as AnyObject?
        dict["store"] = store as AnyObject?
        dict["users"] = users.map{$0.toDict()} as AnyObject?
        setSyncableFieldsInDict(&dict)
        return dict
    }
    
    public func copy(uuid: String? = nil, name: String? = nil, users: [DBSharedUser]? = nil, color: UIColor? = nil, order: Int? = nil, inventory: DBInventory? = nil, store: ListCopyStore? = nil, lastServerUpdate: Int64? = nil, removed: Bool? = nil) -> List {
        let list = List(
            uuid: uuid ?? self.uuid,
            name: name ?? self.name,
            users: users ?? self.users.map{$0.copy()},
            color: color ?? self.color,
            order: order ?? self.order,
            inventory: inventory ?? self.inventory.copy(),
            store: store.map{$0.store} ?? self.store,
            lastServerUpdate: lastServerUpdate ?? self.lastServerUpdate,
            removed: removed ?? self.removed
        )
        
//        list.todoSections = todoSections
//        list.doneListItems = doneListItems
//        list.stashListItems = stashListItems
        
        return list
    }
    
    
    public override static func ignoredProperties() -> [String] {
        return ["inventory", "color"]
    }
    
    override func deleteWithDependenciesSync(_ realm: Realm, markForSync: Bool) {
        _ = DBProv.listProvider.removeListDependenciesSync(realm, listUuid: uuid, markForSync: markForSync)
        realm.delete(self)
    }
    
    public func same(_ rhs: List) -> Bool {
        return self.uuid == rhs.uuid
    }
 
    public var shortDebugDescription: String {
        return "{uuid: \(uuid), name: \(name), order: \(order)}"
    }

    public override var debugDescription: String {
        //        return shortDebugDescription
        return "{\(type(of: self)) uuid: \(uuid), name: \(name), color: \(color), order: \(order), inventory: \(inventory), store: \(String(describing: store)), lastServerUpdate: \(lastServerUpdate)::\(lastServerUpdate.millisToEpochDate()), removed: \(removed)}"
    }
    
    public func sections(status: ListItemStatus) -> RealmSwift.List<Section> {
        switch status {
        case .todo: return todoSections
        case .done: fallthrough
        case .stash: fatalError("Sections only supported in TODO") // backwards compatibility - for now like this, to keep the interface generic, in case we want to re-add the sections to cart/stash later
        }
    }
    
    public func listItems(status: ListItemStatus) -> RealmSwift.List<ListItem> {
        switch status {
        case .todo: fatalError("List items not supported in TODO")  // backwards compatibility - for now like this, to keep the interface generic, in case we want to re-add the sections to cart/stash later
        case .done: return doneListItems
        case .stash: return stashListItems
        }
    }
    
    // WARN: doesn't include listItems. Actually, should we remove list items from list? this is never used?
    public func equalsExcludingSyncAttributes(_ rhs: List) -> Bool {
        return uuid == rhs.uuid && name == rhs.name && color == rhs.color && order == rhs.order && users == rhs.users && inventory == rhs.inventory && store == rhs.store
    }
}
