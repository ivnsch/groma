//
//  DBProduct.swift
//  shoppin
//
//  Created by ischuetz on 14/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class DBProduct: DBSyncable {
    
    dynamic var uuid: String = ""
    dynamic var name: String = ""
    dynamic var price: Float = 0
    dynamic var category: String = ""
    
    override static func primaryKey() -> String? {
        return "uuid"
    }
}
