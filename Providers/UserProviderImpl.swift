//
//  UserProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 26/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

class UserProviderImpl: UserProvider {
   
    fileprivate let remoteProvider = RemoteUserProvider()

    fileprivate var webSocket: MyWebSocket? // arc
    
    func login(_ loginData: LoginData, controller: UIViewController, _ handler: @escaping (ProviderResult<SyncResult>) -> ()) {

        self.remoteProvider.login(loginData) {[weak self] result in
            if result.success {
                self?.handleLoginSuccess(loginData.email, controller: controller, handler)
            } else {
                handler(ProviderResult(status: DefaultRemoteResultMapper.toProviderStatus(result.status)))
            }
        }
    }
    
    func register(_ user: UserInput, controller: UIViewController, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        self.remoteProvider.register(user) {result in
            if result.success {
                PreferencesManager.savePreference(PreferencesManagerKey.registeredWithThisDevice, value: true)
            }
            
            // Server sends only already exists but we need register-specific status code to show specific error message
            let providerStatus = DefaultRemoteResultMapper.toProviderStatus(result.status)
            let status = providerStatus == .alreadyExists ? .userAlreadyExists : providerStatus
            
            handler(ProviderResult(status: status))
        }
    }
    
    func isRegistered(_ email: String, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        remoteProvider.isRegistered(email) {result in
            let providerStatus = DefaultRemoteResultMapper.toProviderStatus(result.status)
            handler(ProviderResult(status: providerStatus))
        }
    }

    func logout(_ handler: @escaping (ProviderResult<Any>) -> ()) {
        // TODO ensure the socket always really disconnects (client or server side), to prevent possible zombies sockets in server. It should, but maybe connection error or sth.
        webSocket?.disconnect()
        remoteProvider.logout(remoteResultHandler(handler))
        
        // Target specific logout (e.g. iOS has own FB, Google, etc. libraries). Logout can be called from core parts of library like when auth token expires, so a notification is suitable.
        Notification.send(Notification.Logout)
        
        QL2("User logged out")
    }
    
