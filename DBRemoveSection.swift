//
//  DBRemoveSection.swift
//  shoppin
//
//  Created by ischuetz on 16/04/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class DBRemoveSection: Object {
    
    dynamic var uuid: String = ""
    dynamic var lastServerUpdate: Int64 = 0
    
    convenience init(_ dbSection: DBSection) {
        self.init(uuid: dbSection.uuid, lastServerUpdate: dbSection.lastServerUpdate)
    }
    
    convenience init(uuid: String, lastServerUpdate: Int64) {
        self.init()
        self.uuid = uuid
        self.lastServerUpdate = lastServerUpdate
    }
    
    override static func primaryKey() -> String? {
        return "uuid"
    }
    
    // MARK: - Filters
    
    static func createFilter(uuid: String) -> String {
        return "uuid == '\(uuid)'"
    }
    
    // MARK: -
    
    func toDict() -> [String: AnyObject] {
        var dict = [String: AnyObject]()
        dict["uuid"] = uuid
        dict["lastUpdate"] = NSNumber(longLong: Int64(lastServerUpdate))
        return dict
    }
}
