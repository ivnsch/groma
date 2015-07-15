//
//  DBSharedUser.swift
//  shoppin
//
//  Created by ischuetz on 14/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class DBSharedUser: Object {
    
    dynamic var uuid: String = ""
    dynamic var email: String = ""
    dynamic var firstName: String = ""
    dynamic var lastName: String = ""
    
//    dynamic var list: DBList = "" // TODO
    
    override static func primaryKey() -> String? {
        return "uuid"
    }
}
