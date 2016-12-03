//
//  RealmUserProviderImpl.swift
//  shoppin
//
//  Created by Ivan Schütz on 01/12/2016.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift
import QorumLogs
import FBSDKCoreKit
import FBSDKLoginKit

class RealmUserProviderImpl: UserProvider {

    fileprivate var notificationToken: NotificationToken?

    func login(_ loginData: LoginData, controller: UIViewController, _ handler: @escaping (ProviderResult<SyncResult>) -> ()) {
        loginOrRegister(loginData, register: false, controller: controller, handler)
    }

    
    func register(_ user: UserInput, controller: UIViewController, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        let loginData = LoginData(email: user.email, password: user.password)
        loginOrRegister(loginData, register: true, controller: controller) {result in
            handler(ProviderResult(status: result.status))
        }
    }
    
    
    private func loginOrRegister(_ loginData: LoginData, register: Bool, controller: UIViewController, _ handler: @escaping (ProviderResult<SyncResult>) -> Void) {
        let credentials = SyncCredentials.usernamePassword(username: loginData.email, password: loginData.password, register: register)
        loginOrRegister(credentials, controller: controller, handler)
    }
    
    private func loginOrRegister(_ credentials: SyncCredentials, controller: UIViewController, _ handler: @escaping (ProviderResult<SyncResult>) -> Void) {
        
        let syncHost = "192.168.0.12"
        let syncAuthURL = URL(string: "http://\(syncHost):9080")!
        let syncRealmPath = "groma"
        let syncServerURL = URL(string: "realm://\(syncHost):9080/~/\(syncRealmPath)")!
        
        QL1("Logging in with credentials: \(credentials), auth url: \(syncAuthURL)")
        
        SyncUser.logIn(with: credentials, server: syncAuthURL) {[weak self] user, error in
            DispatchQueue.main.async {
                if let user = user {
                    QL1("\nlogged in user: \(user)")
                    
                    var config = AppDelegate.realmConfig
                    
                    config.syncConfiguration = SyncConfiguration(user: user, realmURL: syncServerURL)
                    config.objectTypes = [DBList.self, DBInventory.self, DBSection.self, DBProduct.self, DBSharedUser.self, DBListItem.self, DBInventoryItem.self, DBSyncable.self, DBHistoryItem.self, DBPlanItem.self, DBListItemGroup.self, DBGroupItem.self, DBProductCategory.self, DBStoreProduct.self]
                    Realm.Configuration.defaultConfiguration = config
                    
                    do {
                        self?.notificationToken = try Realm().addNotificationBlock { _ in
                            QL2("Realm changed")
                        }
                        
                        if let identity = user.identity {
                            self?.storeEmail(identity)
                        } else {
                            QL3("User: \(user) has no identity")
                        }
                        
                        
                        // Pass a sync result for compatibility with the protocol interface (originally written for own server)
                        handler(ProviderResult(status: .success, sucessResult: SyncResult(listInvites: [], inventoryInvites: [])))
                        
                    } catch let error {
                        QL4("Couldn't instantiate Realm during login/register: \(error)")
                        handler(ProviderResult(status: .unknown))
                    }

                } else {
                    QL4("Error during login/register, no user: \(error)")
                    handler(ProviderResult(status: .unknown))
                }
            }
        }
    }
    
    func isRegistered(_ email: String, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        QL4("Not implemented")
        handler(ProviderResult(status: .success))
    }
    
    func logout(_ handler: @escaping (ProviderResult<Any>) -> ()) {
        if let user = SyncUser.current {
            user.logOut()
            
        } else {
            QL3("No user to logout")
        }
        handler(ProviderResult(status: .success))
        
        // Sign out of social providers in case we are logged in with them
        // Note: If we add osx support later we must move these calls to iOS-only part. The idea is to not have any iOS specific code in the providers.
        FBSDKLoginManager().logOut()
        GIDSignIn.sharedInstance().signOut()
        GIDSignIn.sharedInstance().disconnect()
    }
    
    func sync(isMatchSync: Bool, onlyOverwriteLocal: Bool, additionalActionsOnSyncSuccess: VoidFunction? = nil, handler: @escaping (ProviderResult<SyncResult>) -> Void) {
        QL4("Not implemented") // this method is not necessary for realm provider
        handler(ProviderResult(status: .success))
    }
    
    func connectWebsocketIfLoggedIn() {
        QL4("Not implemented") // this method is not necessary for realm provider
    }
    
    func disconnectWebsocket() {
        QL4("Not implemented") // this method is not necessary for realm provider
    }
    
    func isWebsocketConnected() -> Bool {
        QL4("Not implemented") // this method is not necessary for realm provider
        return false
    }
    
    func forgotPassword(_ email: String, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        QL4("Not implemented") // TODO
        handler(ProviderResult(status: .success))
    }
    
    func removeAccount(_ handler: @escaping (ProviderResult<Any>) -> ()) {
        QL4("Not implemented") // TODO
        handler(ProviderResult(status: .success))
    }
    
    func removeLoginToken() {
        QL4("Not implemented") // this method is not necessary for realm provider?
    }
    
    func ping() {
        QL4("Not implemented") // this method is not necessary for realm provider
    }
    
    var hasLoginToken: Bool {
        QL4("Not implemented") // this method is not necessary for realm provider
        return true
    }
    
    var hasSignedInOnce: Bool {
        QL4("Not implemented") // this method is not necessary for realm provider
        return true
    }
    
    var mySharedUser: SharedUser? {
        if let email: String = PreferencesManager.loadPreference(PreferencesManagerKey.email) {
            return SharedUser(email: email)
        } else {
            return nil
        }
    }
    
    func findAllKnownSharedUsers(_ handler: @escaping (ProviderResult<[SharedUser]>) -> Void) {
        QL4("Not implemented") // this method is not necessary for realm provider (for now, since we don't share items with real provider)
        handler(ProviderResult(status: .success))
    }
    
    func isDifferentUser(_ email: String) -> Bool {
        return mySharedUser.map{$0.email != email} ?? false
    }
    
    // MARK: - Social login
    
    
    // TODO!!!! don't use default error handler here, if no connection etc we have to show an alert not ignore --- is this todo also relevant for this new realm user provider?
    func authenticateWithFacebook(_ token: String, controller: UIViewController, _ handler: @escaping (ProviderResult<SyncResult>) -> ()) {
        let credentials = SyncCredentials.facebook(token: token)
        loginOrRegister(credentials, controller: controller, handler)
    }
    
    // TODO!!!! don't use default error handler here, if no connection etc we have to show an alert not ignore --- is this todo also relevant for this new realm user provider?
    func authenticateWithGoogle(_ token: String, controller: UIViewController, _ handler: @escaping (ProviderResult<SyncResult>) -> ()) {
        let credentials = SyncCredentials.google(token: token)
        loginOrRegister(credentials, controller: controller, handler)
    }
    
    func authenticateWithICloud(_ token: String, controller: UIViewController, _ handler: @escaping (ProviderResult<SyncResult>) -> Void) {
        let credentials = SyncCredentials.iCloud(token: token)
        loginOrRegister(credentials, controller: controller, handler)
    }
    
    // store email in prefs so we can e.g. prefill login controller, which is opened after registration
    // For now store it as simple preference, we need it to be added automatically to list shared users. This may change in the future
    fileprivate func storeEmail(_ email: String) {
        PreferencesManager.savePreference(PreferencesManagerKey.email, value: NSString(string: email))
    }
}
