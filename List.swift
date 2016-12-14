//
//  List.swift
//  shoppin
//
//  Created by ischuetz on 14/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

struct ListCopyStore {
    let store: String?
    init(_ store: String?) {
        self.store = store
    }
}

class List: DBSyncable, Identifiable {
    
    dynamic var uuid: String = ""
    dynamic var name: String = ""
    dynamic var bgColorHex: String = "000000"
    dynamic var order: Int = 0
    dynamic var inventoryOpt: DBInventory? = DBInventory()
    dynamic var store: String?
    
    var inventory: DBInventory {
        get {
            return inventoryOpt ?? DBInventory()
        }
        set(newInventory) {
            inventoryOpt = newInventory
        }
    }
    
    var users = RealmSwift.List<DBSharedUser>()

    var color: UIColor {
        get {
            return UIColor(hexString: bgColorHex)
        }
        set {
            bgColorHex = newValue.hexStr
        }
    }
    
    convenience init(uuid: String, name: String, users: [DBSharedUser] = [], color: UIColor, order: Int, inventory: DBInventory, store: String?, lastServerUpdate: Int64? = nil, removed: Bool = false) {
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
    
    override static func primaryKey() -> String? {
        return "uuid"
    }
        
    // MARK: - Filters
    
    static func createFilter(_ uuid: String) -> String {
        return "uuid == '\(uuid)'"
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
    
    func copy(uuid: String? = nil, name: String? = nil, users: [DBSharedUser]? = nil, color: UIColor? = nil, order: Int? = nil, inventory: DBInventory? = nil, store: ListCopyStore? = nil, lastServerUpdate: Int64? = nil, removed: Bool? = nil) -> List {
        return List(
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
    }
    
    override static func ignoredProperties() -> [String] {
        return ["inventory", "color"]
    }
    
    override func deleteWithDependenciesSync(_ realm: Realm, markForSync: Bool) {
        _ = DBProviders.listProvider.removeListDependenciesSync(realm, listUuid: uuid, markForSync: markForSync)
        realm.delete(self)
    }
    
    func same(_ rhs: List) -> Bool {
        return self.uuid == rhs.uuid
    }
 
    var shortDebugDescription: String {
        return "{uuid: \(uuid), name: \(name), order: \(order)}"
    }

    override var debugDescription: String {
        //        return shortDebugDescription
        return "{\(type(of: self)) uuid: \(uuid), name: \(name), color: \(color), order: \(order), inventory: \(inventory), store: \(store), lastServerUpdate: \(lastServerUpdate)::\(lastServerUpdate.millisToEpochDate()), removed: \(removed)}"
    }

    
    // WARN: doesn't include listItems. Actually, should we remove list items from list? this is never used?
    func equalsExcludingSyncAttributes(_ rhs: List) -> Bool {
        return uuid == rhs.uuid && name == rhs.name && color == rhs.color && order == rhs.order && users == rhs.users && inventory == rhs.inventory && store == rhs.store
    }
}


//
//
//// Used for copy - for store which is itself an optional field, we would not be able to overwrite with a nil value (which would cause to use the value of the copied instance instead), so we wrap it instead an in another object, which correctly signalises if the caller intends to overwrite the parameter or not. If ListCopyStore is not nil, we overwrite store which whatever is passed as store, also nil.
//struct ListCopyStore {
//    let store: String?
//    init(_ store: String?) {
//        self.store = store
//    }
//}
//
//class List: Equatable, Identifiable, CustomDebugStringConvertible {
//    let uuid: String
//    let name: String
//    let listItems: [ListItem] // TODO is this used? we get the items everywhere from the provider not the list object
//    
//    let users: [DBSharedUser] // note that this will be empty if using the app offline (TODO think about showing myself in this list - right now also this will not appear offline)
//    
//    let bgColor: UIColor
//    var order: Int
//    
//    let store: String?
//    
//    let inventory: DBInventory
//    
//    //////////////////////////////////////////////
//    // sync properties - FIXME - while Realm allows to return Realm objects from async op. This shouldn't be in model objects.
//    // the idea is that we can return the db objs from query and then do sync directly with these objs so no need to put sync attributes in model objs
//    // we could map the db objects to other db objs in order to work around the Realm issue, but this adds even more overhead, we make a lot of mappings already
//    let lastServerUpdate: Int64?
//    let removed: Bool
//    //////////////////////////////////////////////
//    
//    init(uuid: String, name: String, listItems: [ListItem] = [], users: [DBSharedUser] = [], bgColor: UIColor, order: Int, inventory: DBInventory, store: String?, lastServerUpdate: Int64? = nil, removed: Bool = false) {
//        self.uuid = uuid
//        self.name = name
//        self.listItems = listItems
//        self.users = users
//        self.bgColor = bgColor
//        self.order = order
//        self.inventory = inventory
//        self.store = store
//        self.lastServerUpdate = lastServerUpdate
//        self.removed = removed
//    }
//    
//    var shortDebugDescription: String {
//        return "{uuid: \(uuid), name: \(name), order: \(order)}"
//    }
//    
//    var debugDescription: String {
//        //        return shortDebugDescription
//        return "{\(type(of: self)) uuid: \(uuid), name: \(name), bgColor: \(bgColor), order: \(order), inventory: \(inventory), store: \(store), lastServerUpdate: \(lastServerUpdate)::\(lastServerUpdate?.millisToEpochDate()), removed: \(removed)}"
//    }
//    
//    func same(_ rhs: List) -> Bool {
//        return self.uuid == rhs.uuid
//    }
//    
//    func copy(uuid: String? = nil, name: String? = nil, listItems: [ListItem]? = nil, users: [DBSharedUser]? = nil, bgColor: UIColor? = nil, order: Int? = nil, inventory: DBInventory? = nil, store: ListCopyStore? = nil, lastServerUpdate: Int64? = nil, removed: Bool? = nil) -> List {
//        return List(
//            uuid: uuid ?? self.uuid,
//            name: name ?? self.name,
//            listItems: listItems ?? self.listItems,
//            users: users ?? self.users.map{$0.copy()},
//            bgColor: bgColor ?? self.bgColor,
//            order: order ?? self.order,
//            inventory: inventory ?? self.inventory.copy(),
//            store: store.map{$0.store} ?? self.store,
//            lastServerUpdate: lastServerUpdate ?? self.lastServerUpdate,
//            removed: removed ?? self.removed
//        )
//    }
//    
//    // WARN: doesn't include listItems. Actually, should we remove list items from list? this is never used?
//    func equalsExcludingSyncAttributes(_ rhs: List) -> Bool {
//        return uuid == rhs.uuid && name == rhs.name && bgColor == rhs.bgColor && order == rhs.order && users == rhs.users && inventory == rhs.inventory && store == rhs.store
//    }
//}
//
//func ==(lhs: List, rhs: List) -> Bool {
//    return lhs.equalsExcludingSyncAttributes(rhs) && lhs.lastServerUpdate == rhs.lastServerUpdate && lhs.removed == rhs.removed
//}
