//
//  RealmListProvider.swift
//  shoppin
//
//  Created by ischuetz on 14/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift
import QorumLogs

class RealmListProvider: RealmProvider {

    func saveList(_ list: List, dirty: Bool = true, handler: @escaping (Bool) -> Void) {
        let list: List = list.copy() // Fixes Realm acces in incorrect thread exceptions
        self.saveObj(list, update: true, handler: handler)
    }
    
    func saveLists(_ lists: [List], update: Bool = false, dirty: Bool = true, handler: @escaping (Bool) -> ()) {
        let lists: [List] = lists.map{$0.copy()} // Fixes Realm acces in incorrect thread exceptions
        self.saveObjs(lists, update: update, handler: handler)
    }
    
    func updateListsOrder(_ orderUpdates: [OrderUpdate], dirty: Bool, _ handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({realm in
            for orderUpdate in orderUpdates {
                realm.create(List.self, value: List.createOrderUpdateDict(orderUpdate, dirty: dirty), update: true)
            }
            return true
            }) {(successMaybe: Bool?) in
                handler(successMaybe ?? false)
        }
    }
    
    func overwriteLists(_ lists: [List], clearTombstones: Bool, handler: @escaping (Bool) -> ()) {
        let lists: [List] = lists.map{$0.copy()} // Fixes Realm acces in incorrect thread exceptions
        
        // additional actions: delete tombstones. This flag is passed when we overwrite lists using the server's lists. Since we just got the fresh lists from the server, tombstones may refer to: 1. is not in the server anymore - so we don't need the tombstone - can delete tombstone, 2. it is in the server (can happen if for some reason we are downloading without having uploaded the most recent state first, e.g. when we deleted the list the server was being restarted, so the request failed -> added tombstone, now we call get lists on view will appear -> the list is in the server response but there's a tombstone. The ideal solution here would be filter out the tombstoned element from the downloaded list? and trigger the request to delete tombstones again, or something like that (the idea is the user doesn't see this list again as it was deleted), but we don't have time for this now so we will just clear the tombstone, basically undoing the delete. This may not sound obvious - we could also let the tombstone there, in which case the user would see the list and it would be removed in the next sync but this is even worser UX than just reverting the delete, as user doesn't know that login/connect change will remove it again, user may even decide to re-use the list and add items to it and this will get lost in next login/connect.
        let additionalActions: ((Realm) -> Void)? = clearTombstones ? {realm in realm.deleteAll(DBRemoveList.self)} : nil
        
        self.overwrite(lists, resetLastUpdateToServer: true, idExtractor: {$0.uuid}, additionalActions: additionalActions, handler: handler)
    }
    
    func loadList(_ uuid: String, handler: @escaping (List?) -> Void) {
        handler(loadListSync(uuid))
    }

    //////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////

    // NEW
    
    func loadLists(_ handler: @escaping (RealmSwift.List<List>?) -> Void) {
        guard let listsContainer: ListsContainer = loadSync(predicate: nil)?.first else {
            handler(nil)
            QL4("Invalid state: no container")
            return
        }
        handler(listsContainer.lists)
    }
    
    public func add(_ list: List, notificationToken: NotificationToken?, _ handler: @escaping (Bool) -> Void) {
        
        guard let listsContainer: ListsContainer = loadSync(predicate: nil)?.first else {
            handler(false)
            QL4("Invalid state: no container")
            return
        }
        
        add(list, lists: listsContainer.lists, notificationToken: notificationToken, handler)
    }
    
    public func add(_ list: List, lists: RealmSwift.List<List>, notificationToken: NotificationToken?, _ handler: @escaping (Bool) -> Void) {
        let successMaybe = doInWriteTransactionSync(withoutNotifying: notificationToken.map{[$0]} ?? [], realm: list.realm) {realm -> Bool in
            realm.add(list, update: true) // it's necessary to do this additionally to append, see http://stackoverflow.com/a/40595430/930450
            lists.append(list)
            return true
        }
        handler(successMaybe ?? false)
    }
    
    public func update(_ list: List, input: ListInput, lists: RealmSwift.List<List>, notificationToken: NotificationToken, _ handler: @escaping (Bool) -> Void) {
        let successMaybe = doInWriteTransactionSync(withoutNotifying: [notificationToken], realm: list.realm) {realm -> Bool in
            list.name = input.name
            list.color = input.color
            list.store = input.store
            list.inventory = input.inventory
            return true
        }
        handler(successMaybe ?? false)
    }
    
    public func move(from: Int, to: Int, lists: RealmSwift.List<List>, notificationToken: NotificationToken, _ handler: @escaping (Bool) -> Void) {
        let successMaybe = doInWriteTransactionSync(withoutNotifying: [notificationToken], realm: lists.realm) {realm -> Bool in
            lists.move(from: from, to: to)
            return true
        }
        handler(successMaybe ?? false)
    }
    
