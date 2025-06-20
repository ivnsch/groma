//
//  RealmInventoryProvider.swift
//  shoppin
//
//  Created by ischuetz on 16/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift


class RealmInventoryProvider: RealmProvider {
   
    let dbListItemProvider = RealmListItemProvider()
    let remoteInventoryProvider = RemoteInventoryProvider()
    let dbProductProvider = RealmProductProvider()

    
    //////////////////
    
    func loadInventoriesRealm(_ handler: @escaping (Results<DBInventory>?) -> Void) {
        handler(loadSync(filter: nil, sortDescriptor: NSSortDescriptor(key: "order", ascending: true)))
    }
    
    //////////////////
    
    func loadInventory(_ inventory: DBInventory, sortBy: InventorySortBy, handler: @escaping (Results<InventoryItem>?) -> Void) {
        // Fixes Realm acces in incorrect thread exceptions
        let inventoryCopy: DBInventory = inventory.copy()
        
        do {
            let realm = try RealmConfig.realm()
            
            let nameSort = SortDescriptor(keyPath: "productOpt.productOpt.itemOpt.name", ascending: true)
            let quantitySort = SortDescriptor(keyPath: "quantity", ascending: true)
            //        let unitSort = SortDescriptor(keyPath: "productOpt.unitOpt.name", ascending: true) // TODO
            
            //        let rest = [unitSort]
            
            let sortDescriptors: [SortDescriptor] = {
                switch sortBy {
                case .alphabetic: return [nameSort, quantitySort] // + rest
                case .count: return [quantitySort, nameSort] // + rest
                }
            }()
            
            let items: Results<InventoryItem> = self.loadSync(realm, predicate: InventoryItem.createFilterInventory(inventoryCopy.uuid), sortDescriptors: sortDescriptors)
            handler(items)

        } catch let e {
            logger.e("Error: creating Realm, returning empty results, error: \(e)")
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
                let realm = try RealmConfig.realm()
                try realm.write {
                    self?.removeInventorySync(realm, inventoryUuid: uuid, markForSync: markForSync)
                }
                return true
            } catch let e {
                logger.e("Realm error: \(e)")
                return false
            }
            }) {(result: Bool) in
                handler(result)
        }
    }
    
    func removeInventorySync(_ realm: Realm, inventoryUuid: String, markForSync: Bool) {
   
        removeInventoryDependenciesSync(realm, inventoryUuid: inventoryUuid, markForSync: markForSync)
        
        let inventoryResults = realm.objects(DBInventory.self).filter(DBInventory.createFilter(uuid: inventoryUuid))
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
        _ = DBProv.listProvider.removeListsForInventory(realm, inventoryUuid: inventoryUuid, markForSync: markForSync)
        _ = DBProv.historyProvider.removeHistoryItemsForInventory(realm, inventoryUuid: inventoryUuid, markForSync: markForSync)
        _ = DBProv.inventoryItemProvider.removeInventoryItemsForInventorySync(realm, inventoryUuid: inventoryUuid, markForSync: markForSync)
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
    
    //////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////
    
    // NEW
    
    func loadInventories(_ handler: @escaping (RealmSwift.List<DBInventory>?) -> Void) {
        guard let inventoriesContainer: InventoriesContainer = loadSync(predicate: nil)?.first else {
            handler(nil)
            logger.e("Invalid state: no container")
            return
        }
        handler(inventoriesContainer.inventories)
    }
    
    public func add(_ inventory: DBInventory, notificationToken: NotificationToken?, _ handler: @escaping (DBProviderResult) -> Void) {
        
        guard let inventoriesContainer: InventoriesContainer = loadSync(predicate: nil)?.first else {
            handler(.unknown)
            logger.e("Invalid state: no container")
            return
        }
        
        add(inventory, inventories: inventoriesContainer.inventories, notificationToken: notificationToken, handler)
    }

    public func add(_ inventory: DBInventory, inventories: RealmSwift.List<DBInventory>, notificationToken: NotificationToken?, _ handler: @escaping (DBProviderResult) -> Void) {

        func onNotExists() {

            let successMaybe = doInWriteTransactionSync(withoutNotifying: notificationToken.map{[$0]} ?? [], realm: inventories.realm) {realm -> Bool in
                realm.add(inventory, update: true) // it's necessary to do this additionally to append, see http://stackoverflow.com/a/40595430/930450
                inventories.append(inventory)
                return true
            }

            let isSuccess = successMaybe ?? false
            handler(isSuccess ? .success : .unknown)
        }

        exists(inventory.name) { exists in
            if exists {
                handler(.nameAlreadyExists)
            } else {
                onNotExists()
            }
        }
    }

    public func exists(_ name: String, _ handler: @escaping (Bool) -> Void) {
        handler(loadInventorySync(name: name) != nil)
    }

    public func update(_ inventory: DBInventory, input: InventoryInput, inventories: RealmSwift.List<DBInventory>, notificationToken: NotificationToken, _ handler: @escaping (Bool) -> Void) {
        let successMaybe = doInWriteTransactionSync(withoutNotifying: [notificationToken], realm: inventory.realm) {realm -> Bool in
            inventory.name = input.name
            inventory.setBgColor(input.color)
            return true
        }
        handler(successMaybe ?? false)
    }
    
    public func move(from: Int, to: Int, inventories: RealmSwift.List<DBInventory>, notificationToken: NotificationToken, _ handler: @escaping (Bool) -> Void) {
        let successMaybe = doInWriteTransactionSync(withoutNotifying: [notificationToken], realm: inventories.realm) {realm -> Bool in
            inventories.move(from: from, to: to)
            return true
        }
        handler(successMaybe ?? false)
    }
    
    public func delete(index: Int, inventories: RealmSwift.List<DBInventory>, notificationToken: NotificationToken, _ handler: @escaping (Bool) -> Void) {
        let successMaybe = doInWriteTransactionSync(withoutNotifying: [notificationToken], realm: inventories.realm) {realm -> Bool in
            let inventory = inventories[index]

            // Delete dependencies
            let inventoryItems = realm.objects(InventoryItem.self).filter(InventoryItem.createFilterInventory(inventory.uuid))
            let lists = realm.objects(List.self).filter(List.createInventoryFilter(inventory.uuid))
            let sections = realm.objects(Section.self).filter(Section.createFilter(inventoryUuid: inventory.uuid))
            let listItems = realm.objects(ListItem.self).filter(ListItem.createFilter(inventoryUuid: inventory.uuid))
            let historyItems = realm.objects(HistoryItem.self).filter(HistoryItem.createFilterWithInventory(inventory.uuid))

            realm.delete(inventoryItems)
            realm.delete(lists)
            realm.delete(sections)
            realm.delete(listItems)
            realm.delete(historyItems)

            realm.delete(inventory)

            return true
        }
        handler(successMaybe ?? false)
    }

    func loadInventorySync(name: String) -> DBInventory? {
        return loadFirstSync(predicate: DBInventory.createFilter(name: name))
    }

    //////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////
    
}

