//
//  DBSyncable.swift
//  shoppin
//
//  Created by ischuetz on 27/07/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class DBSyncable: Object {
    dynamic var lastUpdate: NSDate = NSDate()
    dynamic var lastServerUpdate: NSDate = NSDate()
    dynamic var removed: Bool = false
}
