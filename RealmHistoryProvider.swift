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
        let dbObj = HistoryItemMapper.dbWithHistoryItem(historyItem, dirty: true)
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
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {[weak self] in guard let weakSelf = self else {return}
            do {
                let realm = try Realm()
                let results = realm.objects(DBHistoryItem).filter(DBHistoryItem.createFilterWithInventory(inventory.uuid)).sorted("addedDate", ascending: false) // not using constant because weak self etc.
                
                var dateDictDB = weakSelf.groupByDate(results)
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
    
    private func groupByDate(dbHistoryItems: Results<DBHistoryItem>) -> OrderedDictionary<NSDate, [DBHistoryItem]> {
        var dateDict: OrderedDictionary<NSDate, [DBHistoryItem]> = OrderedDictionary()
        for result in dbHistoryItems {
            let addedDateWithoutSeconds = millisToGroupDate(result.addedDate)
            if dateDict[addedDateWithoutSeconds] == nil {
                dateDict[addedDateWithoutSeconds] = []
            }
            dateDict[addedDateWithoutSeconds]!.append(result)
        }
        return dateDict
    }
    
    private func millisToGroupDate(date: Int64) -> NSDate {
        return date.millisToEpochDate().dateWithZeroSeconds() // items are grouped using minutes
    }
    
    func loadHistoryItem(uuid: String, handler: HistoryItem? -> Void) {
        let mapper = {HistoryItemMapper.historyItemWith($0)} // TODO loading shared users (when there are shared users) when accessing, crash: BAD_ACCESS, re-test after realm update
        self.loadFirst(mapper, filter: DBHistoryItem.createFilter(uuid), handler: handler)
    }
    
    func removeHistoryItemsForGroupDate(date: Int64, inventoryUuid: String, handler: Bool -> Void) {
        let groupDate = millisToGroupDate(date)
        
        // since we don't want to make assumptions here about how the dates are stored (i.e. rounded to minutes or not), we load (minimal) range, group using the default grouping method and then take the items belonging to our group.
        let startDate = groupDate.inMinutes(-1)
        let endDate = groupDate.inMinutes(1)
        
        doInWriteTransaction({[weak self] realm in guard let weakSelf = self else {return false}
            let results = realm.objects(DBHistoryItem).filter(DBHistoryItem.createPredicate(startDate.toMillis(), endAddedDate: endDate.toMillis(), inventoryUuid: inventoryUuid))
            
            QL1("Found results for date: \(groupDate) in range: \(startDate) to \(endDate): \(results)")
            
            var dateDictDB = weakSelf.groupByDate(results)
            
            if let itemsForDate = dateDictDB[groupDate] {
                realm.delete(itemsForDate)
            } else {
                QL2("Didn't find any items to delete for date: \(groupDate) in range: \(startDate) to \(endDate)")
            }
            
            return true
            
        }) {(successMaybe) -> Void in
            handler(successMaybe ?? false)
        }
    }
    
    func saveHistoryItems(historyItems: RemoteHistoryItems, dirty: Bool, handler: Bool -> ()) {
        
        self.doInWriteTransaction({[weak self] realm in
            
            realm.delete(realm.objects(DBHistoryItem))
            
            let historyItemsWithRelations = HistoryItemMapper.historyItemsWithRemote(historyItems)
            
            self?.saveHistoryItemsHelper(realm, dirty: dirty, historyItemsWithRelations: historyItemsWithRelations)
            
            return true
            
            }, finishHandler: {success in
                handler(success ?? false)
            }
        )
    }

    // Overwrites all the history items
    func saveHistoryItems(historyItemsWithRelations: HistoryItemsWithRelations, dirty: Bool, handler: Bool -> ()) {
        
        self.doInWriteTransaction({[weak self] realm in
            
            realm.delete(realm.objects(DBHistoryItem))
            
            self?.saveHistoryItemsHelper(realm, dirty: dirty, historyItemsWithRelations: historyItemsWithRelations)
            
            return true
            
            }, finishHandler: {success in
                handler(success ?? false)
            }
        )
    }
    
    
    // common code, note that this is expected to be executed in a transaction
    private func saveHistoryItemsHelper(realm: Realm, dirty: Bool, historyItemsWithRelations: HistoryItemsWithRelations) {
        
        // save inventory items
        for inventory in historyItemsWithRelations.inventories {
            let dbInventory = InventoryMapper.dbWithInventory(inventory, dirty: dirty)
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
            let dbHistoryItem = HistoryItemMapper.dbWithHistoryItem(historyItem, dirty: dirty)
            realm.add(dbHistoryItem, update: true)
        }
    }
    
    func saveHistoryItemsSyncResult(historyItems: RemoteHistoryItems, handler: Bool -> ()) {
        self.saveHistoryItems(historyItems, dirty: false, handler: handler)
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
    
    func removeHistoryItems(monthYear: MonthYear, inventory: Inventory, markForSync: Bool, handler: [String]? -> Void) {
        
        doInWriteTransaction({[weak self] realm in
            
            if let date = monthYear.toDate() {
                
                if let endOfMonth = NSDate.endOfMonth(monthYear.month, year: monthYear.year) {
                    let startOfMonth = date.startOfMonth
                    
                    let dbHistoryItems = realm.objects(DBHistoryItem).filter(DBHistoryItem.createPredicate(startOfMonth.toMillis(), endAddedDate: endOfMonth.toMillis(), inventoryUuid: inventory.uuid))
                    if markForSync {
                        let toRemove = dbHistoryItems.map{DBRemoveHistoryItem($0)}
                        self?.saveObjsSyncInt(realm, objs: toRemove, update: true)
                    }
                    
                    let deletedHistoryItemsUuids = dbHistoryItems.map{$0.uuid}
                    
                    realm.delete(dbHistoryItems)
                    return deletedHistoryItemsUuids
                    
                } else {
                    QL4("Didn't get endOfMonth for month year: \(monthYear)")
                    return nil
                }
            } else {
                QL4("Counldn't convert month year to date: \(monthYear)")
                return nil
            }
            
        }, finishHandler: {(deletedHistoryItemsUuidsMaybe: [String]?) in
            if let deletedHistoryItemsUuids = deletedHistoryItemsUuidsMaybe {
                handler(deletedHistoryItemsUuids)
            } else {
                QL4("Error: RealmHistoryProvider.removeHistoryItem: success in nil")
                handler(nil)
            }
        })
    }
    
    func oldestDate(inventory: Inventory, handler: NSDate? -> Void) {
        
        withRealm({realm in
            
            if let oldestItem = realm.objects(DBHistoryItem).sorted(DBHistoryItem.addedDateKey, ascending: true).first {
                return oldestItem.addedDate.millisToEpochDate()
            } else {
                QL1("No items / oldest item")
                return nil
            }
            
        }, resultHandler: {(oldestDateMaybe: NSDate?) in
            // TODO (low prio) differentiate if there was no item or an error ocurred
            handler(oldestDateMaybe)
        })
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
            let dbHistoryItems: [DBHistoryItem] = historyItems.map{HistoryItemMapper.dbWithHistoryItem($0, dirty: true)}
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
    
    func clearHistoryItemsTombstones(uuids: [String], handler: Bool -> Void) {
        doInWriteTransaction({realm in
            for uuid in uuids {
                realm.deleteForFilter(DBRemoveHistoryItem.self, DBRemoveHistoryItem.createFilter(uuid))
            }
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
}