//
//  DBSection.swift
//  shoppin
//
//  Created by ischuetz on 14/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class DBSection: DBSyncable {

    dynamic var uuid: String = ""
    dynamic var name: String = ""
    dynamic var order: Int = 0
//    let listItems = RealmSwift.List<String>()
    
    override static func primaryKey() -> String? {
        return "uuid"
    }
}