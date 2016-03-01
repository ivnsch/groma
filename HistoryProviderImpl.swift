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
    
    func historyItems(startDate: NSDate, inventory: Inventory, _ handler: ProviderResult<[HistoryItem]> -> ()) {
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
    
    func removeHistoryItem(historyItem: HistoryItem, _ handler: ProviderResult<Any> -> ()) {
        removeHistoryItem(historyItem.uuid, remote: true, handler)
    }
    
    func removeHistoryItem(uuid: String, remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        dbProvider.removeHistoryItem(uuid) {[weak self] success in
            if success {
                if remote {
                    self?.remoteProvider.removeHistoryItem(uuid) {result in
                        if result.success {
                            self?.dbProvider.clearHistoryItemTombstone(uuid) {removeTombstoneSuccess in
                                if !removeTombstoneSuccess {
                                    QL4("Couldn't delete tombstone for history item: \(uuid)")
                                }
                            }
                        } else {
                            let providerStatus = DefaultRemoteResultMapper.toProviderStatus(result.status)
                            handler(ProviderResult(status: providerStatus))
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
    
    // TODO after implement groups in separate table
    func removeHistoryItemsGroup(historyItemGroup: HistoryItemGroup, _ handler: ProviderResult<Any> -> ()) {
        print("TODO: remove history item group")
    }
    
    func addHistoryItems(historyItems: [HistoryItem], _ handler: ProviderResult<Any> -> Void) {
        dbProvider.addHistoryItems(historyItems) {success in
            handler(ProviderResult(status: success ? .Success : .DatabaseUnknown))
        }
    }
}