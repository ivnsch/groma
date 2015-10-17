//
//  DBGroupItem.swift
//  shoppin
//
//  Created by ischuetz on 15/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class DBGroupItem: DBSyncable {
    
    dynamic var uuid: String = ""
    dynamic var quantity: Int = 0
    dynamic var section: DBSection = DBSection()
    dynamic var product: DBProduct = DBProduct()
    
    override static func primaryKey() -> String? {
        return "uuid"
    }
}
