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

    fileprivate lazy var historySortDescriptor: NSSortDescriptor = NSSortDescriptor(key: "addedDate", ascending: false)
    
    func add(_ historyItem: HistoryItem, handler: @escaping (Bool) -> Void) {
        saveObj(historyItem, update: false, handler: handler)
    }
    
    func loadHistoryItems(_ range: NSRange? = nil, inventory: DBInventory, handler: @escaping (Results<HistoryItem>?) -> Void) {
        handler(loadSync(filter: nil, sortDescriptor: historySortDescriptor))
    }

    func loadHistoryItems(_ range: NSRange? = nil, startDate: Int64, inventory: DBInventory, handler: @escaping (Results<HistoryItem>?) -> ()) {
        handler(loadSync(predicate: HistoryItem.createPredicate(startDate, inventoryUuid: inventory.uuid), sortDescriptor: historySortDescriptor))
    }

    func loadHistoryItems(_ productName: String, startDate: Int64, inventory: DBInventory, handler: @escaping (Results<HistoryItem>?) -> ()) {
        handler(loadSync(predicate: HistoryItem.createPredicate(productName, addedDate: startDate, inventoryUuid: inventory.uuid), sortDescriptor: historySortDescriptor))
    }

    func loadAllHistoryItems(_ handler: @escaping (Results<HistoryItem>?) -> Void) {
        handler(loadSync(filter: nil, sortDescriptor: historySortDescriptor))
    }
    
    func loadHistoryItems(_ monthYear: MonthYear, inventory: DBInventory, handler: @escaping (Results<HistoryItem>?) -> Void) {
        if let startDate = Date.startOfMonth(monthYear.month, year: monthYear.year)?.toMillis(), let endDate = Date.endOfMonth(monthYear.month, year: monthYear.year)?.toMillis() {
            loadHistoryItems(startDate, endDate: endDate, inventory: inventory, handler)
        } else {
            print("Error: Invalid month year components to get start/end date: \(monthYear)")
            handler(nil)
        }
    }
    
    func loadHistoryItems(_ startDate: Int64, endDate: Int64, inventory: DBInventory, _ handler: @escaping (Results<HistoryItem>?) -> Void) {
        handler(loadSync(predicate: HistoryItem.createPredicate(startDate, endAddedDate: endDate, inventoryUuid: inventory.uuid), sortDescriptor: historySortDescriptor))

    }
    
    // TODO change data model! one table with groups and the other with history items, 1:n (also in server)
    // this is very important as right now we fetch and iterate through ALL the history items, this is very inefficient
    func loadHistoryItemsGroups(_ range: NSRange, inventory: DBInventory, _ handler: @escaping ([HistoryItemGroup]) -> ()) {
        
        let inventory: DBInventory = inventory.copy()
        
        func retrieved(historyItemsUuidGroupedByDate: OrderedDictionary<Date, [String]>) {
            
            DispatchQueue.main.async(execute: {
                // Map date -> history item dict to HistoryItemDateGroup
                // NOTE as user we select first user in the group. Theoretically there could be more than one user. This is a simplification based in that we think it's highly unlikely that multiple users will mark items as "bought" at the exact same point of time (milliseconds). And even if they do, having one history group with (partly) wrong user is not critical.
                let historyItemsDateGroups: [HistoryItemGroup] = historyItemsUuidGroupedByDate.flatMap{k, uuids in
                    
                    if let historyItems = self.loadHistoryItemsSync(uuids: uuids) {
                        let firstUser = historyItems.first!.user // force unwrap -> if there's an array as value it must contain at least one element. If there was no history item for this date the date would not be in the dictionary
                        return HistoryItemGroup(date: k, user: firstUser, historyItems: historyItems.toArray())
                    } else {
                        QL4("Error ocurred retrieving history items for uuids: \(uuids). Skipping history items group.")
                        return nil
                    }
                }
                
                handler(historyItemsDateGroups)
            })
        }
        
        DispatchQueue.global(qos: .background).async {[weak self] in guard let weakSelf = self else {return}
            do {
                let realm = try Realm()
                let results = realm.objects(HistoryItem.self).filter(HistoryItem.createFilterWithInventory(inventory.uuid)).sorted(byKeyPath: "addedDate", ascending: false) // not using constant because weak self etc.
                
                let dateDict = weakSelf.groupByDate(results)[range].mapDictionary{(date, historyItems) in
                    // Map to uuids because of realm thread issues. We re-fetch the items in the main thread.
                    return (date, historyItems.map{return $0.uuid})
                }

                retrieved(historyItemsUuidGroupedByDate: dateDict)

            } catch _ {
                print("Error: creating Realm() in loadHistoryItemsUserDateGroups, returning empty results")
                DispatchQueue.main.async(execute: {
                    handler([])
                })
            }
        }
    }
    
    fileprivate func groupByDate(_ dbHistoryItems: Results<HistoryItem>) -> OrderedDictionary<Date, [HistoryItem]> {
        var dateDict: OrderedDictionary<Date, [HistoryItem]> = OrderedDictionary()
        for result in dbHistoryItems {
            let addedDateWithoutSeconds = millisToGroupDate(result.addedDate)
            if dateDict[addedDateWithoutSeconds] == nil {
                dateDict[addedDateWithoutSeconds] = []
            }
            dateDict[addedDateWithoutSeconds]!.append(result)
        }
        return dateDict
    }
    
    fileprivate func millisToGroupDate(_ date: Int64) -> Date {
        return date.millisToEpochDate().dateWithZeroSeconds() as Date // items are grouped using minutes
    }
    
    func loadHistoryItem(_ uuid: String, handler: @escaping (HistoryItem?) -> Void) {
        handler(loadFirstSync(filter: HistoryItem.createFilter(uuid)))
    }
    
    func removeHistoryItemsForGroupDate(_ date: Int64, inventoryUuid: String, handler: @escaping (Bool) -> Void) {
        let groupDate = millisToGroupDate(date)
        
        // since we don't want to make assumptions here about how the dates are stored (i.e. rounded to minutes or not), we load (minimal) range, group using the default grouping method and then take the items belonging to our group.
        let startDate = groupDate.inMinutes(-1)
        let endDate = groupDate.inMinutes(1)
        
        doInWriteTransaction({[weak self] realm in guard let weakSelf = self else {return false}
            let results = realm.objects(HistoryItem.self).filter(HistoryItem.createPredicate(startDate.toMillis(), endAddedDate: endDate.toMillis(), inventoryUuid: inventoryUuid))
            
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
    
    func saveHistoryItems(_ historyItems: RemoteHistoryItems, dirty: Bool, handler: @escaping (Bool) -> ()) {
        
        self.doInWriteTransaction({[weak self] realm in
            
            realm.delete(realm.objects(HistoryItem.self))
            
            let historyItemsWithRelations = HistoryItemMapper.historyItemsWithRemote(historyItems)
            
            self?.saveHistoryItemsHelper(realm, dirty: dirty, historyItemsWithRelations: historyItemsWithRelations)
            
            return true
            
            }, finishHandler: {success in
                handler(success ?? false)
            }
        )
    }

    // Overwrites all the history items
    func saveHistoryItems(_ historyItemsWithRelations: HistoryItemsWithRelations, dirty: Bool, handler: @escaping (Bool) -> ()) {
        
        self.doInWriteTransaction({[weak self] realm in
            
            realm.delete(realm.objects(HistoryItem.self))
            
            self?.saveHistoryItemsHelper(realm, dirty: dirty, historyItemsWithRelations: historyItemsWithRelations)
            
            return true
            
            }, finishHandler: {success in
                handler(success ?? false)
            }
        )
    }
    
    
    // common code, note that this is expected to be executed in a transaction
    fileprivate func saveHistoryItemsHelper(_ realm: Realm, dirty: Bool, historyItemsWithRelations: HistoryItemsWithRelations) {
        
        // save inventory items
        for inventory in historyItemsWithRelations.inventories {
            realm.add(inventory, update: true) // since we don't delete products (see comment above) we do update
        }
        
        for product in historyItemsWithRelations.products {
            realm.add(product, update: true) // since we don't delete products (see comment above) we do update
        }
        
        for user in historyItemsWithRelations.users {
            let dbUser = SharedUserMapper.dbWithSharedUser(user)
            realm.add(dbUser, update: true)
        }
        
        for historyItem in historyItemsWithRelations.historyItems {
            realm.add(historyItem, update: true)
        }
    }
    
    func saveHistoryItemsSyncResult(_ historyItems: RemoteHistoryItems, handler: @escaping (Bool) -> ()) {
        self.saveHistoryItems(historyItems, dirty: false, handler: handler)
    }
    
    func removeHistoryItem(_ uuid: String, markForSync: Bool, handler: @escaping (Bool) -> Void) {
        self.doInWriteTransaction({[weak self] realm in
            let dbHistoryItems = realm.objects(HistoryItem.self).filter(HistoryItem.createFilter(uuid))
            if markForSync {
                let toRemove = Array(dbHistoryItems.map{DBRemoveHistoryItem($0)})
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
    func removeHistoryItemsForInventory(_ realm: Realm, inventoryUuid: String, markForSync: Bool) -> Bool {
        let dbHistoryItems = realm.objects(HistoryItem.self).filter(HistoryItem.createFilterWithInventory(inventoryUuid))
        if markForSync {
            let toRemove = Array(dbHistoryItems.map{DBRemoveHistoryItem($0)})
            saveObjsSyncInt(realm, objs: toRemove, update: true)
        }
        realm.delete(dbHistoryItems)
        return true
    }
    
    func removeHistoryItems(_ monthYear: MonthYear, inventory: DBInventory, markForSync: Bool, handler: @escaping ([String]?) -> Void) {
        
        doInWriteTransaction({[weak self] realm in
            
            if let date = monthYear.toDate() {
                
                if let endOfMonth = Date.endOfMonth(monthYear.month, year: monthYear.year) {
                    let startOfMonth = date.startOfMonth
                    
                    let dbHistoryItems = realm.objects(HistoryItem.self).filter(HistoryItem.createPredicate(startOfMonth.toMillis(), endAddedDate: endOfMonth.toMillis(), inventoryUuid: inventory.uuid))
                    if markForSync {
                        let toRemove = Array(dbHistoryItems.map{DBRemoveHistoryItem($0)})
                        self?.saveObjsSyncInt(realm, objs: toRemove, update: true)
                    }
                    
                    let deletedHistoryItemsUuids = dbHistoryItems.map{$0.uuid}
                    
                    realm.delete(dbHistoryItems)
                    return Array(deletedHistoryItemsUuids)
                    
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
    
    
    // Returns nil if error, true if found and removed something, false if there was nothing to remove
    func removeHistoryItemsOlderThan(_ date: Date, handler: @escaping (Bool?) -> Void) {
        
        doInWriteTransaction({realm in
            let items = realm.objects(HistoryItem.self).filter(HistoryItem.createPredicateOlderThan(date.toMillis()))
            let removedSomething = items.count > 0
            realm.delete(items)
            return removedSomething
            
            }, finishHandler: {(removedMaybe: Bool?) in
                if let removed = removedMaybe {
                    handler(removed)
                } else {
                    QL4("removed is nil")
                    handler(false)
                }
        })
    }

    
    func oldestDate(_ inventory: DBInventory, handler: @escaping (Date?) -> Void) {
        
        withRealm({realm in
            
            if let oldestItem = realm.objects(HistoryItem.self).sorted(byKeyPath: HistoryItem.addedDateKey, ascending: true).first {
                return oldestItem.addedDate.millisToEpochDate()
            } else {
                QL1("No items / oldest item")
                return nil
            }
            
        }, resultHandler: {(oldestDateMaybe: Date?) in
            // TODO (low prio) differentiate if there was no item or an error ocurred
            handler(oldestDateMaybe)
        })
    }
    
    // TODO!! optimise this, instead of adding everything to the tombstone table and send on sync maybe just store somewhere a flag and send it on sync, which instructs the server to delete all the history.
    func removeAllHistoryItems(_ markForSync: Bool, handler: @escaping (Bool) -> ()) {
        self.doInWriteTransaction({[weak self] realm in
            let dbHistoryItems = realm.objects(HistoryItem.self)
            if markForSync {
                let toRemove = Array(dbHistoryItems.map{DBRemoveHistoryItem($0)})
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
    
    func removeHistoryItemsGroup(_ historyItemGroup: HistoryItemGroup, markForSync: Bool, _ handler: @escaping (Bool) -> Void) {
        
        let historyItemGroup = historyItemGroup.copy()
        
        self.doInWriteTransaction({[weak self] realm in
            let dbHistoryItems = realm.objects(HistoryItem.self).filter(HistoryItem.createFilter(historyItemGroup))
            if markForSync {
                let toRemove = Array(dbHistoryItems.map{DBRemoveHistoryItem($0)})
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
    
    func addHistoryItems(_ historyItems: [HistoryItem], handler: @escaping (Bool) -> Void) {
        
        let historyItems: [HistoryItem] = historyItems.map{$0.copy()} // Fixes Realm acces in incorrect thread exceptions
        
        doInWriteTransaction({realm in
            for historyItem in historyItems {
                realm.add(historyItem, update: true)
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

    func clearHistoryItemTombstone(_ uuid: String, handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({realm in
            realm.deleteForFilter(DBRemoveHistoryItem.self, DBRemoveHistoryItem.createFilter(uuid))
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func clearHistoryItemsTombstones(_ historyItemGroup: HistoryItemGroup, handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({realm in
            for historyItem in historyItemGroup.historyItems {
                realm.deleteForFilter(DBRemoveHistoryItem.self, DBRemoveHistoryItem.createFilter(historyItem.uuid))
            }
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func clearHistoryItemsTombstones(_ uuids: [String], handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({realm in
            for uuid in uuids {
                realm.deleteForFilter(DBRemoveHistoryItem.self, DBRemoveHistoryItem.createFilter(uuid))
            }
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    // MARK: - Sync
    
    func loadHistoryItemSync(uuid: String) -> HistoryItem? {
        return loadFirstSync(filter: HistoryItem.createFilter(uuid))
    }
    
    func loadHistoryItemsSync(uuids: [String]) -> Results<HistoryItem>? {
        return loadSync(filter: HistoryItem.createFilter(uuids: uuids))
    }
}
