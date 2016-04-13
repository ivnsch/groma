//
//  DBSectionToRemove.swift
//  shoppin
//
//  Created by ischuetz on 29/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift
import QorumLogs

class DBSectionToRemove: Object {
    
    dynamic var uuid: String = ""
    dynamic var lastServerUpdate: Int64 = 0
    
    convenience init(_ dbSection: DBSection) {
        self.init(uuid: dbSection.uuid, lastServerUpdate: dbSection.lastServerUpdate)
    }
    
    convenience init(_ section: Section) {
        
        let lastServerUpdate = section.lastServerUpdate ?? {
            QL4("lastServerUpdate of section object is nil (?)") // don't have time to think about this now so log error msg and use 0 to return something
            return 0
        }()
        
        self.init(uuid: section.uuid, lastServerUpdate: lastServerUpdate)
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
