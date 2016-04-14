//
//  DBRemoveListItem.swift
//  shoppin
//
//  Created by ischuetz on 29/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift
import QorumLogs

class DBRemoveListItem: Object {
    
    dynamic var uuid: String = ""
    dynamic var listUuid: String = ""
    dynamic var lastServerUpdate: Int64 = 0

    convenience init(_ dbListItem: DBListItem) {
        self.init(uuid: dbListItem.uuid, listUuid: dbListItem.list.uuid, lastServerUpdate: dbListItem.lastServerUpdate)
    }
    
    convenience init(uuid: String, listUuid: String, lastServerUpdate: Int64) {
        self.init()
        self.uuid = uuid
        self.listUuid = listUuid
        self.lastServerUpdate = lastServerUpdate
    }
//    required init() {
//        fatalError("init() has not been implemented")
//    }
    
    override static func primaryKey() -> String? {
        return "uuid"
    }
    
    // MARK: - Filters
    
    static func createFilter(uuid: String) -> String {
        return "uuid == '\(uuid)'"
    }
    
    static func createFilterForList(listUuid: String) -> String {
        return "listUuid == '\(listUuid)'"
    }
    
    // MARK: -
    
    func toDict() -> [String: AnyObject] {
        var dict = [String: AnyObject]()
        dict["uuid"] = uuid
        dict["lastUpdate"] = NSNumber(longLong: Int64(lastServerUpdate))
        return dict
    }
}
