//
//  UserProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 26/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

class UserProviderImpl: UserProvider {
   
    private let remoteProvider = RemoteUserProvider()

    // arc
    private let listsProvider = ProviderFactory().listProvider
    private let inventoryProvider = ProviderFactory().inventoryProvider
    private let historyProvider = ProviderFactory().historyProvider
    
    func login(loginData: LoginData, _ handler: ProviderResult<Any> -> ()) {
        self.remoteProvider.login(loginData) {[weak self] result in
            let providerStatus = DefaultRemoteResultMapper.toProviderStatus(result.status) // status here should be always success
            if result.success {
                self?.sync {
                    handler(ProviderResult(status: providerStatus))
                }
            } else {
                handler(ProviderResult(status: providerStatus))
            }
        }
    }
    
    func register(user: UserInput, _ handler: ProviderResult<Any> -> ()) {
        self.remoteProvider.register(user) {[weak self] result in
            let providerStatus = DefaultRemoteResultMapper.toProviderStatus(result.status) // status here should be always success
            if result.success {
                self?.sync {
                    handler(ProviderResult(status: providerStatus))
                }
            } else {
                handler(ProviderResult(status: providerStatus))
            }
        }
    }
    
    func logout(handler: ProviderResult<Any> -> ()) {
        self.remoteProvider.logout(remoteResultHandler(handler))
    }
    
    private func sync(handler: () -> ()) {

        listsProvider.syncListsWithListItems {[weak self] result in
            if result.success {
                self!.inventoryProvider.syncInventoriesWithInventoryItems {[weak self] result in
                    if result.success {
                        self!.historyProvider.syncHistoryItems {result in
                            handler()
                        }
                        
                    } else {
                        print("Error: could not sync inventories (login/register): \(result.status)")
                        handler()
                    }
                }
                
            } else {
                print("Error: could not sync lists (login/register): \(result.status)")
                handler()
            }
        }
    }
    
    var loggedIn: Bool {
        return remoteProvider.hasToken()
    }
    
    var mySharedUser: SharedUser? {
        if let email: String = PreferencesManager.loadPreference(PreferencesManagerKey.email) {
            return SharedUser(email: email)
        } else {
            return nil
        }
    }
}
