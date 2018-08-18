//
//  RealmHistoryProvider.swift
//  shoppin
//
//  Created by ischuetz on 12/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

// TODo async wrappers don't need to extend RealmProvider. Remove this after removing tombstone code
class RealmHistoryProvider: RealmProvider {

    fileprivate let syncProvider = RealmHistoryProviderSync()

    func add(_ historyItem: HistoryItem, handler: @escaping (Bool) -> Void) {
        handler(syncProvider.add(historyItem: historyItem))
    }

    func loadHistoryItems(_ range: NSRange? = nil, inventory: DBInventory, handler: @escaping (Results<HistoryItem>?) -> Void) {
        handler(syncProvider.loadHistoryItems(range, inventory: inventory))
    }

    func loadHistoryItems(_ range: NSRange? = nil, startDate: Int64, inventory: DBInventory, handler: @escaping (Results<HistoryItem>?) -> ()) {
        handler(syncProvider.loadHistoryItems(range, startDate: startDate, inventory: inventory))
    }

    func loadHistoryItems(_ productName: String, startDate: Int64, inventory: DBInventory, handler: @escaping (Results<HistoryItem>?) -> ()) {
        handler(syncProvider.loadHistoryItems(productName, startDate: startDate, inventory: inventory))
    }

    func loadAllHistoryItems(_ handler: @escaping (Results<HistoryItem>?) -> Void) {
        handler(syncProvider.loadAllHistoryItems())
    }

    func loadHistoryItems(_ monthYear: MonthYear, inventory: DBInventory, handler: @escaping (Results<HistoryItem>?) -> Void) {
        handler(syncProvider.loadHistoryItems(monthYear, inventory: inventory))
    }

    func loadHistoryItems(_ startDate: Int64, endDate: Int64, inventory: DBInventory, _ handler: @escaping (Results<HistoryItem>?) -> Void) {
        handler(syncProvider.loadHistoryItems(startDate, endDate: endDate, inventory: inventory))
    }

    func loadHistoryItemsGroups(_ range: NSRange, inventory: DBInventory, _ handler: @escaping ([HistoryItemGroup]) -> ()) {
        DispatchQueue.main.async(execute: {
            handler(self.syncProvider.loadHistoryItemsGroups(range, inventory: inventory))
        })
    }

    func loadHistoryItem(_ uuid: String, handler: @escaping (HistoryItem?) -> Void) {
        handler(syncProvider.loadHistoryItem(uuid))
    }

    func removeHistoryItemsForGroupDate(_ date: Int64, inventoryUuid: String, handler: @escaping (Bool) -> Void) {
        handler(syncProvider.removeHistoryItemsForGroupDate(date, inventoryUuid: inventoryUuid))
    }

    func removeHistoryItem(_ uuid: String, markForSync: Bool, handler: @escaping (Bool) -> Void) {
        handler(syncProvider.removeHistoryItem(uuid, markForSync: markForSync))
    }

    // Expected to be executed in do/catch and write block
    func removeHistoryItemsForInventory(_ realm: Realm, inventoryUuid: String, markForSync: Bool) -> Bool {
        return syncProvider.removeHistoryItemsForInventory(realm, inventoryUuid: inventoryUuid, markForSync: markForSync)
    }

    func removeHistoryItems(_ monthYear: MonthYear, inventory: DBInventory, markForSync: Bool, handler: @escaping ([String]?) -> Void) {
        DispatchQueue.main.async(execute: {
            handler(self.syncProvider.removeHistoryItems(monthYear, inventory: inventory, markForSync: markForSync))
        })
    }

    // Returns nil if error, true if found and removed something, false if there was nothing to remove
    func removeHistoryItemsOlderThan(_ date: Date, handler: @escaping (Bool?) -> Void) {
        DispatchQueue.main.async(execute: {
            handler(self.syncProvider.removeHistoryItemsOlderThan(date))
        })
    }

    func oldestDate(_ inventory: DBInventory, handler: @escaping (Date?) -> Void) {
        DispatchQueue.main.async(execute: {
            handler(self.syncProvider.oldestDate(inventory))
        })
    }

    // TODO!! optimise this, instead of adding everything to the tombstone table and send on sync maybe just store somewhere a flag and send it on sync, which instructs the server to delete all the history.
    func removeAllHistoryItems(_ markForSync: Bool, handler: @escaping (Bool) -> ()) {
        DispatchQueue.main.async(execute: {
            handler(self.syncProvider.removeAllHistoryItems(markForSync))
        })
    }

    func removeHistoryItemsGroup(_ historyItemGroup: HistoryItemGroup, markForSync: Bool, _ handler: @escaping (Bool) -> Void) {
        DispatchQueue.main.async(execute: {
            handler(self.syncProvider.removeHistoryItemsGroup(historyItemGroup, markForSync: markForSync))
        })
    }

    func addHistoryItems(_ historyItems: [HistoryItem], handler: @escaping (Bool) -> Void) {
        DispatchQueue.main.async(execute: {
            handler(self.syncProvider.addHistoryItems(historyItems))
        })
    }
    
    func loadHistoryItemSync(uuid: String) -> HistoryItem? {
        return syncProvider.loadHistoryItem(uuid)
    }
    
    func loadHistoryItemsSync(uuids: [String]) -> Results<HistoryItem>? {
        return syncProvider.loadHistoryItems(uuids:uuids)
    }

    // MARK: - Tombstones - not used - TODO remove? - if not at least move to sync provider

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
}
