//
//  RealmHistoryProvider.swift
//  shoppin
//
//  Created by ischuetz on 12/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift
import QorumLogs

class RealmHistoryProvider: RealmProvider {

    private lazy var historySortDescriptor: NSSortDescriptor = NSSortDescriptor(key: "addedDate", ascending: false)
    
    func add(historyItem: HistoryItem, handler: Bool -> ()) {
        let dbObj = HistoryItemMapper.dbWithHistoryItem(historyItem)
        self.saveObj(dbObj, update: false, handler: handler)
    }
    
    func loadHistoryItems(range: NSRange? = nil, inventory: Inventory, handler: [HistoryItem] -> ()) {
        let mapper = {HistoryItemMapper.historyItemWith($0)} // TODO loading shared users (when there are shared users) when accessing, crash: BAD_ACCESS, re-test after realm update
        self.load(mapper, sortDescriptor: historySortDescriptor, range: range, handler: handler)
    }

    func loadHistoryItems(range: NSRange? = nil, startDate: Int64, inventory: Inventory, handler: [HistoryItem] -> ()) {
        let mapper = {HistoryItemMapper.historyItemWith($0)} // TODO loading shared users (when there are shared users) when accessing, crash: BAD_ACCESS, re-test after realm update
        self.load(mapper, predicate: DBHistoryItem.createPredicate(startDate, inventoryUuid: inventory.uuid), sortDescriptor: historySortDescriptor, range: range, handler: handler)
    }

    func loadHistoryItems(productName: String, startDate: Int64, inventory: Inventory, handler: [HistoryItem] -> ()) {
        let mapper = {HistoryItemMapper.historyItemWith($0)}
        self.load(mapper, predicate: DBHistoryItem.createPredicate(productName, addedDate: startDate, inventoryUuid: inventory.uuid), sortDescriptor: historySortDescriptor, handler: handler)
    }

    func loadAllHistoryItems(handler: [HistoryItem] -> ()) {
        let mapper = {HistoryItemMapper.historyItemWith($0)}
        self.load(mapper, sortDescriptor: historySortDescriptor, handler: handler)
    }
    
    func loadHistoryItems(monthYear: MonthYear, inventory: Inventory, handler: [HistoryItem] -> Void) {
        if let startDate = NSDate.startOfMonth(monthYear.month, year: monthYear.year)?.toMillis(), endDate = NSDate.endOfMonth(monthYear.month, year: monthYear.year)?.toMillis() {
            loadHistoryItems(startDate, endDate: endDate, inventory: inventory, handler)
        } else {
            print("Error: Invalid month year components to get start/end date: \(monthYear)")
            handler([])
        }
    }
    
    func loadHistoryItems(startDate: Int64, endDate: Int64, inventory: Inventory, _ handler: [HistoryItem] -> Void) {
        let mapper = {HistoryItemMapper.historyItemWith($0)}
        self.load(mapper, predicate: DBHistoryItem.createPredicate(startDate, endAddedDate: endDate, inventoryUuid: inventory.uuid), sortDescriptor: historySortDescriptor, handler: handler)
    }
    
