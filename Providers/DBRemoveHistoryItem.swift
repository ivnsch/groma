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
    
    @objc dynamic var uuid: String = ""
    @objc dynamic var lastServerUpdate: Int64 = 0

    convenience init(_ dbHistoryItem: HistoryItem) {
        self.init(uuid: dbHistoryItem.uuid, lastServerUpdate: dbHistoryItem.lastServerUpdate)
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
    
    static func createFilter(_ uuid: String) -> String {
        return "uuid == '\(uuid)'"
    }
    
    // MARK: -
    
    func toDict() -> [String: AnyObject] {
        var dict = [String: AnyObject]()
        dict["uuid"] = uuid as AnyObject?
        dict["lastUpdate"] = NSNumber(value: Int64(lastServerUpdate) as Int64)
        return dict
    }
}
