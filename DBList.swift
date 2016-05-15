//
//  DBList.swift
//  shoppin
//
//  Created by ischuetz on 14/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class DBList: DBSyncable {
    
    dynamic var uuid: String = ""
    dynamic var name: String = ""
    dynamic var bgColorHex: String = "000000"
    dynamic var order: Int = 0
    dynamic var inventoryOpt: DBInventory? = DBInventory()
    dynamic var storeOpt: String?
    
    var inventory: DBInventory {
        get {
            return inventoryOpt ?? DBInventory()
        }
        set(newInventory) {
            inventoryOpt = newInventory
        }
    }
    
    let users = RealmSwift.List<DBSharedUser>()

    func bgColor() -> UIColor {
        return UIColor(hexString: bgColorHex)
    }
    
    func setBgColor(bgColor: UIColor) {
        bgColorHex = bgColor.hexStr
    }
    
    override static func primaryKey() -> String? {
        return "uuid"
    }
        
    // MARK: - Filters
    
    static func createFilter(uuid: String) -> String {
        return "uuid == '\(uuid)'"
    }
    
    static func createInventoryFilter(inventoryUuid: String) -> String {
        return "inventoryOpt.uuid == '\(inventoryUuid)'"
    }
    
    // MARK: - Update
    
    // Creates dictionary to update database entry for an order update
    static func createOrderUpdateDict(orderUpdate: OrderUpdate, dirty: Bool) -> [String: AnyObject] {
        return ["uuid": orderUpdate.uuid, "order": orderUpdate.order, DBSyncable.dirtyFieldName: dirty]
    }
    
    static func timestampUpdateDict(uuid: String, lastUpdate: Int64) -> [String: AnyObject] {
        return DBSyncable.timestampUpdateDict(uuid, lastServerUpdate: lastUpdate)
    }
    
    // MARK: -
    
    static func fromDict(dict: [String: AnyObject], inventory: DBInventory) -> DBList {
        let item = DBList()
        let listDict = dict["list"] as! [String: AnyObject]
        item.uuid = listDict["uuid"]! as! String
        item.name = listDict["name"]! as! String
        let colorStr = listDict["color"]! as! String
        let color = UIColor(hexString: colorStr)
        item.setBgColor(color)
        item.order = listDict["order"]! as! Int
        item.storeOpt = listDict["store"] as? String
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
        dict["uuid"] = uuid
        dict["name"] = name
        dict["color"] = bgColorHex
        dict["order"] = order
        dict["inventory"] = inventory.toDict()
        if let store = storeOpt {
            dict["store"] = store
        }
        dict["users"] = users.map{$0.toDict()}
        setSyncableFieldsInDict(&dict)
        return dict
    }
    
    override static func ignoredProperties() -> [String] {
        return ["inventory"]
    }
    
    override func deleteWithDependenciesSync(realm: Realm, markForSync: Bool) {
        DBProviders.listProvider.removeListDependenciesSync(realm, listUuid: uuid, markForSync: markForSync)
        realm.delete(self)
    }
}
