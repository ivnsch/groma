//
//  InventoryMapper.swift
//  shoppin
//
//  Created by ischuetz on 21/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

class InventoryMapper {
    
    class func inventoryWithDB(_ dbInventory: DBInventory) -> DBInventory {
        let users = dbInventory.users.toArray().map{SharedUserMapper.sharedUserWithDB($0)}
        return DBInventory(uuid: dbInventory.uuid, name: dbInventory.name, users: users, bgColor: dbInventory.bgColor(), order: dbInventory.order)
    }
    
    class func inventoryWithRemote(_ remoteInventory: RemoteInventory, users: [RemoteSharedUser]) -> DBInventory {
        return DBInventory(uuid: remoteInventory.uuid, name: remoteInventory.name, users: users.map{SharedUserMapper.sharedUserWithRemote($0)}, bgColor: remoteInventory.color, order: remoteInventory.order)
    }

    class func inventoryWithRemote(_ remoteInventoryWithDependencies: RemoteInventoryWithDependencies) -> DBInventory {
        let remoteInventory = remoteInventoryWithDependencies.inventory
        return inventoryWithRemote(remoteInventory, users: remoteInventoryWithDependencies.users)
    }
    
    class func dbWithInventory(_ remoteInventoryWithDependencies: RemoteInventoryWithDependencies) -> DBInventory {
        return dbWithInventory(remoteInventoryWithDependencies.inventory, users: remoteInventoryWithDependencies.users)
    }
    
    class func dbWithInventory(_ inventory: RemoteInventory, users: [RemoteSharedUser]) -> DBInventory {
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