    public func delete(index: Int, lists: RealmSwift.List<List>, notificationToken: NotificationToken, _ handler: @escaping (Bool) -> Void) {
        let successMaybe = doInWriteTransactionSync(withoutNotifying: [notificationToken], realm: lists.realm) {realm -> Bool in
            lists.remove(objectAtIndex: index)
            return true
        }
        handler(successMaybe ?? false)
    }
    
    //////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////

    

    func remove(_ list: List, markForSync: Bool, handler: @escaping (Bool) -> ()) {
        let list: List = list.copy() // Fixes Realm acces in incorrect thread exceptions
        remove(list.uuid, markForSync: markForSync, handler: handler)
    }
    
    func remove(_ listUuid: String, markForSync: Bool, handler: @escaping (Bool) -> Void) {
        QL1("Removing list, uuid: \(listUuid), markForSync: \(markForSync)")
        
        background({[weak self] in
            do {
                let realm = try Realm()
                var success = false 
                try realm.write {
                    success = self?.removeListSync(realm, listUuid: listUuid, markForSync: markForSync) ?? false
                }
                return success
            } catch let e {
                QL4("Realm error: \(e)")
                return false
            }
            }) {(result: Bool) in
                handler(result)
        }
    }
    
    // Expected to be executed in do/catch and write block
    func removeListSync(_ realm: Realm, listUuid: String, markForSync: Bool) -> Bool {

        _ = removeListDependenciesSync(realm, listUuid: listUuid, markForSync: markForSync)
        
        // delete list
        if let dbList = realm.objects(List.self).filter(List.createFilter(listUuid)).first {
            if markForSync {
                let toRemoveList = DBRemoveList(dbList)
                saveObjsSyncInt(realm, objs: [toRemoveList], update: true)
            }
            realm.delete(dbList)
        }
        
        // Update order. No synchonisation with server for this, since server also reorders on delete, and on sync. Not sure right now if reorder on sync covers all cases specially for multiple devices, for now looks sufficient.
        let allSortedDbLists = realm.objects(List.self).sorted(by: {$0.order < $1.order})
        let updatedDbLists: [List] = allSortedDbLists.mapEnumerate {(index, dbList) in
            dbList.order = index
            return dbList
        }
        for updatedDbList in updatedDbLists {
            realm.create(List.self, value: ["uuid": updatedDbList.uuid, "order": updatedDbList.order], update: true)
        }
        
        return true
    }
    
    func removeListDependenciesSync(_ realm: Realm, listUuid: String, markForSync: Bool) -> Bool {
        // delete listItems
        let dbListItems = realm.objects(ListItem.self).filter(ListItem.createFilterList(listUuid))
        realm.delete(dbListItems)
        // delete sections
        let dbSections = realm.objects(Section.self).filter(Section.createFilterList(listUuid))
        realm.delete(dbSections)
        // NOTE: it's not necessary to mark list items / section deletes for sync as syncing the list delete will also delete these in the server. TODO review if this note is still valid since we now split removeListDependencies from removeListSync and may be used in different context.
        return true
    }
    
    // Expected to be executed in do/catch and write block
    func removeListsForInventory(_ realm: Realm, inventoryUuid: String, markForSync: Bool) -> Bool {
        let dbLists = realm.objects(List.self).filter(List.createInventoryFilter(inventoryUuid))
        if markForSync {
            let toRemove = Array(dbLists.map{DBRemoveList($0)})
            saveObjsSyncInt(realm, objs: toRemove, update: true)
        }
        realm.delete(dbLists)
        return true
    }
    
    // TODO update list
    
    
    func updateLastSyncTimeStamp(_ lists: RemoteListsWithDependencies, handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({[weak self] realm in
            self?.updateLastSyncTimeStampSync(realm, lists: lists)
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func updateLastSyncTimeStampSync(_ realm: Realm, lists: RemoteListsWithDependencies) {
        for list in lists.lists {
            realm.create(List.self, value: list.timestampUpdateDict, update: true)
        }
//        for inventory in lists.inventories {
//            realm.create(DBInventory.self, value: inventory.inventory.timestampUpdateDict, update: true)
//        }
    }
    
    func updateLastSyncTimeStamp(_ lists: [List], timestamp: Int64, handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({realm in
            for list in lists {
                realm.create(List.self, value: List.timestampUpdateDict(list.uuid, lastUpdate: timestamp), update: true)
            }
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func clearListTombstone(_ uuid: String, handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({realm in
            realm.deleteForFilter(DBRemoveList.self, DBRemoveList.createFilter(uuid))
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    // MARK: - Sync
    
    func loadListSync(_ uuid: String) -> List? {
        return loadFirstSync(filter: List.createFilter(uuid))
    }
    
}
