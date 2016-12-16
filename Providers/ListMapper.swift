//
//  ListMapper.swift
//  shoppin
//
//  Created by ischuetz on 01.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
//import ChameleonFramework

class ListMapper {

    class func dbWithLists(_ remoteLists: RemoteListsWithDependencies) -> [List] {
        let inventoriesDict = remoteLists.inventories.toDictionary{($0.inventory.uuid, InventoryMapper.dbWithInventory($0))}
        
        return remoteLists.lists.map {remoteList in
            let dbList = List()
            dbList.uuid = remoteList.uuid
            dbList.name = remoteList.name
            dbList.color = remoteList.color
            dbList.order = remoteList.order
            dbList.inventory = inventoriesDict[remoteList.inventoryUuid]!
            dbList.store = remoteList.store
            let dbSharedUsers = remoteList.users.map{SharedUserMapper.dbWithSharedUser($0)}
            dbList.dirty = false
            for dbObj in dbSharedUsers {
                dbList.users.append(dbObj)
            }
            dbList.lastServerUpdate = remoteList.lastUpdate
            return dbList
        }
    }
    
    class func listsWithRemote(_ remoteLists: RemoteListsWithDependencies) -> [List] {

        let inventoriesDict = remoteLists.inventories.toDictionary{($0.inventory.uuid, InventoryMapper.inventoryWithRemote($0))}
        
        let lists = remoteLists.lists.map {remoteList in
            List(
                uuid: remoteList.uuid,
                name: remoteList.name,
                users: remoteList.users.map{SharedUserMapper.sharedUserWithRemote($0)},
                color: remoteList.color,
                order: remoteList.order,
                inventory: inventoriesDict[remoteList.inventoryUuid]!,
                store: remoteList.store,
                lastServerUpdate: remoteList.lastUpdate
            )
        }
        
        return lists.sortedByOrder()
    }
    
    class func listWithRemote(_ remoteList: RemoteListWithDependencies) -> List {
        let inventory = InventoryMapper.inventoryWithRemote(remoteList.inventory)
        return List(
            uuid: remoteList.list.uuid,
            name: remoteList.list.name,
            users: remoteList.list.users.map{SharedUserMapper.sharedUserWithRemote($0)},
            color: remoteList.list.color,
            order: remoteList.list.order,
            inventory: inventory,
            store: remoteList.list.store,
            lastServerUpdate: remoteList.list.lastUpdate
        )
    }
}
