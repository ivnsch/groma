//
//  InventoryMapper.swift
//  shoppin
//
//  Created by ischuetz on 21/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

class InventoryMapper {
    
    class func inventoryWithDB(dbInventory: DBInventory) -> Inventory {
        let users = dbInventory.users.toArray().map{SharedUserMapper.sharedUserWithDB($0)}
        return Inventory(uuid: dbInventory.uuid, name: dbInventory.name, users: users, bgColor: dbInventory.bgColor(), order: dbInventory.order, lastUpdate: dbInventory.lastUpdate, lastServerUpdate: dbInventory.lastServerUpdate) // lastupdate ONLY DB -> MODEL
    }
    
    class func inventoryWithRemote(remoteInventory: RemoteInventory) -> Inventory {
        // TODO bgColor
        return Inventory(uuid: remoteInventory.uuid, name: remoteInventory.name, users: remoteInventory.users.map{SharedUserMapper.sharedUserWithRemote($0)}, bgColor: UIColor.purpleColor(), order: remoteInventory.order)
    }
    
    class func dbWithInventory(inventory: Inventory) -> DBInventory {
        let db = DBInventory()
        db.uuid = inventory.uuid
        db.name = inventory.name
        db.setBgColor(inventory.bgColor)
        db.order = inventory.order
        db.lastUpdate = inventory.lastUpdate
        if let lastServerUpdate = inventory.lastServerUpdate {
            db.lastServerUpdate = lastServerUpdate
        }
        let dbSharedUsers = inventory.users.map{SharedUserMapper.dbWithSharedUser($0)}
        for dbObj in dbSharedUsers {
            db.users.append(dbObj)
        }
        return db
    }
    
    class func dbWithInventory(inventory: RemoteInventory) -> DBInventory {
        let db = DBInventory()
        db.uuid = inventory.uuid
        db.name = inventory.name
        db.lastServerUpdate = inventory.lastUpdate
        let dbSharedUsers = inventory.users.map{SharedUserMapper.dbWithSharedUser($0)}
        for dbObj in dbSharedUsers {
            db.users.append(dbObj)
        }
        return db
    }
}
