//
//  RealmInventoryProvider.swift
//  shoppin
//
//  Created by ischuetz on 16/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift
import QorumLogs

class RealmInventoryProvider: RealmProvider {
   
    let dbListItemProvider = RealmListItemProvider()
    let remoteInventoryProvider = RemoteInventoryProvider()
    let dbProductProvider = RealmProductProvider()
    
    func loadInventories(_ handler: @escaping ([DBInventory]) -> ()) {
        let mapper = {InventoryMapper.inventoryWithDB($0)}
        self.load(mapper, sortDescriptor: NSSortDescriptor(key: "order", ascending: true), handler: handler)
    }

    
    //////////////////
    
    func loadInventoriesRealm(_ handler: @escaping (Results<DBInventory>?) -> Void) {
        handler(loadSync(filter: nil, sortDescriptor: NSSortDescriptor(key: "order", ascending: true)))
    }
    
    //////////////////
    
    func loadInventory(_ inventory: DBInventory, sortBy: InventorySortBy, handler: @escaping (Results<InventoryItem>?) -> Void) {
        // Fixes Realm acces in incorrect thread exceptions
        let inventoryCopy = inventory.copy()
        
        do {
            let realm = try Realm()
            
            let sortData: (key: String, ascending: Bool) = {
                switch sortBy {
                case .alphabetic: return ("name", true)
                case .count: return ("quantity", false)
                }
            }()
            
            let items: Results<InventoryItem> = self.loadSync(realm, filter: InventoryItem.createFilterInventory(inventoryCopy.uuid), sortDescriptor: NSSortDescriptor(key: sortData.key, ascending: sortData.ascending))
            handler(items)

        } catch let e {
            QL4("Error: creating Realm, returning empty results, error: \(e)")
            handler(nil)
        }
    }
    
    func saveInventory(_ inventory: DBInventory, update: Bool = true, dirty: Bool, handler: @escaping (Bool) -> ()) {
        self.saveInventories([inventory], update: update, dirty: dirty, handler: handler)
    }
    
    func updateInventoriesOrder(_ orderUpdates: [OrderUpdate], withoutNotifying: [NotificationToken] = [], realm: Realm? = nil, dirty: Bool, _ handler: @escaping (Bool) -> Void) {
        doInWriteTransaction(withoutNotifying: withoutNotifying, {realm in
            for orderUpdate in orderUpdates {
                realm.create(DBInventory.self, value: DBInventory.createOrderUpdateDict(orderUpdate, dirty: dirty), update: true)
            }
            return true
        }) {(successMaybe: Bool?) in
            handler(successMaybe ?? false)
        }
    }
    
    func removeInventory(_ uuid: String, update: Bool =  true, markForSync: Bool, handler: @escaping (Bool) -> ()) {
        background({[weak self] in
            do {
                let realm = try Realm()
                try realm.write {
                    self?.removeInventorySync(realm, inventoryUuid: uuid, markForSync: markForSync)
                }
                return true
            } catch let e {
                QL4("Realm error: \(e)")
                return false
            }
            }) {(result: Bool) in
                handler(result)
        }
    }
    
    func removeInventorySync(_ realm: Realm, inventoryUuid: String, markForSync: Bool) {
   
        removeInventoryDependenciesSync(realm, inventoryUuid: inventoryUuid, markForSync: markForSync)
        
        let inventoryResults = realm.objects(DBInventory.self).filter(DBInventory.createFilter(inventoryUuid))
        if markForSync {
            let toRemove = Array(inventoryResults.map{DBRemoveInventory($0)})
            saveObjsSyncInt(realm, objs: toRemove, update: true)
        }
        
        // Update order. No synchonisation with server for this, since server also reorders on delete, and on sync. Not sure right now if reorder on sync covers all cases specially for multiple devices, for now looks sufficient.
        let allSortedDbInventories = realm.objects(DBInventory.self).sorted(by: {$0.order < $1.order})
        let updatedDbInventories: [DBInventory] = allSortedDbInventories.mapEnumerate {(index, dbList) in
            dbList.order = index
            return dbList
        }
        for updatedDbInventory in updatedDbInventories {
            realm.create(DBInventory.self, value: ["uuid": updatedDbInventory.uuid, "order": updatedDbInventory.order], update: true)
        }
        
        realm.delete(inventoryResults)
    }
    
