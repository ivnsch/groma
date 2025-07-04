//
//  HistoryProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 12/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

import RealmSwift

class HistoryProviderImpl: HistoryProvider {

    let dbProvider = RealmHistoryProvider()
    let remoteProvider = RemoteHistoryProvider()

    func historyItems(_ range: NSRange, inventory: DBInventory, _ handler: @escaping (ProviderResult<Results<HistoryItem>>) -> Void) {
        dbProvider.loadHistoryItems(range, inventory: inventory) {historyItems in
            if let historyItems = historyItems {
                handler(ProviderResult(status: .success, sucessResult: historyItems))
            } else {
                logger.e("Couldn't load history items")
                handler(ProviderResult(status: .unknown))
            }
            
            // no background update - the history is too long to be fetched each time, and paginated update is too complicated
            // so we update the history only on sync (and later on push notification)
        }
    }
    
    func historyItems(_ startDate: Int64, inventory: DBInventory, _ handler: @escaping (ProviderResult<Results<HistoryItem>>) -> Void) {
        self.dbProvider.loadHistoryItems(startDate: startDate, inventory: inventory) {historyItems in
            if let historyItems = historyItems {
                handler(ProviderResult(status: .success, sucessResult: historyItems))
            } else {
                logger.e("Couldn't load history items")
                handler(ProviderResult(status: .unknown))
            }
        }
    }
    
    func historyItems(_ monthYear: MonthYear, inventory: DBInventory, _ handler: @escaping (ProviderResult<Results<HistoryItem>>) -> Void) {
        dbProvider.loadHistoryItems(monthYear, inventory: inventory) {historyItems in
            if let historyItems = historyItems {
                handler(ProviderResult(status: .success, sucessResult: historyItems))
            } else {
                logger.e("Couldn't load history items")
                handler(ProviderResult(status: .unknown))
            }
        }
    }
    
    func historyItemsGroups(_ range: NSRange, inventory: DBInventory, _ handler: @escaping (ProviderResult<[HistoryItemGroup]>) -> ()) {
        dbProvider.loadHistoryItemsGroups(range, inventory: inventory) {groups in
            handler(ProviderResult(status: .success, sucessResult: groups))
        }
    }
    
    func historyItem(_ uuid: String, handler: @escaping (ProviderResult<HistoryItem?>) -> Void) {
        dbProvider.loadHistoryItem(uuid) {historyItemMaybe in
            handler(ProviderResult(status: .success, sucessResult: historyItemMaybe))
        }
    }
    
    func removeHistoryItem(_ historyItem: HistoryItem, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        removeHistoryItem(historyItem.uuid, remote: true, handler)
    }
    
