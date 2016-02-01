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
class DBSharedUser: Object {
    
    dynamic var email: String = ""
    
    override static func primaryKey() -> String? {
        return "email"
    }
    
    static func fromDict(dict: [String: AnyObject]) -> DBSharedUser {
        let user = DBSharedUser()
        user.email = dict["email"] as! String
        return user
    }
    
    func toDict() -> [String: AnyObject] {
        var dict = [String: AnyObject]()
        dict["email"] = email
        dict["foo"] = "" // FIXME this is a workaround for serverside, for some reason case class & serialization didn't work with only one field
//        setSyncableFieldsInDict(dict) // no syncable obj itself, just a part of other objects
        return dict
    }
}
