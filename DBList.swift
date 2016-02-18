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
    dynamic var bgColorData: NSData = NSData()
    dynamic var order: Int = 0
    dynamic var inventory: DBInventory = DBInventory()
    
    let users = RealmSwift.List<DBSharedUser>()

    func bgColor() -> UIColor {
        return NSKeyedUnarchiver.unarchiveObjectWithData(bgColorData) as! UIColor
    }
    
    func setBgColor(bgColor: UIColor) {
        bgColorData = NSKeyedArchiver.archivedDataWithRootObject(bgColor)
    }
    
    override static func primaryKey() -> String? {
        return "uuid"
    }
    
    static func fromDict(dict: [String: AnyObject], inventory: DBInventory) -> DBList {
        let item = DBList()
        let listDict = dict["list"] as! [String: AnyObject]
        item.uuid = listDict["uuid"]! as! String
        item.name = listDict["name"]! as! String
        let colorStr = listDict["color"]! as! String
        let color = UIColor(hexString: colorStr)
        item.setBgColor(color)
        item.order = listDict["order"]! as! Int
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
        dict["color"] = bgColor().hexStr
        dict["order"] = order
        dict["inventory"] = inventory.toDict()
        dict["users"] = users.map{$0.toDict()}
        setSyncableFieldsInDict(dict)
        return dict
    }
}