    func removeHistoryItem(_ uuid: String, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        // remote -> markForSync: if it's a call that's meant to be synced with the server, it means we want to add tombstones.
        dbProvider.removeHistoryItem(uuid, markForSync: remote) {[weak self] success in
            if success {
                handler(ProviderResult(status: .success))
                if remote {
                    self?.remoteProvider.removeHistoryItem(uuid) {result in
                        if result.success {
                            self?.dbProvider.clearHistoryItemTombstone(uuid) {removeTombstoneSuccess in
                                if !removeTombstoneSuccess {
                                    logger.e("Couldn't delete tombstone for history item: \(uuid)")
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
    
    func removeAllHistoryItems(_ handler: @escaping (ProviderResult<Any>) -> Void) {
        dbProvider.removeAllHistoryItems(true) {success in
            handler(ProviderResult(status: success ? .success : .databaseUnknown))
            
            // TODO!!!! server
        }
    }
    
    func removeHistoryItemsGroup(_ historyItemGroup: HistoryItemGroup, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        dbProvider.removeHistoryItemsGroup(historyItemGroup, markForSync: true) {success in
            if success {
                handler(ProviderResult(status: .success))
//                if remote {
//                    self?.remoteProvider.removeHistoryItems(historyItemGroup) {result in
//                        if result.success {
//                            self?.dbProvider.clearHistoryItemsTombstones(historyItemGroup) {removeTombstoneSuccess in
//                                if !removeTombstoneSuccess {
//                                    logger.e("Couldn't delete tombstones for history items: \(historyItemGroup)")
//                                }
//                            }
//                        } else {
//                            DefaultRemoteErrorHandler.handle(result, handler: handler)
//                        }
//                    }
//                }
            } else {
                logger.e("Coult not remove historyItem group: \(historyItemGroup)")
            }
        }
    }
    
    func removeHistoryItemGroupForHistoryItemLocal(_ uuid: String, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        historyItem(uuid) {[weak self] result in
            if let historyItemMaybe = result.sucessResult {
                if let historyItem = historyItemMaybe {
                    self?.dbProvider.removeHistoryItemsForGroupDate(historyItem.addedDate, inventoryUuid: historyItem.inventory.uuid) {removeSuccess in
                        if removeSuccess {
                            handler(ProviderResult(status: .success))
                        } else {
                            logger.e("Couldn't remove local history group items for iem: \(uuid)")
                            handler(ProviderResult(status: .unknown))
                        }
                    }
                } else {
                    logger.d("History item to remove group was not found: \(uuid)")
                    handler(ProviderResult(status: .success))
                }
            } else {
                logger.d("History item to remove group was not found: \(uuid) (second optional?)") // TODO does unwrapping the optional twice make sense?
                handler(ProviderResult(status: .success))
            }
        }
    }

    func addHistoryItems(_ historyItems: [HistoryItem], _ handler: @escaping (ProviderResult<Any>) -> Void) {
        dbProvider.addHistoryItems(historyItems) {success in
            handler(ProviderResult(status: success ? .success : .databaseUnknown))
        }
    }
    
    func oldestDate(_ inventory: DBInventory, handler: @escaping (ProviderResult<Date>) -> Void) {
        DBProv.historyProvider.oldestDate(inventory) {oldestDateMaybe in
            if let oldestDate = oldestDateMaybe {
                handler(ProviderResult(status: .success, sucessResult: oldestDate))
            } else {
                handler(ProviderResult(status: .notFound))
            }
        }
    }
    
    func removeHistoryItemsForMonthYear(_ monthYear: MonthYear, inventory: DBInventory, remote: Bool, handler: @escaping (ProviderResult<Any>) -> Void) {
        
        DBProv.historyProvider.removeHistoryItems(monthYear, inventory: inventory, markForSync: remote) {[weak self] removedHistoryItemsUuidsMaybe in
            
            if let removedHistoryItemsUuids = removedHistoryItemsUuidsMaybe {
                handler(ProviderResult(status: .success))
                if remote {
                    self?.remoteProvider.removeHistoryItems(removedHistoryItemsUuids) {result in
                        if result.success {
                            self?.dbProvider.clearHistoryItemsTombstones(removedHistoryItemsUuids) {removeTombstoneSuccess in
                                if !removeTombstoneSuccess {
                                    logger.e("Couldn't delete tombstones for history items: \(removedHistoryItemsUuids)")
                                }
                            }
                        } else {
                            DefaultRemoteErrorHandler.handle(result, handler: handler)
                        }
                    }
                }
            } else {
                logger.e("Coult not remove history items for month year: \(monthYear)")
            }
        }
    }
    
    // For now local only
    func removeHistoryItemsOlderThan(_ date: Date, handler: @escaping (ProviderResult<Bool>) -> Void) {
        DBProv.historyProvider.removeHistoryItemsOlderThan(date) {removedSomething in
            if let removedSomething = removedSomething {
                logger.d("Removed history items older than: \(date), removed something: \(removedSomething)")
                handler(ProviderResult(status: .success, sucessResult: removedSomething))
            } else {
                logger.e("Coult not remove history items older than: \(date)")
            }
        }
    }
    
}
