//
//  DBSyncable.swift
//  shoppin
//
//  Created by ischuetz on 27/07/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class DBSyncable: Object {
    // TODO!!!! are we using lastUpdate if not remove or write a comment. Ensure we use lastServerUpdate in sync
    // ensure also that when we create the new objs with lastServerUpdate, lastUpdate is set to the same date
    dynamic var lastUpdate: NSDate = NSDate()
    dynamic var lastServerUpdate: NSDate = NSDate(timeIntervalSince1970: 1) // Realm doesn't support nilable NSDate yet
    dynamic var removed: Bool = false
    
    // WARN: Use this only for sync, that is when the local db objects are removed to be added again - behaviour in other contexts not considered.
    func setSyncableFieldswithRemoteDict(dict: [String: AnyObject]) {
        // lastServerUpdate is called by server "lastUpdate". So we set lastServerUpdate with this. And subsequently we set lastUpdate with lastServerUpdate, as the sync is effectively updating the local db, so this is also the lastUpdate.
        self.lastServerUpdate = NSDate(timeIntervalSince1970: dict["lastUpdate"]! as! Double)
        self.lastUpdate = lastServerUpdate
    }
    
    func setSyncableFieldsInDict(var dict: [String: AnyObject]) {
        dict["lastUpdate"] = NSNumber(double: lastServerUpdate.timeIntervalSince1970).longValue
    }
}
