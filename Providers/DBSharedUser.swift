//
//  DBSharedUser.swift
//  shoppin
//
//  Created by ischuetz on 14/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

// TODO remove uuid, firstName and lastName
//class DBSharedUser: DBSyncable { // TODO is this syncable or not?
public class DBSharedUser: Object {
    
    @objc public dynamic var email: String = ""
    
    public override static func primaryKey() -> String? {
        return "email"
    }
    
    public convenience init(email: String) {
        self.init()
        
        self.email = email
    }
    
    static func fromDict(_ dict: [String: AnyObject]) -> DBSharedUser {
        let user = DBSharedUser()
        user.email = dict["email"] as! String
//        user.setSyncableFieldswithRemoteDict(dict) // for now disabled as backend doesn't have specific last update of shared user, TODO think about this, maybe send the one of user?
        return user
    }
    
    func toDict() -> [String: AnyObject] {
        var dict = [String: AnyObject]()
        dict["email"] = email as AnyObject?
        dict["foo"] = "" as AnyObject? // FIXME this is a workaround for serverside, for some reason case class & serialization didn't work with only one field
//        setSyncableFieldsInDict(dict) // no syncable obj itself, just a part of other objects
        return dict
    }
    
    func copy(email: String? = nil) -> DBSharedUser {
        return DBSharedUser(
            email: email ?? self.email
        )
    }
}
