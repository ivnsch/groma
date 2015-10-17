//
//  DBListItemGroup.swift
//  shoppin
//
//  Created by ischuetz on 13/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class DBListItemGroup: DBSyncable {

    dynamic var uuid: String = ""
    dynamic var name: String = ""
    let items = RealmSwift.List<DBGroupItem>()
    
    override static func primaryKey() -> String? {
        return "uuid"
    }
}