//
//  DBSyncable.swift
//  shoppin
//
//  Created by ischuetz on 27/07/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

public class DBSyncable: Object {

    static let lastServerUpdateFieldName = "lastServerUpdate" // the field name in the db objects, used e.g. to do update queries
    
    static let lastUpdateFieldName = "lastUpdate" // used to send and parse the timestamp from server which is called lastUpdate instead of lastServerUpdate
    static let dirtyFieldName = "dirty"
    
    // TODO!!!! are we using lastUpdate if not remove or write a comment. Ensure we use lastServerUpdate in sync
    // ensure also that when we create the new objs with lastServerUpdate, lastUpdate is set to the same date
//    dynamic var lastUpdate: NSDate = NSDate()
    @objc dynamic var lastServerUpdate: Int64 = 0
    @objc dynamic var removed: Bool = false
    
    // We make db objs by default dirty. When the db obj comes from the server we have to set it to false.
    // the reason we don't do it the other way is 1. if we miss setting an obj to false (it's just sent again to the server), it's better than when we miss setting one to true (update is never sent to the server) 2. it's easier to miss setting it to true, as this has to be done every single local update and this is more frequent than sync calls.
    @objc dynamic var dirty: Bool = true
    
    // IMPORTANT: Use this only to store sync results
    func setSyncableFieldswithRemoteDict(_ dict: [String: AnyObject]) {
        // lastServerUpdate is called by server "lastUpdate". So we set lastServerUpdate with this. And subsequently we set lastUpdate with lastServerUpdate, as the sync is effectively updating the local db, so this is also the lastUpdate.
        self.lastServerUpdate = Int64(dict[DBSyncable.lastUpdateFieldName]! as! Double)
//        self.lastUpdate = lastServerUpdate
        self.dirty = false
    }
    
    func setSyncableFieldsInDict(_ dict: inout [String: AnyObject]) {
        dict[DBSyncable.lastUpdateFieldName] = NSNumber(value: lastServerUpdate as Int64)
    }
    
    static func dirtyFilter(_ dirty: Bool = true) -> String {
        return "\(dirtyFieldName) == \(dirty)"
    }
    
    // Helper for common code for different objects where we want to update the last server update timestamp on server response. The dirty flag is set to false, we assume this is called after server operation success so the object is synced.
    static func timestampUpdateDict(_ uuid: String, lastServerUpdate: Int64) -> [String: AnyObject] {
        return ["uuid": uuid as AnyObject, DBSyncable.lastServerUpdateFieldName: NSNumber(value: Int64(lastServerUpdate) as Int64), dirtyFieldName: false as AnyObject]
    }
    
    func deleteWithDependenciesSync(_ realm: Realm, markForSync: Bool) {
        realm.delete(self)
    }
}
