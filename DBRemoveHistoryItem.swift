//
//  DBRemoveHistoryItem.swift
//  shoppin
//
//  Created by ischuetz on 29/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class DBRemoveHistoryItem: Object {
    
    dynamic var uuid: String = ""
    dynamic var lastServerUpdate: NSDate = NSDate()

    convenience init(_ dbHistoryItem: DBHistoryItem) {
        self.init(uuid: dbHistoryItem.uuid, lastServerUpdate: dbHistoryItem.lastServerUpdate)
    }
    
    convenience init(uuid: String, lastServerUpdate: NSDate) {
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
        dict["lastUpdate"] = NSNumber(double: lastServerUpdate.timeIntervalSince1970).longValue
        return dict
    }
}