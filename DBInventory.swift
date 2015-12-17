//
//  DBInventory.swift
//  shoppin
//
//  Created by ischuetz on 21/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class DBInventory: DBSyncable {
    
    dynamic var uuid: String = ""
    dynamic var name: String = ""
    dynamic var bgColorData: NSData = NSData()
    dynamic var order: Int = 0
    
    let users = RealmSwift.List<DBSharedUser>()
    
    func bgColor() -> UIColor {
        return NSKeyedUnarchiver.unarchiveObjectWithData(bgColorData) as! UIColor
    }
    
    func setBgColor(bgColor: UIColor) {
        bgColorData = NSKeyedArchiver.archivedDataWithRootObject(bgColor)
    }
    
    override static func primaryKey() -> String? {
        return "uuid"
    }
}
