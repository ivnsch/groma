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
        self.dbProvider.loadHistoryItems {dbHistoryItems in
            handler(ProviderResult(status: .Success, sucessResult: dbHistoryItems))
            
            self.remoteProvider.historyItems {result in
                if let remoteHistoryItems = result.successResult {
                    let historyItemsWithRelations: HistoryItemsWithRelations = HistoryItemMapper.historyItemsWithRemote(remoteHistoryItems)
                    
                    // if there's no cached list or there's a difference, overwrite the cached list
                    if dbHistoryItems != historyItemsWithRelations.historyItems {
                        
                        self.dbProvider.saveHistoryItems(historyItemsWithRelations) {saved in
                            handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: historyItemsWithRelations.historyItems))
                        }
                    }
                } else {
                    print("Error: history items background request didn't work: \(result.status)")
                }
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