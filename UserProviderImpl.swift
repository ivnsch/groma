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

    private var webSocket: MyWebSocket? // arc
    
    func login(loginData: LoginData, _ handler: ProviderResult<Any> -> ()) {
        self.remoteProvider.login(loginData) {[weak self] result in
            let providerStatus = DefaultRemoteResultMapper.toProviderStatus(result.status) // status here should be always success
            if result.success {
                self?.sync {result in
                    self?.connectWebsocketIfLoggedIn()
                    handler(result)
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
                self?.sync {result in
                    self?.connectWebsocketIfLoggedIn()
                    handler(result)
                }
            } else {
                handler(ProviderResult(status: providerStatus))
            }
        }
    }
    
    func isRegistered(email: String, _ handler: ProviderResult<Any> -> ()) {
        remoteProvider.isRegistered(email) {result in
            let providerStatus = DefaultRemoteResultMapper.toProviderStatus(result.status)
            handler(ProviderResult(status: providerStatus))
        }
    }

    func logout(handler: ProviderResult<Any> -> ()) {
        self.remoteProvider.logout(remoteResultHandler(handler))
    }
    
    func sync(handler: ProviderResult<Any> -> Void) {

        Providers.listProvider.syncListsWithListItems {result in
            if result.success {
                
                Providers.inventoryProvider.syncInventoriesWithInventoryItems {result in
                    if result.success {
                        
                        Providers.historyProvider.syncHistoryItems {result in
                            if result.success {
                                Providers.listItemsProvider.invalidateMemCache()
                                Providers.inventoryItemsProvider.invalidateMemCache()
                                handler(ProviderResult(status: result.status))
                                
                            } else {
                                print("Error: could not sync history (login/register): \(result.status)")
                                handler(ProviderResult(status: result.status))
                            }
                        }
                        
                    } else {
                        print("Error: could not sync inventories (login/register): \(result.status)")
                        handler(ProviderResult(status: result.status))
                    }
                }
                
            } else {
                print("Error: could not sync lists (login/register): \(result.status)")
                handler(ProviderResult(status: result.status))
            }
        }
    }

    func connectWebsocketIfLoggedIn() {
        webSocket = MyWebSocket()
    }
    
    func disconnectWebsocket() {
        webSocket?.disconnect()
    }
    
    func forgotPassword(email: String, _ handler: ProviderResult<Any> -> ()) {
        remoteProvider.forgotPassword(email) {result in
            handler(ProviderResult(status: DefaultRemoteResultMapper.toProviderStatus(result.status)))
        }
    }
    
    func removeAccount(handler: ProviderResult<Any> -> ()) {
        remoteProvider.removeAccount {result in
            handler(ProviderResult(status: DefaultRemoteResultMapper.toProviderStatus(result.status)))
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
    
    
    // MARK: - Social login
    
    func authenticateWithFacebook(token: String, _ handler: ProviderResult<Any> -> ()) {
        self.remoteProvider.authenticateWithFacebook(token) {[weak self] result in
            let providerStatus = DefaultRemoteResultMapper.toProviderStatus(result.status) // status here should be always success
            if result.success {
                self?.sync {result in
                    handler(result)
                }   
            } else {
                handler(ProviderResult(status: providerStatus))
            }
        }
    }

    
    func authenticateWithGoogle(token: String, _ handler: ProviderResult<Any> -> ()) {
        self.remoteProvider.authenticateWithGoogle(token) {[weak self] result in
            let providerStatus = DefaultRemoteResultMapper.toProviderStatus(result.status) // status here should be always success
            if result.success {
                self?.sync {result in
                    handler(result)
                }
            } else {
                handler(ProviderResult(status: providerStatus))
            }
        }
    }
    
}