    // TODO change data model! one table with groups and the other with history items, 1:n (also in server)
    // this is very important as right now we fetch and iterate through ALL the history items, this is very inefficient
    func loadHistoryItemsGroups(range: NSRange, inventory: Inventory, _ handler: [HistoryItemGroup] -> ()) {

        let finished: ([HistoryItemGroup]) -> () = {result in
            dispatch_async(dispatch_get_main_queue(), {
                handler(result)
            })
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            do {
                let realm = try Realm()
                let results = realm.objects(DBHistoryItem).filter(DBHistoryItem.createFilterWithInventory(inventory.uuid)).sorted("addedDate", ascending: false) // not using constant because weak self etc.
                
                // Group by date
                var dateDictDB: OrderedDictionary<NSDate, [DBHistoryItem]> = OrderedDictionary()
                for result in results {
                    let addedDateWithoutSeconds = result.addedDate.millisToEpochDate().dateWithZeroSeconds() // items are groped using minutes
                    if dateDictDB[addedDateWithoutSeconds] == nil {
                        dateDictDB[addedDateWithoutSeconds] = []
                    }
                    dateDictDB[addedDateWithoutSeconds]!.append(result)
                }
                
                dateDictDB = dateDictDB[range] // extract range
                let dateDict: OrderedDictionary<NSDate, [HistoryItem]> = dateDictDB.mapDictionary {(k, v) in // we do this mapping after extract range - in groupBy iteration I think this causes to evaluate the db lazy objects which is very bad performance, since we are fetching the entire history
                    return (k, v.map{item in HistoryItemMapper.historyItemWith(item)})
                }

                // Map date -> history item dict to HistoryItemDateGroup
                // NOTE as user we select first user in the group. Theoretically there could be more than one user. This is a simplification based in that we think it's highly unlikely that multiple users will mark items as "bought" at the exact same point of time (milliseconds). And even if they do, having one history group with (partly) wrong user is not critical.
                let historyItemsDateGroup: [HistoryItemGroup] = dateDict.map{k, v in
                    let firstUser = v.first!.user // force unwrap -> if there's an array as value it must contain at least one element. If there was no history item for this date the date would not be in the dictionary
                    return HistoryItemGroup(date: k, user: firstUser, historyItems: v)
                }
                
                finished(historyItemsDateGroup)
                
            } catch _ {
                print("Error: creating Realm() in loadHistoryItemsUserDateGroups, returning empty results")
                finished([])
            }
        }
    }
    
    
    func saveHistoryItems(historyItems: RemoteHistoryItems, handler: Bool -> ()) {
        
        self.doInWriteTransaction({[weak self] realm in
            
            realm.delete(realm.objects(DBHistoryItem))
            
            let historyItemsWithRelations = HistoryItemMapper.historyItemsWithRemote(historyItems)
            
            self?.saveHistoryItemsHelper(realm, historyItemsWithRelations: historyItemsWithRelations)
            
            return true
            
            }, finishHandler: {success in
                handler(success ?? false)
            }
        )
    }

    // Overwrites all the history items
    func saveHistoryItems(historyItemsWithRelations: HistoryItemsWithRelations, handler: Bool -> ()) {
        
        self.doInWriteTransaction({[weak self] realm in
            
            realm.delete(realm.objects(DBHistoryItem))
            
            self?.saveHistoryItemsHelper(realm, historyItemsWithRelations: historyItemsWithRelations)
            
            return true
            
            }, finishHandler: {success in
                handler(success ?? false)
            }
        )
    }
    
    
    // common code, note that this is expected to be executed in a transaction
    private func saveHistoryItemsHelper(realm: Realm, historyItemsWithRelations: HistoryItemsWithRelations) {
        
        // save inventory items
        for inventory in historyItemsWithRelations.inventories {
            let dbInventory = InventoryMapper.dbWithInventory(inventory)
            realm.add(dbInventory, update: true) // since we don't delete products (see comment above) we do update
        }
        
        for product in historyItemsWithRelations.products {
            let dbProduct = ProductMapper.dbWithProduct(product)
            realm.add(dbProduct, update: true) // since we don't delete products (see comment above) we do update
        }
        
        for user in historyItemsWithRelations.users {
            let dbUser = SharedUserMapper.dbWithSharedUser(user)
            realm.add(dbUser, update: true)
        }
        
        for historyItem in historyItemsWithRelations.historyItems {
            let dbHistoryItem = HistoryItemMapper.dbWithHistoryItem(historyItem)
            realm.add(dbHistoryItem, update: true)
        }
    }
    
    func saveHistoryItemsSyncResult(historyItems: RemoteHistoryItems, handler: Bool -> ()) {
        self.saveHistoryItems(historyItems, handler: handler)
    }
    
