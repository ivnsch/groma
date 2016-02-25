//
//  GlobalProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 28/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

class GlobalProviderImpl: GlobalProvider {

    let dbProvider = RealmGlobalProvider()
    let remoteProvider = RemoteGlobalProvider()
    
    func sync(handler: ProviderResult<SyncResult> -> Void) {
        
        dbProvider.loadGlobalSync{[weak self] syncDict in
            if let syncDict = syncDict {
                
                self?.remoteProvider.sync(syncDict) {remoteResult in
                    
                    if let syncDict = remoteResult.successResult {
                        
                        self?.dbProvider.saveSyncResult(syncDict) {saved in
                            if saved {
                                Providers.listItemsProvider.invalidateMemCache()
                                Providers.inventoryItemsProvider.invalidateMemCache()
                                if let remoteSyncResult = remoteResult.successResult {
                                    let syncResult = SyncResult(listInvites: remoteSyncResult.listInvitations)
                                    handler(ProviderResult(status: .Success, sucessResult: syncResult))
                                } else {
                                    QL4("Invalid state, remote result should have a successResult")
                                    handler(ProviderResult(status: .Unknown))
                                }
                                
                            } else {
                                QL4("Coudln't save sync result to database")
                                handler(ProviderResult(status: .Unknown))
                            }
                        }
                        
                    } else {
                        QL3("Remote error, result: \(remoteResult)") // show err msg in any case (also not logged in etc) as in sync we are expected to be
//                        DefaultRemoteErrorHandler.handle(remoteResult, handler: {(result: ProviderResult<Any>) in
//                            print("Error: GlobalProviderImpl.sync: remote error, result: \(result)")
                            let providerStatus = DefaultRemoteResultMapper.toProviderStatus(remoteResult.status)
                            handler(ProviderResult(status: providerStatus))
//                        })
                    }
                }
            } else {
                QL4("Couldn't load sync dictionary")
            }
        }
    }
    
    func clearAllData(handler: ProviderResult<Any> -> Void) {
        dbProvider.clearAllData {success in
            handler(ProviderResult(status: success ? .Success : .DatabaseUnknown))
            
            // TODO!!!! server
        }
    }
}