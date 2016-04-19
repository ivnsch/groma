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

    func saveList(list: List, dirty: Bool = true, handler: Bool -> ()) {
        let dbList = ListMapper.dbWithList(list, dirty: dirty)
        self.saveObj(dbList, update: true, handler: handler)
    }
    
    func saveLists(lists: [List], update: Bool = false, dirty: Bool = true, handler: Bool -> ()) {
        let dbLists = lists.map{ListMapper.dbWithList($0, dirty: dirty)}
        saveLists(dbLists, update: update, handler: handler)
    }
    
    func saveLists(lists: [DBList], update: Bool = false, handler: Bool -> ()) {
        self.saveObjs(lists, update: update, handler: handler)
    }
    
    func updateListsOrder(orderUpdates: [OrderUpdate], dirty: Bool, _ handler: Bool -> Void) {
        doInWriteTransaction({realm in
            for orderUpdate in orderUpdates {
                realm.create(DBList.self, value: DBList.createOrderUpdateDict(orderUpdate, dirty: dirty), update: true)
            }
            return true
            }) {(successMaybe: Bool?) in
                handler(successMaybe ?? false)
        }
    }
    
    func overwriteLists(lists: [List], clearTombstones: Bool, handler: Bool -> ()) {
        let dbLists = lists.map{ListMapper.dbWithList($0)}
        // additional actions: delete tombstones. This flag is passed when we overwrite lists using the server's lists. Since we just got the fresh lists from the server, tombstones may refer to: 1. is not in the server anymore - so we don't need the tombstone - can delete tombstone, 2. it is in the server (can happen if for some reason we are downloading without having uploaded the most recent state first, e.g. when we deleted the list the server was being restarted, so the request failed -> added tombstone, now we call get lists on view will appear -> the list is in the server response but there's a tombstone. The ideal solution here would be filter out the tombstoned element from the downloaded list? and trigger the request to delete tombstones again, or something like that (the idea is the user doesn't see this list again as it was deleted), but we don't have time for this now so we will just clear the tombstone, basically undoing the delete. This may not sound obvious - we could also let the tombstone there, in which case the user would see the list and it would be removed in the next sync but this is even worser UX than just reverting the delete, as user doesn't know that login/connect change will remove it again, user may even decide to re-use the list and add items to it and this will get lost in next login/connect.
        let additionalActions: (Realm -> Void)? = clearTombstones ? {realm in realm.deleteAll(DBRemoveList)} : nil
        self.overwrite(dbLists, resetLastUpdateToServer: true, idExtractor: {$0.uuid}, additionalActions: additionalActions, handler: handler)
    }
    
    func loadList(uuid: String, handler: List? -> ()) {
        let mapper = {ListMapper.listWithDB($0)}
        self.loadFirst(mapper, filter: DBList.createFilter(uuid), handler: handler)
    }
    
    func loadLists(handler: [List] -> ()) {
        let mapper = {ListMapper.listWithDB($0)}
        self.load(mapper, handler: handler)
    }
    
    func remove(list: List, markForSync: Bool, handler: Bool -> ()) {
        remove(list.uuid, markForSync: markForSync, handler: handler)
    }
    
    func remove(listUuid: String, markForSync: Bool, handler: Bool -> Void) {
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
    func removeListSync(realm: Realm, listUuid: String, markForSync: Bool) -> Bool {

        removeListDependenciesSync(realm, listUuid: listUuid, markForSync: markForSync)
        
        // delete list
        if let dbList = realm.objects(DBList).filter(DBList.createFilter(listUuid)).first {
            if markForSync {
                let toRemoveList = DBRemoveList(dbList)
                saveObjsSyncInt(realm, objs: [toRemoveList], update: true)
            }
            realm.delete(dbList)
        }
        return true
    }
    
    func removeListDependenciesSync(realm: Realm, listUuid: String, markForSync: Bool) -> Bool {
        // delete listItems
        let dbListItems = realm.objects(DBListItem).filter(DBListItem.createFilterList(listUuid))
        realm.delete(dbListItems)
        // delete sections
        let dbSections = realm.objects(DBSection).filter(DBSection.createFilterList(listUuid))
        realm.delete(dbSections)
        // NOTE: it's not necessary to mark list items / section deletes for sync as syncing the list delete will also delete these in the server. TODO review if this note is still valid since we now split removeListDependencies from removeListSync and may be used in different context.
        return true
    }
    
    // Expected to be executed in do/catch and write block
    func removeListsForInventory(realm: Realm, inventoryUuid: String, markForSync: Bool) -> Bool {
        let dbLists = realm.objects(DBList).filter(DBList.createInventoryFilter(inventoryUuid))
        if markForSync {
            let toRemove = dbLists.map{DBRemoveList($0)}
            saveObjsSyncInt(realm, objs: toRemove, update: true)
        }
        realm.delete(dbLists)
        return true
    }
    
    // TODO update list
    
    
    func updateLastSyncTimeStamp(lists: RemoteListsWithDependencies, handler: Bool -> Void) {
        doInWriteTransaction({[weak self] realm in
            self?.updateLastSyncTimeStampSync(realm, lists: lists)
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func updateLastSyncTimeStampSync(realm: Realm, lists: RemoteListsWithDependencies) {
        for list in lists.lists {
            realm.create(DBList.self, value: list.timestampUpdateDict, update: true)
        }
        for inventory in lists.inventories {
            realm.create(DBInventory.self, value: inventory.timestampUpdateDict, update: true)
        }
    }
    
    func clearListTombstone(uuid: String, handler: Bool -> Void) {
        doInWriteTransaction({realm in
            realm.deleteForFilter(DBRemoveList.self, DBRemoveList.createFilter(uuid))
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
}