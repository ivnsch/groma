//
//  DBInventory.swift
//  shoppin
//
//  Created by ischuetz on 21/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class DBInventory: DBSyncable {
    
    dynamic var uuid: String = ""
    dynamic var name: String = ""
    dynamic var bgColorHex: String = "000000"
    dynamic var order: Int = 0
    
    var users = RealmSwift.List<DBSharedUser>()
    
    func bgColor() -> UIColor {
        return UIColor(hexString: bgColorHex)
    }
    
    func setBgColor(_ bgColor: UIColor) {
        bgColorHex = bgColor.hexStr
    }
    
    convenience init(uuid: String, name: String, users: [DBSharedUser] = [], bgColor: UIColor, order: Int) {
        self.init()
        
        self.uuid = uuid
        self.name = name

        self.users = RealmSwift.List.list(users)
        
        self.order = order
        
        setBgColor(bgColor)
    }
    
    override static func primaryKey() -> String? {
        return "uuid"
    }
    
    // MARK: - Filters
    
    static func createFilter(_ uuid: String) -> String {
        return "uuid == '\(uuid)'"
    }
    
    // MARK: - Update
    
    // Creates dictionary to update database entry for order update
    static func createOrderUpdateDict(_ orderUpdate: OrderUpdate, dirty: Bool) -> [String: AnyObject] {
        return ["uuid": orderUpdate.uuid as AnyObject, "order": orderUpdate.order as AnyObject, DBSyncable.dirtyFieldName: dirty as AnyObject]
    }

    // MARK: -
    
    static func fromDict(_ dict: [String: AnyObject]) -> DBInventory {
        let item = DBInventory()
        let inventoryDict = dict["inventory"] as! [String: AnyObject]
        item.uuid = inventoryDict["uuid"]! as! String
        item.name = inventoryDict["name"]! as! String
        let colorStr = inventoryDict["color"]! as! String
        let color = UIColor(hexString: colorStr)
        item.setBgColor(color)
        item.order = inventoryDict["order"]! as! Int
        
        let usersDict = dict["users"] as! [[String: AnyObject]]
        let users = usersDict.map{DBSharedUser.fromDict($0)}
        for user in users {
            item.users.append(user)
        }
        
        item.setSyncableFieldswithRemoteDict(inventoryDict)
        return item
    }
    
    func toDict() -> [String: AnyObject] {
        var dict = [String: AnyObject]()
        dict["uuid"] = uuid as AnyObject?
        dict["name"] = name as AnyObject?
        dict["color"] = bgColorHex as AnyObject?
        dict["order"] = order as AnyObject?
        dict["users"] = users.map{$0.toDict()} as AnyObject
        setSyncableFieldsInDict(&dict)
        return dict
    }
    
    override func deleteWithDependenciesSync(_ realm: Realm, markForSync: Bool) {
        RealmInventoryProvider().removeInventoryDependenciesSync(realm, inventoryUuid: uuid, markForSync: markForSync)
        realm.delete(self)
    }
    
//    override var debugDescription: String {
//        return "{\(type(of: self)) uuid: \(uuid), name: \(name), users: \(users), bgColor: \(bgColor), order: \(order)}"
//    }
    
    func copy(uuid: String? = nil, name: String? = nil, users: [DBSharedUser]? = nil, bgColor: UIColor? = nil, order: Int? = nil) -> DBInventory {
        return DBInventory(
            uuid: uuid ?? self.uuid,
            name: name ?? self.name,
            users: users ?? self.users.map{$0.copy()},
            bgColor: bgColor ?? self.bgColor(),
            order: order ?? self.order
        )
    }
    
    
    func same(_ inventory: DBInventory) -> Bool {
        return self.uuid == inventory.uuid
    }
}
