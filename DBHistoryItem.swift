//
//  DBHistoryItem.swift
//  shoppin
//
//  Created by ischuetz on 12/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class DBHistoryItem: DBSyncable {

    dynamic var uuid: String = ""
    dynamic var inventory: DBInventory = DBInventory()
    dynamic var product: DBProduct = DBProduct()
    dynamic var addedDate: NSDate = NSDate()
    dynamic var quantity: Int = 0
    dynamic var user: DBSharedUser = DBSharedUser()
    
    override static func primaryKey() -> String? {
        return "uuid"
    }
    
    static func fromDict(dict: [String: AnyObject], inventory: DBInventory, product: DBProduct) -> DBHistoryItem {
        let item = DBHistoryItem()
        item.uuid = dict["uuid"]! as! String
        item.inventory = inventory
        item.product = product
        item.addedDate = NSDate(timeIntervalSince1970: dict["addedDate"] as! Double)
        item.quantity = dict["quantity"]! as! Int
        // TODO!!!! user -> the backend sends us the uuid, we should send for now the email instead
        let user = DBSharedUser()
        user.email = dict["userUuid"]! as! String
        item.user = user
        item.setSyncableFieldswithRemoteDict(dict)
        return item
    }
    
    func toDict() -> [String: AnyObject] {
        var dict = [String: AnyObject]()
        dict["uuid"] = uuid
        dict["inventoryUuid"] = inventory.uuid
        dict["productInput"] = product.toDict()
        dict["addedDate"] = NSNumber(double: addedDate.timeIntervalSince1970).longValue
        dict["quantity"] = quantity
        dict["user"] = user.toDict()
        setSyncableFieldsInDict(dict)
        return dict
    }
}