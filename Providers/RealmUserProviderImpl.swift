//
//  RealmUserProviderImpl.swift
//  shoppin
//
//  Created by Ivan Schütz on 01/12/2016.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

import CloudKit

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
        loginOrRegister(credentials, userName: loginData.email, controller: controller, handler)
    }
    
    // We pass userName separately because it's not safely retrievable from SyncCredentials
    private func loginOrRegister(_ credentials: SyncCredentials, userName: String? = nil, controller: UIViewController, _ handler: @escaping (ProviderResult<SyncResult>) -> Void) {

        #if (arch(i386) || arch(x86_64)) && os(iOS)
            let syncHost = "127.0.0.1"
        #else // device
            let syncHost = "192.168.0.208"
        #endif

        let syncAuthURL = URL(string: "http://\(syncHost):9080")!
        let syncRealmPath = "groma4"
        let syncServerURL = URL(string: "realm://\(syncHost):9080/~/\(syncRealmPath)")!
        
        logger.v("Logging in with credentials: \(credentials), auth url: \(syncAuthURL)")
        
        SyncUser.logIn(with: credentials, server: syncAuthURL) {[weak self] user, error in

            DispatchQueue.main.sync {

                if let user = user {
                    logger.v("\nlogged in user: \(user)")
                    
                    var config = RealmConfig.config
                    
                    config.syncConfiguration = SyncConfiguration(user: user, realmURL: syncServerURL)
                    config.objectTypes = [List.self, DBInventory.self, Section.self, Product.self, DBSharedUser.self, DBRemoveList.self, DBRemoveInventory.self, ListItem.self, InventoryItem.self, DBSyncable.self, HistoryItem.self, DBPlanItem.self, ProductGroup.self, GroupItem.self, ProductCategory.self, StoreProduct.self, Recipe.self, Ingredient.self,
                        SectionToRemove.self, ProductToRemove.self, StoreProductToRemove.self, DBRemoveSharedUser.self, DBRemoveGroupItem.self, DBRemoveProductCategory.self, DBRemoveInventoryItem.self, DBRemoveProductGroup.self, Item.self, Unit.self, QuantifiableProduct.self, RecipesContainer.self, InventoriesContainer.self, ListsContainer.self, BaseQuantitiesContainer.self, BaseQuantity.self
                    ]
                        
                    Realm.Configuration.defaultConfiguration = config
                    
                    do {
                        self?.notificationToken = try Realm().addNotificationBlock { _ in
                            logger.d("Realm changed")
                        }
                        
                        if let userName = userName { // for credentials login
//                            self?.storeEmail(user.identity) // not the user name / email
                            self?.storeEmail(userName)
                        } else {
                            logger.w("User: \(user) has no identity")
                        }
                        
                        
                        // Pass a sync result for compatibility with the protocol interface (originally written for own server)
                        handler(ProviderResult(status: .success, sucessResult: SyncResult(listInvites: [], inventoryInvites: [])))
                        
                    } catch let error {
                        logger.e("Couldn't instantiate Realm during login/register: \(error)")
                        handler(ProviderResult(status: .unknown))
                    }

                } else {
                    logger.e("Error during login/register, no user: \(String(describing: error))")
                    // TODO!!!!!!!!!!!!!!!! fix/ask:
//                     RealmUserProviderImpl.swift:82 loginOrRegister(_:userName:controller:_:): ❤️Error during login/register, no user: Optional(Error Domain=io.realm.sync Code=3 "Your request parameters did not validate." UserInfo={statusCode=400, NSLocalizedDescription=Your request parameters did not validate.})❤️

                    switch error {
                    case let nsError as NSError:
                        switch nsError.code {
                        case 611: handler(ProviderResult(status: .invalidCredentials))
                        default: handler(ProviderResult(status: .unknown))
                        }
                    default: handler(ProviderResult(status: .unknown))
                    }
                }
            }
        }
    }
    
    func isRegistered(_ email: String, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        logger.e("Not implemented")
        handler(ProviderResult(status: .success))
    }
    
    func logout(_ handler: @escaping (ProviderResult<Any>) -> ()) {

        // TODO investigate why sometimes more than 1 user here (causes impl of SyncUser.current to throw an error). Happens when logging in, restarting app and trying to log in with invalid user id (both with credentials)
        let allUsers = SyncUser.all.values
        
        if allUsers.isEmpty {
            logger.w("No user to logout")
        } else if allUsers.count > 1 {
            logger.e("Warning/error: more than 1 user logged in: \(allUsers)")
        }
        
        for user in allUsers {
            user.logOut()
        }
        
        handler(ProviderResult(status: .success))
        
        // Target specific logout (e.g. iOS has own FB, Google, etc. libraries). Logout can be called from core parts of library like when auth token expires, so a notification is suitable.
        Notification.send(Notification.Logout)
    }
    
    func sync(isMatchSync: Bool, onlyOverwriteLocal: Bool, additionalActionsOnSyncSuccess: VoidFunction? = nil, handler: @escaping (ProviderResult<SyncResult>) -> Void) {
        logger.e("Not implemented") // this method is not necessary for realm provider
        handler(ProviderResult(status: .success))
    }
    
    func connectWebsocketIfLoggedIn() {
        logger.e("Not implemented") // this method is not necessary for realm provider
    }
    
    func disconnectWebsocket() {
        logger.e("Not implemented") // this method is not necessary for realm provider
    }
    
    func isWebsocketConnected() -> Bool {
        logger.e("Not implemented") // this method is not necessary for realm provider
        return false
    }
    
    func forgotPassword(_ email: String, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        logger.e("Not implemented") // TODO
        handler(ProviderResult(status: .success))
    }
    
    func removeAccount(_ handler: @escaping (ProviderResult<Any>) -> ()) {
        logger.e("Not implemented") // TODO
        handler(ProviderResult(status: .success))
    }
    
    func removeLoginToken() {
        logger.e("Not implemented") // this method is not necessary for realm provider?
    }
    
    func ping() {
        logger.e("Not implemented") // this method is not necessary for realm provider
    }
    
    var hasLoginToken: Bool {
        logger.e("Not implemented") // this method is not necessary for realm provider
        return true
    }
    
    var hasSignedInOnce: Bool {
        logger.e("Not implemented") // this method is not necessary for realm provider
        return true
    }
    
    var mySharedUser: DBSharedUser? {
        if let email: String = PreferencesManager.loadPreference(PreferencesManagerKey.email) {
            return DBSharedUser(email: email)
        } else {
            return nil
        }
    }
    
    func findAllKnownSharedUsers(_ handler: @escaping (ProviderResult<[DBSharedUser]>) -> Void) {
        logger.e("Not implemented") // this method is not necessary for realm provider (for now, since we don't share items with real provider)
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
    
    func authenticateWithICloud(controller: UIViewController, _ handler: @escaping (ProviderResult<SyncResult>) -> Void) {
        
        let container = CKContainer.default()
        container.fetchUserRecordID(completionHandler: {(recordID: CKRecordID?, error: Error?) in
            if let error = error {
                logger.e("Couldn't fetch iCloud user record, error: \(error)")
                handler(ProviderResult(status: .iCloudLoginError))
                
            } else if let userAccessToken = recordID?.recordName {
                logger.d("Retrieved cloudKit token: \(userAccessToken), logging in...")
                
                let credentials = SyncCredentials.cloudKit(token: userAccessToken)
                self.loginOrRegister(credentials, controller: controller, handler)
                
            } else{
                logger.e("Invalid state: No error, but also no user record")
                handler(ProviderResult(status: .iCloudLoginError))
            }
        })
    }
    
    // store email in prefs so we can e.g. prefill login controller, which is opened after registration
    // For now store it as simple preference, we need it to be added automatically to list shared users. This may change in the future
    fileprivate func storeEmail(_ email: String) {
        PreferencesManager.savePreference(PreferencesManagerKey.email, value: NSString(string: email))
    }
}
