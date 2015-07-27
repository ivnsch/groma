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
class DBSharedUser: Object {
    
    dynamic var email: String = ""
    
    override static func primaryKey() -> String? {
        return "email"
    }
}
