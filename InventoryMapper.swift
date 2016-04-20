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
        return Inventory(uuid: dbInventory.uuid, name: dbInventory.name, users: users, bgColor: dbInventory.bgColor(), order: dbInventory.order, lastServerUpdate: dbInventory.lastServerUpdate)
    }
    
    class func inventoryWithRemote(remoteInventory: RemoteInventory, users: [RemoteSharedUser]) -> Inventory {
        return Inventory(uuid: remoteInventory.uuid, name: remoteInventory.name, users: users.map{SharedUserMapper.sharedUserWithRemote($0)}, bgColor: remoteInventory.color, order: remoteInventory.order, lastServerUpdate: remoteInventory.lastUpdate)
    }

    class func inventoryWithRemote(remoteInventoryWithDependencies: RemoteInventoryWithDependencies) -> Inventory {
        let remoteInventory = remoteInventoryWithDependencies.inventory
        return inventoryWithRemote(remoteInventory, users: remoteInventoryWithDependencies.users)
    }
    
    class func dbWithInventory(inventory: Inventory, dirty: Bool) -> DBInventory {
        let db = DBInventory()
        db.uuid = inventory.uuid
        db.name = inventory.name
        db.setBgColor(inventory.bgColor)
        db.order = inventory.order
        db.setBgColor(inventory.bgColor)
        if let lastServerUpdate = inventory.lastServerUpdate {
            db.lastServerUpdate = lastServerUpdate
        }
        let dbSharedUsers = inventory.users.map{SharedUserMapper.dbWithSharedUser($0)}
        for dbObj in dbSharedUsers {
            db.users.append(dbObj)
        }
        db.dirty = dirty
        return db
    }
    
    class func dbWithInventory(remoteInventoryWithDependencies: RemoteInventoryWithDependencies) -> DBInventory {
        return dbWithInventory(remoteInventoryWithDependencies.inventory, users: remoteInventoryWithDependencies.users)
    }
    
    class func dbWithInventory(inventory: RemoteInventory, users: [RemoteSharedUser]) -> DBInventory {
        let db = DBInventory()
        db.uuid = inventory.uuid
        db.name = inventory.name
        db.order = inventory.order
        db.setBgColor(inventory.color)
        db.lastServerUpdate = inventory.lastUpdate
        let dbSharedUsers = users.map{SharedUserMapper.dbWithSharedUser($0)}
        for dbObj in dbSharedUsers {
            db.users.append(dbObj)
        }
        db.dirty = false
        return db
    }
}
