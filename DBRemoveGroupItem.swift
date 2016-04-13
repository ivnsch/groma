//
//  DBRemoveGroupItem.swift
//  shoppin
//
//  Created by ischuetz on 29/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class DBRemoveGroupItem: Object {
    
    dynamic var uuid: String = ""
    dynamic var groupUuid: String = ""
    dynamic var lastServerUpdate: Int64 = 0

    convenience init(_ dbGroupItem: DBGroupItem) {
        self.init(uuid: dbGroupItem.uuid, groupUuid: dbGroupItem.group.uuid, lastServerUpdate: dbGroupItem.lastServerUpdate)
    }
    
    convenience init(uuid: String, groupUuid: String, lastServerUpdate: Int64) {
        self.init()
        self.uuid = uuid
        self.groupUuid = groupUuid
        self.lastServerUpdate = lastServerUpdate
    }
    
    override static func primaryKey() -> String? {
        return "uuid"
    }
    
    // MARK: - Filters
    
    static func createFilter(uuid: String) -> String {
        return "uuid == '\(uuid)'"
    }
    
    static func createFilterWithGroup(groupUuid: String) -> String {
        return "groupUuid == '\(groupUuid)'"
    }
    
    // MARK: -
    
    func toDict() -> [String: AnyObject] {
        var dict = [String: AnyObject]()
        dict["uuid"] = uuid
        dict["lastUpdate"] = NSNumber(longLong: Int64(lastServerUpdate))
        return dict
    }
}
