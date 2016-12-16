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
    
    func sync(_ isMatchSync: Bool, handler: @escaping (ProviderResult<SyncResult>) -> Void) {
        
        dbProvider.loadGlobalSync(isMatchSync) {[weak self] syncDict in
            if let syncDict = syncDict {
                
                self?.remoteProvider.sync(syncDict) {remoteResult in
                    self?.handleSyncResult(remoteResult, handler: handler)
                }
            } else {
                QL4("Couldn't load sync dictionary")
            }
        }
    }
    
    fileprivate func handleSyncResult(_ syncResult: RemoteResult<RemoteSyncResult>, handler: @escaping (ProviderResult<SyncResult>) -> Void) {
        if let syncDict = syncResult.successResult {
            
            dbProvider.saveSyncResult(syncDict) {saved in
                if saved {
                    Prov.listItemsProvider.invalidateMemCache()
                    Prov.inventoryItemsProvider.invalidateMemCache()
                    if let remoteSyncResult = syncResult.successResult {
                        let syncResult = SyncResult(listInvites: remoteSyncResult.listInvitations, inventoryInvites: remoteSyncResult.inventoryInvitations)
                        handler(ProviderResult(status: .success, sucessResult: syncResult))
                    } else {
                        QL4("Invalid state, remote result should have a successResult")
                        handler(ProviderResult(status: .unknown))
                    }
                    
                } else {
                    QL4("Coudln't save sync result to database")
                    handler(ProviderResult(status: .unknown))
                }
            }
            
        } else {
            QL3("Remote error doing sync, result: \(syncResult)")
            // show err msg in any case (also not logged in etc) as in sync we are expected to be connected
            handler(ProviderResult(status: DefaultRemoteResultMapper.toProviderStatus(syncResult.status)))
        }
    }
    
    func clearAllData(_ remote: Bool, handler: @escaping (ProviderResult<Any>) -> Void) {
        dbProvider.clearAllData {success in
            handler(ProviderResult(status: success ? .success : .databaseUnknown))
            
            // TODO!!!! server
        }
    }
    
    func fullDownload(_ handler: @escaping (ProviderResult<SyncResult>) -> Void) {
        remoteProvider.fullDownload() {[weak self] remoteResult in
            // Full download result handling is the same as sync - full overwrite of local db. Note that the caller decides what to do with the possible invitations - show, ignore, etc.
            self?.handleSyncResult(remoteResult, handler: handler)
        }
    }
}
