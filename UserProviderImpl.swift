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
    
    func login(loginData: LoginData, controller: UIViewController, _ handler: ProviderResult<SyncResult> -> ()) {

        self.remoteProvider.login(loginData) {[weak self] result in
            if result.success {
                self?.handleLoginSuccess(controller, handler)
            } else {
                handler(ProviderResult(status: DefaultRemoteResultMapper.toProviderStatus(result.status)))
            }
        }
    }
    
    func register(user: UserInput, _ handler: ProviderResult<Any> -> ()) {
        self.remoteProvider.register(user) {result in
            if result.success {
                PreferencesManager.savePreference(PreferencesManagerKey.registeredWithThisDevice, value: true)
            }
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
    
    func sync(isMatchSync isMatchSync: Bool, onlyOverwriteLocal: Bool, additionalActionsOnSyncSuccess: VoidFunction? = nil, handler: ProviderResult<SyncResult> -> Void) {
        
        let resultHandler: ProviderResult<SyncResult> -> Void = {result in
            if result.success {
                QL2("Sync success, connecting websocket...")
                WebsocketHelper.tryConnectWebsocket()
                if onlyOverwriteLocal {
                    // overwrote with new device and existing account - store a flag so we don't do this again (after this device is not considered "new" anymore and does normal sync).
                    PreferencesManager.savePreference(PreferencesManagerKey.overwroteLocalDataAfterNewDeviceLogin, value: true)
                }
                additionalActionsOnSyncSuccess?()
                handler(result)
            } else {
                QL4("Sync didn't return success: \(result)")
                // Return a sync failed status code such that the controller can show error message specific to this. Since we return this as a result of both login and sync, if we let only the server error code client wouldn't know if e.g. "wrong parameters" would be because of login or sync. Differentiation is important because on sync errors we let the user logged in (this way they can e.g. call full download from settings to try to solve the sync problem) while on login errors the user is logged out.
                handler(ProviderResult(status: .SyncFailed, sucessResult: nil, error: result.error, errorObj: result.errorObj))
            }
        }
        
        
        if onlyOverwriteLocal {
            Providers.globalProvider.fullDownload(resultHandler)
        } else {
            Providers.globalProvider.sync(isMatchSync, handler: resultHandler)
        }
    }

    func connectWebsocketIfLoggedIn() {
        webSocket = MyWebSocket()
    }
    
    func disconnectWebsocket() {
        webSocket?.disconnect()
    }
    
    func isWebsocketConnected() -> Bool {
        return webSocket?.isConnected ?? false
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
    
    private func handleLoginSuccess(controller: UIViewController, _ handler: ProviderResult<SyncResult> -> ()) {
        
        // If a user logs in the first time on a device but account exists already, we don't want to do a full sync because this would upload all the prefilled products (which have different uuids) and user would end with a duplicate (name suffix (n)) for each product.
        // So we remember if the user registered using this device, if not it means they are loggin in with a new device. If the user logs in with a new device we only overwrite the local database, meaning we send a sync with no payload.
        // We also remember if we overwrote already - this is only for the first login! After this the user of course has to sync normally.
        let registeredWithThisDevice = PreferencesManager.loadPreference(PreferencesManagerKey.registeredWithThisDevice) ?? false
        let overwroteLocalDataAfterNewDeviceLogin = PreferencesManager.loadPreference(PreferencesManagerKey.overwroteLocalDataAfterNewDeviceLogin) ?? false
        
        if !registeredWithThisDevice && !overwroteLocalDataAfterNewDeviceLogin {
            ConfirmationPopup.show(title: "New installation", message: "Your local data will be overwritten with the data stored in your account", okTitle: "Continue", cancelTitle: "Cancel", controller: controller, onOk: {[weak self] in
                
                self?.sync(isMatchSync: false, onlyOverwriteLocal: true, additionalActionsOnSyncSuccess: {
                    PreferencesManager.savePreference(PreferencesManagerKey.registeredWithThisDevice, value: true)
                }, handler: handler)
                
                }, onCancel: {[weak self] in
                    // If user declines to overwrite local data we do nothing and log the user out.
                    QL1("Declined overwrite sync, logging out")
                    self?.logout {logoutResult in
                        QL2("Declined overwrite sync, logged out. Logout result: \(logoutResult)")
                        handler(ProviderResult(status: .IsNewDeviceLoginAndDeclinedOverwrite))
                    }
                })
            
        } else { // normal login/sync
            sync(isMatchSync: false, onlyOverwriteLocal: false, handler: handler)
        }
    }
    
    // MARK: - Social login
    
    // TODO!!!! don't use default error handler here, if no connection etc we have to show an alert not ignore
    func authenticateWithFacebook(token: String, controller: UIViewController, _ handler: ProviderResult<SyncResult> -> ()) {
        self.remoteProvider.authenticateWithFacebook(token) {[weak self] result in
            if let authResult = result.successResult {
                if authResult.isRegister {
                    self?.sync(isMatchSync: false, onlyOverwriteLocal: false, handler: handler)
                } else {
                    self?.handleLoginSuccess(controller, handler)
                }
            } else {
                handler(ProviderResult(status: DefaultRemoteResultMapper.toProviderStatus(result.status)))
            }
        }
    }

    // TODO!!!! don't use default error handler here, if no connection etc we have to show an alert not ignore
    func authenticateWithGoogle(token: String, controller: UIViewController, _ handler: ProviderResult<SyncResult> -> ()) {
        self.remoteProvider.authenticateWithGoogle(token) {[weak self] result in
            if let authResult = result.successResult {
                if authResult.isRegister {
                    self?.sync(isMatchSync: false, onlyOverwriteLocal: false, handler: handler)
                } else {
                    self?.handleLoginSuccess(controller, handler)
                }
            } else {
                handler(ProviderResult(status: DefaultRemoteResultMapper.toProviderStatus(result.status)))
            }
        }
    }
}
