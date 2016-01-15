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
    dynamic var order: Int = 0    
    dynamic var bgColorData: NSData = NSData()
    dynamic var fav: Int = 0
    
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