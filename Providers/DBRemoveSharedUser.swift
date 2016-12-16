//
//  DBSectionToRemove.swift
//  shoppin
//
//  Created by ischuetz on 29/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

// TODO!!!! do we need to send this in sync? we don't even have lastServerUpdate here
class DBRemoveSharedUser: Object {
    
    dynamic var email: String = ""
    dynamic var lastServerUpdate: Double = 0

    convenience init(_ dbSharedUser: DBSharedUser) {
        self.init()
        self.email = dbSharedUser.email
    }
    
    convenience init(email: String, lastServerUpdate: Double) {
        self.init()
        self.email = email
        self.lastServerUpdate = lastServerUpdate
    }
    
    override static func primaryKey() -> String? {
        return "email"
    }
    
    // MARK: - Filters
    
    static func createFilter(_ email: String) -> String {
        return "email == '\(email)'"
    }
    
    // MARK: -
    
    func toDict() -> [String: AnyObject] {
        var dict = [String: AnyObject]()
        dict["email"] = email as AnyObject?
        return dict
    }
}
