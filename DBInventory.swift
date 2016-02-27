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
    
    // MARK: -
    
    static func fromDict(dict: [String: AnyObject]) -> DBInventory {
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
        dict["uuid"] = uuid
        dict["name"] = name
        dict["color"] = bgColorHex
        dict["order"] = order
        dict["users"] = users.map{$0.toDict()}
        setSyncableFieldsInDict(dict)
        return dict
    }
}
