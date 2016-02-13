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
    dynamic var product: DBProduct = DBProduct()
    dynamic var group: DBListItemGroup = DBListItemGroup()

    override static func primaryKey() -> String? {
        return "uuid"
    }
    
    static func fromDict(dict: [String: AnyObject], product: DBProduct, group: DBListItemGroup) -> DBGroupItem {
        let item = DBGroupItem()
        item.uuid = dict["uuid"]! as! String
        item.quantity = dict["quantity"]! as! Int
        item.product = product
        item.group = group
        item.product = product
        item.setSyncableFieldswithRemoteDict(dict)
        return item
    }
    
    func toDict() -> [String: AnyObject] {
        var dict = [String: AnyObject]()
        dict["uuid"] = uuid
        dict["quantity"] = quantity
        dict["product"] = product.toDict()
        dict["group"] = group.toDict()
        setSyncableFieldsInDict(dict)
        return dict
    }
}
