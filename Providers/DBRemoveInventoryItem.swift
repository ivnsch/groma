//
//  DBRemoveInventoryItem.swift
//  shoppin
//
//  Created by ischuetz on 29/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift


class DBRemoveInventoryItem: Object {
    
    dynamic var uuid: String = ""
    dynamic var inventoryUuid: String = ""
    dynamic var lastServerUpdate: Int64 = 0

    convenience init(_ dbInventoryItem: InventoryItem) {
        self.init(uuid: dbInventoryItem.uuid, inventoryUuid: dbInventoryItem.inventory.uuid, lastServerUpdate: dbInventoryItem.lastServerUpdate)
    }
    
    convenience init(uuid: String, inventoryUuid: String, lastServerUpdate: Int64) {
        self.init()
        self.uuid = uuid
        self.inventoryUuid = inventoryUuid
        self.lastServerUpdate = lastServerUpdate
    }
    
    override static func primaryKey() -> String? {
        return "uuid"
    }
    
    
    // MARK: - Filter

    static func createFilterUuid(_ uuid: String) -> String {
        return "uuid == '\(uuid)'"
    }
    
    static func createFilterForInventory(_ inventoryUuid: String) -> String {
        return "inventoryUuid == '\(inventoryUuid)'"
    }
    
    static func createFilter(_ productUuid: String, inventoryUuid: String) -> String {
        return "productUuid == '\(productUuid)' AND inventoryUuid == '\(inventoryUuid)'"
    }
    
    // MARK: -
    
    func toDict() -> [String: AnyObject] {
        var dict = [String: AnyObject]()
        dict["uuid"] = uuid as AnyObject?
        dict["lastUpdate"] = NSNumber(value: Int64(lastServerUpdate) as Int64)
        return dict
    }
}
