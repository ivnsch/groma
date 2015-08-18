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

    // Note that when we have push notifications sync we will not need this
    func historyItems(handler: ProviderResult<[HistoryItem]> -> ()) {
        self.dbProvider.loadHistoryItems {historyItems in
            handler(ProviderResult(status: .Success, sucessResult: historyItems))
        }
        
        self.remoteProvider.historyItems {result in
            if let historyItems = result.successResult {
                self.dbProvider.saveHistoryItems(historyItems) {saved in
                    if !saved {
                        print("Error: local database couldn't save history items fetched in background request")
                    }
                }
            } else {
                print("Error: history items background request didn't work: \(result.status)")
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