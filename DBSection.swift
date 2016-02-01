//
//  DBSection.swift
//  shoppin
//
//  Created by ischuetz on 14/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class DBSection: DBSyncable {

    dynamic var uuid: String = ""
    dynamic var name: String = ""
    dynamic var order: Int = 0
//    let listItems = RealmSwift.List<String>()
    
    override static func primaryKey() -> String? {
        return "uuid"
    }
    
    override class func indexedProperties() -> [String] {
        return ["name"]
    }
    
    static func fromDict(dict: [String: AnyObject]) -> DBSection {
        let item = DBSection()
        item.uuid = dict["uuid"]! as! String
        item.name = dict["name"]! as! String
        item.order = dict["order"]! as! Int
        item.setSyncableFieldswithRemoteDict(dict)
        return item
    }
    
    func toDict() -> [String: AnyObject] {
        var dict = [String: AnyObject]()
        dict["uuid"] = uuid
        dict["name"] = name
        dict["order"] = order
        setSyncableFieldsInDict(dict)
        return dict
    }
}