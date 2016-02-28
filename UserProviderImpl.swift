//
//  UserProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 26/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import FBSDKCoreKit
import FBSDKLoginKit

class UserProviderImpl: UserProvider {
   
    private let remoteProvider = RemoteUserProvider()

    private var webSocket: MyWebSocket? // arc
    
    func login(loginData: LoginData, _ handler: ProviderResult<SyncResult> -> ()) {
        self.remoteProvider.login(loginData) {[weak self] result in
            if result.success {
                self?.sync {result in
                    self?.connectWebsocketIfLoggedIn()
                    handler(result)
                }
            } else {
                DefaultRemoteErrorHandler.handle(result, handler: handler)
            }
        }
    }
    
    func register(user: UserInput, _ handler: ProviderResult<SyncResult> -> ()) {
        self.remoteProvider.register(user) {[weak self] result in
            if result.success {
                self?.sync {result in
                    self?.connectWebsocketIfLoggedIn()
                    handler(result)
                }
            } else {
                DefaultRemoteErrorHandler.handle(result, handler: handler)
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
        // TODO ensure the socket always really disconnects (client or server side), to prevent possible zombies sockets in server. It should, but maybe connection error or sth.
        webSocket?.disconnect()
        remoteProvider.logout(remoteResultHandler(handler))
        
        // Sign out of social providers in case we are logged in with them
        // Note: If we add osx support later we must move these calls to iOS-only part. The idea is to not have any iOS specific code in the providers.
        FBSDKLoginManager().logOut()
        GIDSignIn.sharedInstance().signOut()
    }
    
    func sync(handler: ProviderResult<SyncResult> -> Void) {
        Providers.globalProvider.sync {result in
            handler(result)
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
    
    func removeLoginToken() {
        remoteProvider.removeToken()
    }
    
    func ping() {
        remoteProvider.ping{result in
        }
    }
    
    var hasLoginToken: Bool {
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
    
    func authenticateWithFacebook(token: String, _ handler: ProviderResult<SyncResult> -> ()) {
        self.remoteProvider.authenticateWithFacebook(token) {[weak self] result in
            if result.success {
                self?.sync {result in
                    handler(result)
                }   
            } else {
                DefaultRemoteErrorHandler.handle(result, handler: handler)
            }
        }
    }

    
    func authenticateWithGoogle(token: String, _ handler: ProviderResult<SyncResult> -> ()) {
        self.remoteProvider.authenticateWithGoogle(token) {[weak self] result in
            if result.success {
                self?.sync {result in
                    handler(result)
                }
            } else {
                DefaultRemoteErrorHandler.handle(result, handler: handler)
            }
        }
    }
    
}
