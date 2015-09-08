//
//  HistoryProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 12/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class HistoryProviderImpl: HistoryProvider {

    let dbProvider = RealmHistoryProvider()
    let remoteProvider = RemoteHistoryProvider()

    func historyItems(range: NSRange, _ handler: ProviderResult<[HistoryItem]> -> ()) {

        self.dbProvider.loadHistoryItems(range) {dbHistoryItems in
            handler(ProviderResult(status: .Success, sucessResult: dbHistoryItems))
            
            // no background update - the history is too long to be fetched each time, and paginated update is too complicated
            // so we update the history only on sync (and later on push notification)
        }
    }
    
    func removeHistoryItem(historyItem: HistoryItem, _ handler: ProviderResult<Any> -> ()) {
        dbProvider.removeHistoryItem(historyItem) {[weak self] success in
            if success {
                self?.remoteProvider.removeHistoryItem(historyItem) {result in
                    let providerStatus = DefaultRemoteResultMapper.toProviderStatus(result.status)
                    handler(ProviderResult(status: providerStatus))
                }
            } else {
                print("Error: coult not remove historyItem: \(historyItem)")
            }
        }
    }
    
    func syncHistoryItems(handler: (ProviderResult<[Any]> -> ())) {
        
        self.dbProvider.loadHistoryItems {dbHistoryItems in
            
            let historyItemsSync: HistoryItemsSync = SyncUtils.toHistoryItemsSync(dbHistoryItems)
            
            self.remoteProvider.syncHistoryItems(historyItemsSync) {remoteResult in
                
                if let syncResult = remoteResult.successResult, items = syncResult.items.first {
                    
                    self.dbProvider.saveHistoryItemsSyncResult(items) {success in
                        if success {
                            handler(ProviderResult(status: .Success))
                        } else {
                            handler(ProviderResult(status: .DatabaseSavingError))
                        }
                    }
                    
                } else {
                    let providerStatus = DefaultRemoteResultMapper.toProviderStatus(remoteResult.status)
                    handler(ProviderResult(status: providerStatus))
                }
            }
        }
    }
}