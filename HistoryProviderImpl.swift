//
//  HistoryProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 12/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

class HistoryProviderImpl: HistoryProvider {

    let dbProvider = RealmHistoryProvider()
    let remoteProvider = RemoteHistoryProvider()

    func historyItems(range: NSRange, inventory: Inventory, _ handler: ProviderResult<[HistoryItem]> -> ()) {

        self.dbProvider.loadHistoryItems(range, inventory: inventory) {dbHistoryItems in
            handler(ProviderResult(status: .Success, sucessResult: dbHistoryItems))
            
            // no background update - the history is too long to be fetched each time, and paginated update is too complicated
            // so we update the history only on sync (and later on push notification)
        }
    }
    
    func historyItems(startDate: Int64, inventory: Inventory, _ handler: ProviderResult<[HistoryItem]> -> ()) {
        self.dbProvider.loadHistoryItems(startDate: startDate, inventory: inventory) {dbHistoryItems in
            handler(ProviderResult(status: .Success, sucessResult: dbHistoryItems))
        }
    }
    
    func historyItems(monthYear: MonthYear, inventory: Inventory, _ handler: ProviderResult<[HistoryItem]> -> Void) {
        dbProvider.loadHistoryItems(monthYear, inventory: inventory) {dbHistoryItems in
            handler(ProviderResult(status: .Success, sucessResult: dbHistoryItems))
        }
    }
    
    func historyItemsGroups(range: NSRange, inventory: Inventory, _ handler: ProviderResult<[HistoryItemGroup]> -> ()) {
        dbProvider.loadHistoryItemsGroups(range, inventory: inventory) {groups in
            handler(ProviderResult(status: .Success, sucessResult: groups))
        }
    }
    
    func historyItem(uuid: String, handler: ProviderResult<HistoryItem?> -> Void) {
        dbProvider.loadHistoryItem(uuid) {historyItemMaybe in
            handler(ProviderResult(status: .Success, sucessResult: historyItemMaybe))
        }
    }
    
    func removeHistoryItem(historyItem: HistoryItem, _ handler: ProviderResult<Any> -> ()) {
        removeHistoryItem(historyItem.uuid, remote: true, handler)
    }
    
    func removeHistoryItem(uuid: String, remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        // remote -> markForSync: if it's a call that's meant to be synced with the server, it means we want to add tombstones.
        dbProvider.removeHistoryItem(uuid, markForSync: remote) {[weak self] success in
            if success {
                handler(ProviderResult(status: .Success))
                if remote {
                    self?.remoteProvider.removeHistoryItem(uuid) {result in
                        if result.success {
                            self?.dbProvider.clearHistoryItemTombstone(uuid) {removeTombstoneSuccess in
                                if !removeTombstoneSuccess {
                                    QL4("Couldn't delete tombstone for history item: \(uuid)")
                                }
                            }
                        } else {
                            DefaultRemoteErrorHandler.handle(result, handler: handler)
                        }
                    }
                }
            } else {
                print("Error: coult not remove historyItem: \(uuid)")
            }
        }
    }
    
    func removeAllHistoryItems(handler: ProviderResult<Any> -> Void) {
        dbProvider.removeAllHistoryItems(true) {success in
            handler(ProviderResult(status: success ? .Success : .DatabaseUnknown))
            
            // TODO!!!! server
        }
    }
    
    func removeHistoryItemsGroup(historyItemGroup: HistoryItemGroup, remote: Bool, _ handler: ProviderResult<Any> -> Void) {
        dbProvider.removeHistoryItemsGroup(historyItemGroup, markForSync: true) {[weak self] success in
            if success {
                handler(ProviderResult(status: .Success))
                if remote {
                    self?.remoteProvider.removeHistoryItems(historyItemGroup) {result in
                        if result.success {
                            self?.dbProvider.clearHistoryItemsTombstones(historyItemGroup) {removeTombstoneSuccess in
                                if !removeTombstoneSuccess {
                                    QL4("Couldn't delete tombstones for history items: \(historyItemGroup)")
                                }
                            }
                        } else {
                            DefaultRemoteErrorHandler.handle(result, handler: handler)
                        }
                    }
                }
            } else {
                QL4("Coult not remove historyItem group: \(historyItemGroup)")
            }
        }
    }
    
    func removeHistoryItemGroupForHistoryItemLocal(uuid: String, _ handler: ProviderResult<Any> -> Void) {
        historyItem(uuid) {[weak self] result in
            if let historyItemMaybe = result.sucessResult {
                if let historyItem = historyItemMaybe {
                    self?.dbProvider.removeHistoryItemsForGroupDate(historyItem.addedDate, inventoryUuid: historyItem.inventory.uuid) {removeSuccess in
                        if removeSuccess {
                            handler(ProviderResult(status: .Success))
                        } else {
                            QL4("Couldn't remove local history group items for iem: \(uuid)")
                            handler(ProviderResult(status: .Unknown))
                        }
                    }
                } else {
                    QL2("History item to remove group was not found: \(uuid)")
                    handler(ProviderResult(status: .Success))
                }
            } else {
                QL2("History item to remove group was not found: \(uuid) (second optional?)") // TODO does unwrapping the optional twice make sense?
                handler(ProviderResult(status: .Success))
            }
        }
    }

    func addHistoryItems(historyItems: [HistoryItem], _ handler: ProviderResult<Any> -> Void) {
        dbProvider.addHistoryItems(historyItems) {success in
            handler(ProviderResult(status: success ? .Success : .DatabaseUnknown))
        }
    }
    
    func oldestDate(inventory: Inventory, handler: ProviderResult<NSDate> -> Void) {
        DBProviders.historyProvider.oldestDate(inventory) {oldestDateMaybe in
            if let oldestDate = oldestDateMaybe {
                handler(ProviderResult(status: .Success, sucessResult: oldestDate))
            } else {
                handler(ProviderResult(status: .NotFound))
            }
        }
    }
    
    func removeHistoryItemsForMonthYear(monthYear: MonthYear, inventory: Inventory, remote: Bool, handler: ProviderResult<Any> -> Void) {
        
        DBProviders.historyProvider.removeHistoryItems(monthYear, inventory: inventory, markForSync: remote) {[weak self] removedHistoryItemsUuidsMaybe in
            
            if let removedHistoryItemsUuids = removedHistoryItemsUuidsMaybe {
                handler(ProviderResult(status: .Success))
                if remote {
                    self?.remoteProvider.removeHistoryItems(removedHistoryItemsUuids) {result in
                        if result.success {
                            self?.dbProvider.clearHistoryItemsTombstones(removedHistoryItemsUuids) {removeTombstoneSuccess in
                                if !removeTombstoneSuccess {
                                    QL4("Couldn't delete tombstones for history items: \(removedHistoryItemsUuids)")
                                }
                            }
                        } else {
                            DefaultRemoteErrorHandler.handle(result, handler: handler)
                        }
                    }
                }
            } else {
                QL4("Coult not remove history items for month year: \(monthYear)")
            }
        }
    }
    
    // For now local only
    func removeHistoryItemsOlderThan(date: NSDate, handler: ProviderResult<Bool> -> Void) {
        DBProviders.historyProvider.removeHistoryItemsOlderThan(date) {removedSomething in
            if let removedSomething = removedSomething {
                QL2("Removed history items older than: \(date), removed something: \(removedSomething)")
                handler(ProviderResult(status: .Success, sucessResult: removedSomething))
            } else {
                QL4("Coult not remove history items older than: \(date)")
            }
        }
    }
    
}