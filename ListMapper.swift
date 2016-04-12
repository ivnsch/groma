//
//  ListMapper.swift
//  shoppin
//
//  Created by ischuetz on 01.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import ChameleonFramework

class ListMapper {
    
    class func dbWithList(list: List, dirty: Bool = true) -> DBList {
        let dbList = DBList()
        dbList.uuid = list.uuid
        dbList.name = list.name
        dbList.setBgColor(list.bgColor)
        dbList.order = list.order
        dbList.inventory = InventoryMapper.dbWithInventory(list.inventory)
        dbList.storeOpt = list.store
        let dbSharedUsers = list.users.map{SharedUserMapper.dbWithSharedUser($0)}
        for dbObj in dbSharedUsers {
            dbList.users.append(dbObj)
        }
        if let lastServerUpdate = list.lastServerUpdate { // needs if let because Realm doesn't support optional NSDate yet
            dbList.lastServerUpdate = lastServerUpdate
        }
        dbList.dirty = dirty
        return dbList
    }

    class func dbWithLists(remoteLists: RemoteListsWithDependencies) -> [DBList] {
        let inventoriesDict = remoteLists.inventories.toDictionary{($0.uuid, InventoryMapper.dbWithInventory($0))}
        
        return remoteLists.lists.map {remoteList in
            let dbList = DBList()
            dbList.uuid = remoteList.uuid
            dbList.name = remoteList.name
            dbList.setBgColor(remoteList.color)
            dbList.order = remoteList.order
            dbList.inventory = inventoriesDict[remoteList.inventoryUuid]!
            dbList.storeOpt = remoteList.store
            let dbSharedUsers = remoteList.users.map{SharedUserMapper.dbWithSharedUser($0)}
            dbList.dirty = false
            for dbObj in dbSharedUsers {
                dbList.users.append(dbObj)
            }
            dbList.lastServerUpdate = remoteList.lastUpdate
            return dbList
        }
    }
    
    class func listWithDB(dbList: DBList) -> List {
        let users = dbList.users.toArray().map{SharedUserMapper.sharedUserWithDB($0)}
        let inventory = InventoryMapper.inventoryWithDB(dbList.inventory)
        return List(uuid: dbList.uuid, name: dbList.name, users: users, bgColor: dbList.bgColor(), order: dbList.order, inventory: inventory, store: dbList.storeOpt, lastServerUpdate: dbList.lastServerUpdate)
    }
    
    class func listsWithRemote(remoteLists: RemoteListsWithDependencies) -> [List] {

        let inventoriesDict = remoteLists.inventories.toDictionary{($0.uuid, InventoryMapper.inventoryWithRemote($0))}
        
        let lists = remoteLists.lists.map {remoteList in
            List(
                uuid: remoteList.uuid,
                name: remoteList.name,
                users: remoteList.users.map{SharedUserMapper.sharedUserWithRemote($0)},
                bgColor: remoteList.color,
                order: remoteList.order,
                inventory: inventoriesDict[remoteList.inventoryUuid]!,
                store: remoteList.store,
                lastServerUpdate: remoteList.lastUpdate
            )
        }
        
        return lists.sortedByOrder()
    }
    
    class func listWithRemote(remoteList: RemoteListWithDependencies) -> List {
        let inventory = InventoryMapper.inventoryWithRemote(remoteList.inventory)
        return List(
            uuid: remoteList.list.uuid,
            name: remoteList.list.name,
            users: remoteList.list.users.map{SharedUserMapper.sharedUserWithRemote($0)},
            bgColor: remoteList.list.color,
            order: remoteList.list.order,
            inventory: inventory,
            store: remoteList.list.store,
            lastServerUpdate: remoteList.list.lastUpdate
        )
    }
}