    func removeInventoryDependenciesSync(_ realm: Realm, inventoryUuid: String, markForSync: Bool) {
        _ = DBProviders.listProvider.removeListsForInventory(realm, inventoryUuid: inventoryUuid, markForSync: markForSync)
        _ = DBProviders.historyProvider.removeHistoryItemsForInventory(realm, inventoryUuid: inventoryUuid, markForSync: markForSync)
        _ = DBProviders.inventoryItemProvider.removeInventoryItemsForInventorySync(realm, inventoryUuid: inventoryUuid, markForSync: markForSync)
    }
    
    func saveInventories(_ inventories: [DBInventory], update: Bool = true, dirty: Bool, handler: @escaping (Bool) -> ()) {
        let inventories = update ? inventories.map{$0.copy()} : inventories
        saveInventories(inventories, handler: handler)
    }
    
    func saveInventories(_ inventories: [DBInventory], update: Bool = true, handler: @escaping (Bool) -> ()) {
        self.saveObjs(inventories, update: update, handler: handler)
    }
    
    func overwrite(_ inventories: [DBInventory], clearTombstones: Bool, dirty: Bool, handler: @escaping (Bool) -> Void) {
        let dbInventories = inventories
        let additionalActions: ((Realm) -> Void)? = clearTombstones ? {realm in realm.deleteAll(DBRemoveInventory.self)} : nil
        self.overwrite(dbInventories, resetLastUpdateToServer: true, idExtractor: {$0.uuid}, additionalActions: additionalActions, handler: handler)
    }
    
    // MARK: - Sync
    
    func saveInventoriesSyncResult(_ syncResult: RemoteInventoriesWithInventoryItemsSyncResult, handler: @escaping (Bool) -> ()) {
        
        self.doInWriteTransaction({realm in
            
            let inventories = realm.objects(DBInventory.self)
            let inventoryItems = realm.objects(InventoryItem.self)
            
            realm.delete(inventories)
            realm.delete(inventoryItems)
            
            // save inventories
            var dbInventoriesDict: [String: DBInventory] = [:] // cache saved inventories for fast access when saving inventory items, which need the inventory
            let remoteInventories = syncResult.inventories
            for remoteInventory in remoteInventories {
                let dbInventory = InventoryMapper.dbWithInventory(remoteInventory)
                dbInventoriesDict[remoteInventory.inventory.uuid] = dbInventory
                realm.add(dbInventory, update: true)
            }
            
            // save inventory items
            for inventoryItemsSyncResult in syncResult.inventoryItemsSyncResults {
                for inventoryItem in inventoryItemsSyncResult.inventoryItems {
                    if let dbInventory = dbInventoriesDict[inventoryItemsSyncResult.inventoryUuid] {
                        let dbInventoryItem = InventoryItemMapper.dbInventoryItemWithRemote(inventoryItem, inventory: dbInventory)
                        realm.add(dbInventoryItem, update: true)
                    } else {
                        print("Error: Invalid response: Inventory item sync response: No inventory found for inventory item uuid")
                        // TODO good unit test for this, also send to error monitoring
                        // This should not happen, but if it does we just don't save these inventory items. The rest continues normally.
                    }
                }
            }
            
            return true
            
        }, finishHandler: {success in
            handler(success ?? false)
        })
    }
    
    func clearInventoryTombstone(_ uuid: String, handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({realm in
            realm.deleteForFilter(DBRemoveInventory.self, DBRemoveInventory.createFilter(uuid))
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func updateLastSyncTimeStamp(_ inventory: RemoteInventory, handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({[weak self] realm in
            self?.updateLastSyncTimeStampSync(realm, inventory: inventory)
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }

    func updateLastSyncTimeStamp(_ inventory: RemoteInventoryWithDependencies, handler: @escaping (Bool) -> Void) {
        self.updateLastSyncTimeStamp(inventory.inventory, handler: handler)
        // the users are not synced so only inventory
    }
    
    func updateLastSyncTimeStampSync(_ realm: Realm, inventory: RemoteInventory) {
        realm.create(DBInventory.self, value: inventory.timestampUpdateDict, update: true)
    }
}
