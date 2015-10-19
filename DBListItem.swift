//
//  DBListItem.swift
//  shoppin
//
//  Created by ischuetz on 14/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class DBListItem: DBSyncable {
    
    dynamic var uuid: String = ""
    dynamic var status: Int = 0
    dynamic var quantity: Int = 0
    dynamic var section: DBSection = DBSection()
    dynamic var product: DBProduct = DBProduct()
    dynamic var list: DBList = DBList()
    dynamic var order: Int = 0 // TODO is this still necessary with realm?
    dynamic var note: String = "" // TODO review if we can use optionals in realm, if not check if in newer version
    
    override static func primaryKey() -> String? {
        return "uuid"
    }
}

