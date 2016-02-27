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
    dynamic var bgColorHex: String = "000000"

    override static func primaryKey() -> String? {
        return "uuid"
    }
    
    override class func indexedProperties() -> [String] {
        return ["name"]
    }
    
    func color() -> UIColor {
        return UIColor(hexString: bgColorHex)
    }
    
    func setColor(bgColor: UIColor) {
        bgColorHex = bgColor.hexStr
    }
    
    // MARK: - Filters
    
    static func createFilter(uuid: String) -> String {
        return "uuid == '\(uuid)'"
    }
    
    static func createFilterName(name: String) -> String {
        return "name = '\(name)'"
    }
    
    static func createFilterNameContains(text: String) -> String {
        return "name CONTAINS[c] '\(text)'"
    }
    
    // MARK: -
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
        dict["color"] = bgColorHex
        setSyncableFieldsInDict(dict)
        return dict
    }
}