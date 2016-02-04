//
//  GlobalProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 28/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

class GlobalProviderImpl: GlobalProvider {

    let dbProvider = RealmGlobalProvider()
    let remoteProvider = RemoteGlobalProvider()
    
    func sync(handler: ProviderResult<Any> -> Void) {
        
        dbProvider.loadGlobalSync{[weak self] syncDict in
            if let syncDict = syncDict {
                
                self?.remoteProvider.sync(syncDict) {remoteResult in
                    
                    if let syncDict = remoteResult.successResult {
                        
                        self?.dbProvider.saveSyncResult(syncDict) {saved in
                            if saved {
                                Providers.listItemsProvider.invalidateMemCache()
                                Providers.inventoryItemsProvider.invalidateMemCache()
                                handler(ProviderResult(status: .Success))
                            } else {
                                print("Error: GlobalProviderImpl.sync: saving sync result to database")
                                handler(ProviderResult(status: .Unknown))
                            }
                        }
                        
                    } else {
                        print("Warn: GlobalProviderImpl.sync: remote error, result: \(remoteResult)") // show err msg in any case (also not logged in etc) as in sync we are expected to be
//                        DefaultRemoteErrorHandler.handle(remoteResult, handler: {(result: ProviderResult<Any>) in
//                            print("Error: GlobalProviderImpl.sync: remote error, result: \(result)")
                            let providerStatus = DefaultRemoteResultMapper.toProviderStatus(remoteResult.status)
                            handler(ProviderResult(status: providerStatus))
//                        })
                    }
                }
            } else {
                print("Error: GlobalProviderImpl.sync: Couldn't load sync dictionary")
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