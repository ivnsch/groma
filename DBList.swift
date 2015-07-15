//
//  DBList.swift
//  shoppin
//
//  Created by ischuetz on 14/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class DBList: Object {
    
    dynamic var uuid: String = ""
    dynamic var name: String = ""
    let users = RealmSwift.List<DBSharedUser>()

    override static func primaryKey() -> String? {
        return "uuid"
    }
}