    func sync(isMatchSync: Bool, onlyOverwriteLocal: Bool, additionalActionsOnSyncSuccess: VoidFunction? = nil, handler: @escaping (ProviderResult<SyncResult>) -> Void) {
        
        let resultHandler: (ProviderResult<SyncResult>) -> Void = {result in
            if result.success {
                QL2("Sync/download success, connecting websocket...")
                _ = WebsocketHelper.tryConnectWebsocket()
                if onlyOverwriteLocal {
                    // overwrote with new device and existing account - store a flag so we don't do this again (after this device is not considered "new" anymore and does normal sync).
                    PreferencesManager.savePreference(PreferencesManagerKey.overwroteLocalDataAfterNewDeviceLogin, value: true)
                }
                additionalActionsOnSyncSuccess?()
                handler(result)
            } else {
                QL4("Sync/download didn't return success: \(result)")
                // Return a sync failed status code such that the controller can show error message specific to this. Since we return this as a result of both login and sync, if we let only the server error code client wouldn't know if e.g. "wrong parameters" would be because of login or sync. Differentiation is important because on sync errors we let the user logged in (this way they can e.g. call full download from settings to try to solve the sync problem) while on login errors the user is logged out.
                if result.status == .unknownServerCommunicationError || result.status == .serverNotReachable {
                    // If e.g. server timeout result needs to be treated differently e.g. don't show sync failed popup, logout
                    handler(ProviderResult(status: result.status, sucessResult: nil, error: result.error, errorObj: result.errorObj))
                } else {
                    handler(ProviderResult(status: .syncFailed, sucessResult: nil, error: result.error, errorObj: result.errorObj))
                }
            }
        }
        
        
        if onlyOverwriteLocal {
            Prov.globalProvider.fullDownload(resultHandler)
        } else {
            Prov.globalProvider.sync(isMatchSync, handler: resultHandler)
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
    
    func forgotPassword(_ email: String, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        remoteProvider.forgotPassword(email) {result in
            handler(ProviderResult(status: DefaultRemoteResultMapper.toProviderStatus(result.status)))
        }
    }
    
    func removeAccount(_ handler: @escaping (ProviderResult<Any>) -> ()) {
        remoteProvider.removeAccount {result in
            handler(ProviderResult(status: DefaultRemoteResultMapper.toProviderStatus(result.status)))
            
            if result.success {
                // NOTE: For now disabled as this causes further errors which are not possible to solve for the user, e.g. sync tries to upload inventory which was not removed from the server when the user deleted the account, because it had other participants. Sync will fail because duplicate inventory uuid.
                // If user removes the account and opens an account later again, we want to upload all the data to the server. So everything has to be marked as dirty again.
                // Otherwise after first sync the user will load all this data
                // Note this is only a partial fix, e.g. if user removes account in another device, it doesn't help.
                // We probably should put this after "first login after register on same device" or similar TODO think about this.
//                DBProv.globalProvider.markAllDirty {markAllDirtySuccess in
//                    if markAllDirtySuccess {
//                        QL1("Reset dirty for all objs")
//                    } else {
//                        QL4("Error in mark dirty")
//                    }
//                }
            }
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
    
    var mySharedUser: DBSharedUser? {
        if let email: String = PreferencesManager.loadPreference(PreferencesManagerKey.email) {
            return DBSharedUser(email: email)
        } else {
            return nil
        }
    }
    
    func findAllKnownSharedUsers(_ handler: @escaping (ProviderResult<[DBSharedUser]>) -> Void) {
        // TODO no more custom server
        QL3("Not supported")
        handler(ProviderResult(status: .success, sucessResult: []))
//        remoteProvider.findAllKnownSharedUsers {result in
//            if let remoteSharedUsers = result.successResult {
//                let sharedUsers = remoteSharedUsers.map{SharedUser(email: $0.email)}
//                
//                let sharedUsersWithoutMe: [SharedUser] = {
//                    if let me = Prov.userProvider.mySharedUser {
//                        return sharedUsers.filter{$0.email != me.email}
//                    } else {
//                        QL4("Invalid state - requesting shared users (we expect the user to be logged in for this), but own user is not stored")
//                        return sharedUsers // this shouldn't happen, but in case we just return the list unfiltered
//                    }
//                }()
//                
//                handler(ProviderResult(status: .success, sucessResult: sharedUsersWithoutMe))
//            } else {
//                handler(ProviderResult(status: DefaultRemoteResultMapper.toProviderStatus(result.status)))
//            }
//        }
    }
    
    
    // If we have login success with a different user than the one that is currently stored in the device, clear local db before doing sync. Otherwise we will upload the data from the old user to the account of the new one (which even if we wanted doesn't work because the uuids have to be unique).
    fileprivate func wrapCheckDifferentUser(_ loggedInUserEmail: String, controller: UIViewController, handler: @escaping (ProviderResult<Any>) -> Void) {
        
        let loggingInWithADifferentUser = isDifferentUser(loggedInUserEmail)
        
        if loggingInWithADifferentUser {
            
            let previousEmail = Prov.userProvider.mySharedUser?.email ?? ""

            QL2("Logging in with different user, new email: \(loggedInUserEmail), previous email: \(previousEmail)")
            
            ConfirmationPopup.show(title: "Warning", message: "You're logging in with a new account on this device. If you continue, all the not synced data on this device will be lost permanently. Do you want to continue?\nYour previous account id: \(previousEmail)", okTitle: "Yes", cancelTitle: "Cancel", controller: controller, onOk: {
                
                    Prov.globalProvider.clearAllData(false) {result in
                        if !result.success {
                            QL4("Error clearing data of different user: \(loggedInUserEmail), result: \(result)")
                        }
                        handler(result)
                    }
                
                }, onCancel: {[weak self] in
                    QL2("Different user and cancelled clear local data, logging out")
                    self?.logout {logoutResult in
                        if !logoutResult.success {
                            QL4("Logout failed: \(logoutResult)")
                        }
                        handler(ProviderResult(status: .cancelledLoginWithDifferentAccount))
                    }
            })
            
        } else {
            handler(ProviderResult(status: .success))
        }
    }
    
    
    fileprivate func handleLoginSuccess(_ userEmail: String, controller: UIViewController, _ handler: @escaping (ProviderResult<SyncResult>) -> ()) {
        
        // If a user logs in the first time on a device but account exists already, we don't want to do a full sync because this would upload all the prefilled products (which have different uuids) and user would end with a duplicate (name suffix (n)) for each product.
        // So we remember if the user registered using this device, if not it means they are loggin in with a new device. If the user logs in with a new device we only overwrite the local database, meaning we send a sync with no payload.
        // We also remember if we overwrote already - this is only for the first login! After this the user of course has to sync normally.
        let registeredWithThisDevice = PreferencesManager.loadPreference(PreferencesManagerKey.registeredWithThisDevice) ?? false
        let overwroteLocalDataAfterNewDeviceLogin = PreferencesManager.loadPreference(PreferencesManagerKey.overwroteLocalDataAfterNewDeviceLogin) ?? false
        
        if !registeredWithThisDevice && !overwroteLocalDataAfterNewDeviceLogin {
            ConfirmationPopup.show(title: "New installation", message: "Your local data will be overwritten with the data stored in your account", okTitle: "Continue", cancelTitle: "Cancel", controller: controller, onOk: {[weak self] in
                
                
                self?.wrapCheckDifferentUser(userEmail, controller: controller) {result in
                    if result.success {
                        self?.storeEmail(userEmail)
                        
                        self?.sync(isMatchSync: false, onlyOverwriteLocal: true, additionalActionsOnSyncSuccess: {
                            PreferencesManager.savePreference(PreferencesManagerKey.registeredWithThisDevice, value: true)
                            }, handler: handler)
                    } else {
                        handler(ProviderResult(status: result.status, sucessResult: nil, error: result.error, errorObj: result.errorObj))
                    }
                }
                
            }, onCancel: {[weak self] in
                // If user declines to overwrite local data we do nothing and log the user out.
                QL1("Declined overwrite sync, logging out")
                self?.logout {logoutResult in
                    if !logoutResult.success {
                        QL4("Logout failed: \(logoutResult)")
                    }
                    handler(ProviderResult(status: .isNewDeviceLoginAndDeclinedOverwrite))
                }
                
            }, onCannotPresent: {[weak self] in // this can happen if we are showing another popup already on same controller - an example in this case is when we show the optional app update dialog, which also uses root controller. It's always presented before of this, so when we are here, it will not show anything. For now we do the same as if user cancelled - log out, this isn't perfect but is the only meaningful thing we can do here. Note it is important to return something! Otherwise we get e.g. not dismissed progress indicator. This situation (with the update dialog, the only where it has happened so far) can happen but is rare, it means that: 1. User has an outdated installation on a device, 2. User opened an account with other device, 3. User logs in with the outdated device - here we get 'new device' and 'should update app' popup at the same time. At least for this case logging out is ok, user just has to login again after cancelling the update (if they update the app everything is gone anyway) and then the new installation popup appears.
                QL3("Couldn't present confirm new device popup, logging out")
                self?.logout {logoutResult in
                    if !logoutResult.success {
                        QL4("Logout failed: \(logoutResult)")
                    }
                    handler(ProviderResult(status: .isNewDeviceLoginAndDeclinedOverwrite))
                }
            })
            
        } else { // normal login/sync
            wrapCheckDifferentUser(userEmail, controller: controller) {[weak self] result in
                if result.success {
                    self?.storeEmail(userEmail)
                    
                    self?.sync(isMatchSync: false, onlyOverwriteLocal: false, handler: handler)
                } else {
                    handler(ProviderResult(status: result.status, sucessResult: nil, error: result.error, errorObj: result.errorObj))
                }
            }
        }
    }
    
    func isDifferentUser(_ email: String) -> Bool {
        return mySharedUser.map{$0.email != email} ?? false
    }
    
    // MARK: - Social login
    
    fileprivate func handleSocialSignUpResult(_ controller: UIViewController, result: RemoteResult<RemoteSocialLoginResult>, handler: @escaping (ProviderResult<SyncResult>) -> Void) {
        if let authResult = result.successResult {
            if authResult.isRegister {
                // If register, send a normal sync. This is equivalent with a login with the credentials provider as the user is verified already and don't need to confirm. Except that here we know it's register, so we can just send a plain sync - without checks for possible accounts on other device.
                // We of course also clear data from a possible previous user on this device first.
                wrapCheckDifferentUser(authResult.email, controller: controller) {[weak self] result in
                    if result.success {
                        self?.storeEmail(authResult.email)
                        self?.sync(isMatchSync: false, onlyOverwriteLocal: false, handler: handler)
                    } else {
                        handler(ProviderResult(status: result.status, sucessResult: nil, error: result.error, errorObj: result.errorObj))
                    }
                }
                
            } else {
                handleLoginSuccess(authResult.email, controller: controller, handler)
            }
        } else {
            handler(ProviderResult(status: DefaultRemoteResultMapper.toProviderStatus(result.status)))
        }
    }
    
    // TODO!!!! don't use default error handler here, if no connection etc we have to show an alert not ignore
    func authenticateWithFacebook(_ token: String, controller: UIViewController, _ handler: @escaping (ProviderResult<SyncResult>) -> ()) {
        remoteProvider.authenticateWithFacebook(token) {[weak self] result in
            self?.handleSocialSignUpResult(controller, result: result, handler: handler)
        }
    }

    // TODO!!!! don't use default error handler here, if no connection etc we have to show an alert not ignore
    func authenticateWithGoogle(_ token: String, controller: UIViewController, _ handler: @escaping (ProviderResult<SyncResult>) -> ()) {
        remoteProvider.authenticateWithGoogle(token) {[weak self] result in
            self?.handleSocialSignUpResult(controller, result: result, handler: handler)
        }
    }

    
    func authenticateWithICloud(controller: UIViewController, _ handler: @escaping (ProviderResult<SyncResult>) -> Void) {
        QL4("Not supported")
        handler(ProviderResult(status: .unknown))
    }
    
    // store email in prefs so we can e.g. prefill login controller, which is opened after registration
    // For now store it as simple preference, we need it to be added automatically to list shared users. This may change in the future
    fileprivate func storeEmail(_ email: String) {
        PreferencesManager.savePreference(PreferencesManagerKey.email, value: NSString(string: email))
    }
}
