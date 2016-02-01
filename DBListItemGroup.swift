//
//  DBListItemGroup.swift
//  shoppin
//
//  Created by ischuetz on 13/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class DBListItemGroup: DBSyncable {

    dynamic var uuid: String = ""
    dynamic var name: String = ""
    let items = RealmSwift.List<DBGroupItem>()
    dynamic var order: Int = 0    
    dynamic var bgColorData: NSData = NSData()
    dynamic var fav: Int = 0
    
    func bgColor() -> UIColor {
        return NSKeyedUnarchiver.unarchiveObjectWithData(bgColorData) as! UIColor
    }
    
    func setBgColor(bgColor: UIColor) {
        bgColorData = NSKeyedArchiver.archivedDataWithRootObject(bgColor)
    }
    
    override static func primaryKey() -> String? {
        return "uuid"
    }
    
    static func fromDict(dict: [String: AnyObject]) -> DBListItemGroup {
        let item = DBListItemGroup()
        item.uuid = dict["uuid"]! as! String
        item.name = dict["name"]! as! String
        item.order = dict["order"]! as! Int
        let colorStr = dict["color"]! as! String
        let color = UIColor(hexString: colorStr)
        item.setBgColor(color)
        item.fav = dict["fav"]! as! Int
        item.setSyncableFieldswithRemoteDict(dict)
        //TODO!!!! items
        return item
    }
    
    func toDict() -> [String: AnyObject] {
        var dict = [String: AnyObject]()
        dict["uuid"] = uuid
        dict["name"] = name
        // TODO!!!! items? we don't need this here correct?
        dict["order"] = order
        dict["color"] = bgColor().hexStr
        dict["fav"] = fav
        setSyncableFieldsInDict(dict)
        return dict
    }
}