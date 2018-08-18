//
//  RealmHistoryProviderSync.swift
//  ProvidersTests
//
//  Created by Ivan Schuetz on 18.08.18.
//

import Foundation
import RealmSwift

class RealmHistoryProviderSync: RealmProvider {

    fileprivate lazy var historySortDescriptor: NSSortDescriptor = NSSortDescriptor(key: "addedDate", ascending: false)

    func add(historyItem: HistoryItem) -> Bool {
        return saveObjSync(historyItem, update: false)
    }

    /**
     * Sorted by date in descending order
     */
    func loadHistoryItems(_ range: NSRange? = nil, inventory: DBInventory) -> Results<HistoryItem>? {
        return loadSync(filter: nil, sortDescriptor: historySortDescriptor)
    }

    /**
    * Returns items with date newer or equal than startDate
    */
    func loadHistoryItems(_ range: NSRange? = nil, startDate: Int64, inventory: DBInventory) -> Results<HistoryItem>? {
        return loadSync(predicate: HistoryItem.createPredicate(startDate, inventoryUuid: inventory.uuid), sortDescriptor: historySortDescriptor)
    }

    func loadHistoryItems(_ productName: String, startDate: Int64, inventory: DBInventory) -> Results<HistoryItem>? {
        return loadSync(predicate: HistoryItem.createPredicate(productName, addedDate: startDate, inventoryUuid: inventory.uuid), sortDescriptor: historySortDescriptor)
    }

    func loadAllHistoryItems() -> Results<HistoryItem>? {
        return loadSync(filter: nil, sortDescriptor: historySortDescriptor)
    }

    func loadHistoryItems(_ monthYear: MonthYear, inventory: DBInventory) -> Results<HistoryItem>? {
        if let startDate = Date.startOfMonth(monthYear.month, year: monthYear.year)?.toMillis(), let endDate = Date.endOfMonth(monthYear.month, year: monthYear.year)?.toMillis() {
            return loadHistoryItems(startDate, endDate: endDate, inventory: inventory)
        } else {
            print("Error: Invalid month year components to get start/end date: \(monthYear)")
            return nil
        }
    }

    func loadHistoryItems(_ startDate: Int64, endDate: Int64, inventory: DBInventory) -> Results<HistoryItem>? {
        return loadSync(predicate: HistoryItem.createPredicate(startDate, endAddedDate: endDate, inventoryUuid: inventory.uuid), sortDescriptor: historySortDescriptor)
    }


    // TODO change data model! one table with groups and the other with history items, 1:n (also in server)
    // this is very important as right now we fetch and iterate through ALL the history items, this is very inefficient
    func loadHistoryItemsGroups(_ range: NSRange, inventory: DBInventory) -> [HistoryItemGroup] {

        let inventory: DBInventory = inventory.copy()

        func toGroups(historyItemsUuidGroupedByDate: OrderedDictionary<Date, [String]>) -> [HistoryItemGroup] {
            // Map date -> history item dict to HistoryItemDateGroup
            // NOTE as user we select first user in the group. Theoretically there could be more than one user. This is a simplification based in that we think it's highly unlikely that multiple users will mark items as "bought" at the exact same point of time (milliseconds). And even if they do, having one history group with (partly) wrong user is not critical.
            let historyItemsDateGroups: [HistoryItemGroup] = historyItemsUuidGroupedByDate.compactMap{(arg) in
                let (k, uuids) = arg
                if let historyItems = self.loadHistoryItems(uuids: uuids) {
                    let firstUser = historyItems.first!.user // force unwrap -> if there's an array as value it must contain at least one element. If there was no history item for this date the date would not be in the dictionary
                    return HistoryItemGroup(date: k, user: firstUser, historyItems: historyItems.toArray())
                } else {
                    logger.e("Error ocurred retrieving history items for uuids: \(uuids). Skipping history items group.")
                    return nil
                }
            }

            return historyItemsDateGroups
        }

        func retrieve() -> OrderedDictionary<Date, [String]> {
            do {
                let realm = try RealmConfig.realm()
                let results = realm.objects(HistoryItem.self).filter(HistoryItem.createFilterWithInventory(inventory.uuid)).sorted(byKeyPath: "addedDate", ascending: false) // not using constant because weak self etc.

                let dateDict = groupByDate(results)[range].mapDictionary{(date, historyItems) in
                    // Map to uuids because of realm thread issues. We re-fetch the items in the main thread.
                    return (date, historyItems.map{return $0.uuid})
                }

                return dateDict

            } catch _ {
                print("Error: creating Realm() in loadHistoryItemsUserDateGroups, returning empty results")
                return OrderedDictionary()
            }
        }

        let groupedByDate = retrieve()
        return toGroups(historyItemsUuidGroupedByDate: groupedByDate)
    }

    fileprivate func groupByDate(_ dbHistoryItems: Results<HistoryItem>) -> OrderedDictionary<Date, [HistoryItem]> {
        var dateDict: OrderedDictionary<Date, [HistoryItem]> = OrderedDictionary()
        for result in dbHistoryItems {
            let addedDateWithoutSeconds = result.addedDate.millisToEpochDate().dateWithZeroSeconds()  // items are grouped using minutes
            if dateDict[addedDateWithoutSeconds] == nil {
                dateDict[addedDateWithoutSeconds] = []
            }
            dateDict[addedDateWithoutSeconds]!.append(result)
        }
        return dateDict
    }