    func removeHistoryItem(uuid: String, markForSync: Bool, handler: Bool -> Void) {
        self.doInWriteTransaction({[weak self] realm in
            let dbHistoryItems = realm.objects(DBHistoryItem).filter(DBHistoryItem.createFilter(uuid))
            if markForSync {
                let toRemove = dbHistoryItems.map{DBRemoveHistoryItem($0)}
                self?.saveObjsSyncInt(realm, objs: toRemove, update: true)
            }
            realm.delete(dbHistoryItems)
            return true
            }, finishHandler: {(successMaybe: Bool?) in
                if let success = successMaybe {
                    handler(success)
                } else {
                    QL4("Error: RealmHistoryProvider.removeHistoryItem: success in nil")
                    handler(false)
                }
            }
        )
    }
    
    // Expected to be executed in do/catch and write block
    func removeHistoryItemsForInventory(realm: Realm, inventoryUuid: String, markForSync: Bool) -> Bool {
        let dbHistoryItems = realm.objects(DBHistoryItem).filter(DBHistoryItem.createFilterWithInventory(inventoryUuid))
        if markForSync {
            let toRemove = dbHistoryItems.map{DBRemoveHistoryItem($0)}
            saveObjsSyncInt(realm, objs: toRemove, update: true)
        }
        realm.delete(dbHistoryItems)
        return true
    }
    
    // TODO!! optimise this, instead of adding everything to the tombstone table and send on sync maybe just store somewhere a flag and send it on sync, which instructs the server to delete all the history.
    func removeAllHistoryItems(markForSync: Bool, handler: Bool -> ()) {
        self.doInWriteTransaction({[weak self] realm in
            let dbHistoryItems = realm.objects(DBHistoryItem)
            if markForSync {
                let toRemove = dbHistoryItems.map{DBRemoveHistoryItem($0)}
                self?.saveObjsSyncInt(realm, objs: toRemove, update: true)
            }
            realm.delete(dbHistoryItems)
            return true
            }, finishHandler: {(successMaybe: Bool?) in
                if let success = successMaybe {
                    handler(success)
                } else {
                    print("Error: RealmHistoryProvider.removeAllHistoryItems: success in nil")
                    handler(false)
                }
            }
        )
    }
    
    func removeHistoryItemsGroup(historyItemGroup: HistoryItemGroup, markForSync: Bool, _ handler: Bool -> Void) {
        self.doInWriteTransaction({[weak self] realm in
            let dbHistoryItems = realm.objects(DBHistoryItem).filter(DBHistoryItem.createFilter(historyItemGroup))
            if markForSync {
                let toRemove = dbHistoryItems.map{DBRemoveHistoryItem($0)}
                self?.saveObjsSyncInt(realm, objs: toRemove, update: true)
            }
            realm.delete(dbHistoryItems)
            return true
            }, finishHandler: {(successMaybe: Bool?) in
                if let success = successMaybe {
                    handler(success)
                } else {
                    print("Error: RealmHistoryProvider.removeHistoryItemsGroup: success in nil")
                    handler(false)
                }
            }
        )
    }
    
    func addHistoryItems(historyItems: [HistoryItem], handler: Bool -> Void) {
        doInWriteTransaction({realm in
            let dbHistoryItems: [DBHistoryItem] = historyItems.map{HistoryItemMapper.dbWithHistoryItem($0)}
            for dbHistoryItem in dbHistoryItems {
                realm.add(dbHistoryItem, update: true)
            }
            return true
            }) {(successMaybe: Bool?) in
                if let success = successMaybe {
                    handler(success)
                } else {
                    print("Error: RealmHistoryProvider.addHistoryItems: success in nil")
                    handler(false)
                }
        }
    }
    
    // MARK: - Sync

    func clearHistoryItemTombstone(uuid: String, handler: Bool -> Void) {
        doInWriteTransaction({realm in
            realm.deleteForFilter(DBRemoveHistoryItem.self, DBRemoveHistoryItem.createFilter(uuid))
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func clearHistoryItemsTombstones(historyItemGroup: HistoryItemGroup, handler: Bool -> Void) {
        doInWriteTransaction({realm in
            for historyItem in historyItemGroup.historyItems {
                realm.deleteForFilter(DBRemoveHistoryItem.self, DBRemoveHistoryItem.createFilter(historyItem.uuid))
            }
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
}