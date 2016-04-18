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
import QorumLogs

class UserProviderImpl: UserProvider {
   
    private let remoteProvider = RemoteUserProvider()

    private var webSocket: MyWebSocket? // arc
    
    func login(loginData: LoginData, _ handler: ProviderResult<SyncResult> -> ()) {
        self.remoteProvider.login(loginData) {[weak self] result in
            if result.success {
                self?.sync(false) {result in
                    if result.success {
                        QL2("Sync success, connecting websocket...")
                        self?.connectWebsocketIfLoggedIn()
                    } else {
                        QL4("Sync didn't return success: \(result)")
                    }
                    handler(result)
                }
            } else {
                handler(ProviderResult(status: DefaultRemoteResultMapper.toProviderStatus(result.status)))
            }
        }
    }
    
    func register(user: UserInput, _ handler: ProviderResult<Any> -> ()) {
        self.remoteProvider.register(user) {result in
            handler(ProviderResult(status: DefaultRemoteResultMapper.toProviderStatus(result.status)))
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
        GIDSignIn.sharedInstance().disconnect()
        
        QL2("User logged out")
    }
    
    func sync(isMatchSync: Bool, handler: ProviderResult<SyncResult> -> Void) {
        Providers.globalProvider.sync(isMatchSync) {result in
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
        AccessTokenHelper.removeToken()
    }
    
    func ping() {
        remoteProvider.ping{result in
        }
    }
    
    var hasLoginToken: Bool {
        return AccessTokenHelper.hasToken()
    }
    
    var hasSignedInOnce: Bool {
        return mySharedUser != nil
    }
    
    var mySharedUser: SharedUser? {
        if let email: String = PreferencesManager.loadPreference(PreferencesManagerKey.email) {
            return SharedUser(email: email)
        } else {
            return nil
        }
    }
    
    func findAllKnownSharedUsers(handler: ProviderResult<[SharedUser]> -> Void) {
        remoteProvider.findAllKnownSharedUsers {result in
            if let remoteSharedUsers = result.successResult {
                let sharedUsers = remoteSharedUsers.map{SharedUser(email: $0.email)}
                
                let sharedUsersWithoutMe: [SharedUser] = {
                    if let me = Providers.userProvider.mySharedUser {
                        return sharedUsers.filter{$0.email != me.email}
                    } else {
                        QL4("Invalid state - requesting shared users (we expect the user to be logged in for this), but own user is not stored")
                        return sharedUsers // this shouldn't happen, but in case we just return the list unfiltered
                    }
                }()
                
                handler(ProviderResult(status: .Success, sucessResult: sharedUsersWithoutMe))
            } else {
                handler(ProviderResult(status: DefaultRemoteResultMapper.toProviderStatus(result.status)))
            }
        }
    }
    
    // MARK: - Social login
    
    // TODO!!!! don't use default error handler here, if no connection etc we have to show an alert not ignore
    func authenticateWithFacebook(token: String, _ handler: ProviderResult<SyncResult> -> ()) {
        self.remoteProvider.authenticateWithFacebook(token) {[weak self] result in
            if result.success {
                self?.sync(false) {result in
                    handler(result)
                }   
            } else {
                handler(ProviderResult(status: DefaultRemoteResultMapper.toProviderStatus(result.status)))
            }
        }
    }

    // TODO!!!! don't use default error handler here, if no connection etc we have to show an alert not ignore
    func authenticateWithGoogle(token: String, _ handler: ProviderResult<SyncResult> -> ()) {
        self.remoteProvider.authenticateWithGoogle(token) {[weak self] result in
            if result.success {
                self?.sync(false) {result in
                    handler(result)
                }
            } else {
                handler(ProviderResult(status: DefaultRemoteResultMapper.toProviderStatus(result.status)))
            }
        }
    }
    
}