    func loadHistoryItem(_ uuid: String) -> HistoryItem? {
        return loadFirstSync(predicate: HistoryItem.createFilter(uuid))
    }

    func removeHistoryItemsForGroupDate(_ date: Int64, inventoryUuid: String) -> Bool {
        let groupDate = date.millisToEpochDate().dateWithZeroSeconds()

        // since we don't want to make assumptions here about how the dates are stored (i.e. rounded to minutes or not), we load (minimal) range, group using the default grouping method and then take the items belonging to our group.
        let startDate = groupDate.inMinutes(-1)
        let endDate = groupDate.inMinutes(1)

        return doInWriteTransactionSync({ [weak self] realm in guard let weakSelf = self else { return false }
            let results = realm.objects(HistoryItem.self).filter(HistoryItem.createPredicate(startDate.toMillis(), endAddedDate: endDate.toMillis(), inventoryUuid: inventoryUuid))

            logger.v("Found results for date: \(groupDate) in range: \(startDate) to \(endDate): \(results)")

            var dateDictDB = weakSelf.groupByDate(results)

            if let itemsForDate = dateDictDB[groupDate] {
                realm.delete(itemsForDate)
            } else {
                logger.d("Didn't find any items to delete for date: \(groupDate) in range: \(startDate) to \(endDate)")
            }
            return true
        }) ?? false
    }

    func removeHistoryItem(_ uuid: String, markForSync: Bool) -> Bool {
        return doInWriteTransactionSync({ [weak self] realm in
            let dbHistoryItems = realm.objects(HistoryItem.self).filter(HistoryItem.createFilter(uuid))
            if markForSync {
                let toRemove = Array(dbHistoryItems.map{DBRemoveHistoryItem($0)})
                self?.saveObjsSyncInt(realm, objs: toRemove, update: true)
            }
            realm.delete(dbHistoryItems)
            return true
        }) ?? false
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

    func removeHistoryItems(_ monthYear: MonthYear, inventory: DBInventory, markForSync: Bool) -> [String]? {
        return doInWriteTransactionSync({ [weak self] realm in

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
                    logger.e("Didn't get endOfMonth for month year: \(monthYear)")
                    return nil
                }
            } else {
                logger.e("Counldn't convert month year to date: \(monthYear)")
                return nil
            }

            }
        )
    }

    // Returns nil if error, true if found and removed something, false if there was nothing to remove
    func removeHistoryItemsOlderThan(_ date: Date) -> Bool? {
        return doInWriteTransactionSync({realm in
            let items = realm.objects(HistoryItem.self).filter(HistoryItem.createPredicateOlderThan(date.toMillis()))
            let removedSomething = items.count > 0
            realm.delete(items)
            return removedSomething
        })
    }

    func oldestDate(_ inventory: DBInventory) -> Date? {
        return withRealmSync({realm in
            if let oldestItem = realm.objects(HistoryItem.self).sorted(byKeyPath: HistoryItem.addedDateKey, ascending: true).first {
                return oldestItem.addedDate.millisToEpochDate()
            } else {
                logger.v("No items / oldest item")
                return nil
            }
        })
    }

    // TODO!! optimise this, instead of adding everything to the tombstone table and send on sync maybe just store somewhere a flag and send it on sync, which instructs the server to delete all the history.
    func removeAllHistoryItems(_ markForSync: Bool) -> Bool {
        return doInWriteTransactionSync({ [weak self] realm in
            let dbHistoryItems = realm.objects(HistoryItem.self)
            if markForSync {
                let toRemove = Array(dbHistoryItems.map{DBRemoveHistoryItem($0)})
                self?.saveObjsSyncInt(realm, objs: toRemove, update: true)
            }
            realm.delete(dbHistoryItems)
            return true
        }) ?? false
    }

    func removeHistoryItemsGroup(_ historyItemGroup: HistoryItemGroup, markForSync: Bool) -> Bool {

        let historyItemGroup = historyItemGroup.copy()

        return doInWriteTransactionSync({[weak self] realm in
            let dbHistoryItems = realm.objects(HistoryItem.self).filter(HistoryItem.createFilter(historyItemGroup))
            if markForSync {
                let toRemove = Array(dbHistoryItems.map{DBRemoveHistoryItem($0)})
                self?.saveObjsSyncInt(realm, objs: toRemove, update: true)
            }
            realm.delete(dbHistoryItems)
            return true
        }) ?? false
    }

    func addHistoryItems(_ historyItems: [HistoryItem]) -> Bool {

        let historyItems: [HistoryItem] = historyItems.map{$0.copy()} // Fixes Realm acces in incorrect thread exceptions

        return doInWriteTransactionSync({ realm in
            for historyItem in historyItems {
                realm.add(historyItem, update: true)
            }
            return true
        }) ?? false
    }

    func loadHistoryItem(uuid: String) -> HistoryItem? {
        return loadFirstSync(predicate: HistoryItem.createFilter(uuid))
    }

    func loadHistoryItems(uuids: [String]) -> Results<HistoryItem>? {
        return loadSync(predicate: HistoryItem.createFilter(uuids: uuids))
    }
}
