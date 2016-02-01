//
//  DBProductCategory.swift
//  shoppin
//
//  Created by ischuetz on 20/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

class DBProductCategory: DBSyncable {
    
    dynamic var uuid: String = ""
    dynamic var name: String = ""
    dynamic var colorData: NSData = NSData()

    override static func primaryKey() -> String? {
        return "uuid"
    }
    
    override class func indexedProperties() -> [String] {
        return ["name"]
    }
    
    func color() -> UIColor {
        return NSKeyedUnarchiver.unarchiveObjectWithData(colorData) as! UIColor
    }
    
    func setColor(color: UIColor) {
        colorData = NSKeyedArchiver.archivedDataWithRootObject(color)
    }
    
    static func fromDict(dict: [String: AnyObject]) -> DBProductCategory {
        let item = DBProductCategory()
        item.uuid = dict["uuid"]! as! String
        item.name = dict["name"]! as! String
        let colorStr = dict["color"]! as! String
        let color = UIColor(hexString: colorStr)
        item.setColor(color)
        item.setSyncableFieldswithRemoteDict(dict)
        return item
    }
    
    func toDict() -> [String: AnyObject] {
        var dict = [String: AnyObject]()
        dict["uuid"] = uuid
        dict["name"] = name
        dict["color"] = color().hexStr
        setSyncableFieldsInDict(dict)
        return dict
    }
}