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
//    let listItems = RealmSwift.List<String>()
    
    dynamic var list: DBList = DBList()
    dynamic var todoOrder: Int = 0
    dynamic var doneOrder: Int = 0
    dynamic var stashOrder: Int = 0
    
    override static func primaryKey() -> String? {
        return "uuid"
    }
    
    override class func indexedProperties() -> [String] {
        return ["name"]
    }
    
    convenience init(uuid: String, name: String, list: DBList, todoOrder: Int, doneOrder: Int, stashOrder: Int, lastUpdate: NSDate = NSDate(), lastServerUpdate: NSDate? = nil, removed: Bool = false) {
        
        self.init()
        
        self.uuid = uuid
        self.name = name
        self.list = list
        
        self.todoOrder = todoOrder
        self.doneOrder = doneOrder
        self.stashOrder = stashOrder
        
        self.lastUpdate = lastUpdate
        if let lastServerUpdate = lastServerUpdate {
            self.lastServerUpdate = lastServerUpdate
        }
        self.removed = removed
    }
    
    static func fromDict(dict: [String: AnyObject], list: DBList) -> DBSection {
        let item = DBSection()
        item.uuid = dict["uuid"]! as! String
        item.name = dict["name"]! as! String
        item.list = list
        item.todoOrder = dict["todoOrder"]! as! Int
        item.doneOrder = dict["doneOrder"]! as! Int
        item.stashOrder = dict["stashOrder"]! as! Int
        item.setSyncableFieldswithRemoteDict(dict)
        return item
    }
    
    func toDict() -> [String: AnyObject] {
        var dict = [String: AnyObject]()
        dict["uuid"] = uuid
        dict["name"] = name
        dict["list"] = list.toDict()        
        dict["todoOrder"] = todoOrder
        dict["doneOrder"] = doneOrder
        dict["stashOrder"] = stashOrder
        dict["listInput"] = list.toDict()
        setSyncableFieldsInDict(dict)
        return dict
    }
    
    static func createFilter(name: String, listUuid: String) -> String {
        return "name == '\(name)' && list.uuid = '\(listUuid)'"
    }
    
}