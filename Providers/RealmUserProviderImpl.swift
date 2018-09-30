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
import Alamofire
import Valet

class RealmUserProviderImpl: UserProvider {

    fileprivate var notificationToken: NotificationToken?

    func login(_ loginData: LoginData, _ handler: @escaping (ProviderResult<SyncResult>) -> ()) {
        login(loginData, register: false) { [weak self] result in
            if result.success {
                self?.storeLoginData(loginData: loginData)
            }
            handler(result)
        }
    }

    func register(_ user: UserInput, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        let loginData = LoginData(email: user.email, password: user.password)
        let credentials = SyncCredentials.usernamePassword(username: loginData.email, password: loginData.password, register: true)

        SyncUser.logIn(with: credentials, server: RealmConfig.syncAuthURL) { user, error in
            DispatchQueue.main.async {
                if let error = error {
                    logger.e("Error registering: \(error)", .auth)
                    handler(ProviderResult(status: .unknown))

                } else {
                    logger.i("Register success - send confirmation email", .auth)
                    handler(ProviderResult(status: .success))
                }
            }
        }
    }
    
    private func login(_ loginData: LoginData, register: Bool, _ handler: @escaping (ProviderResult<SyncResult>) -> Void) {
        let credentials = SyncCredentials.usernamePassword(username: loginData.email, password: loginData.password, register: register)
        login(credentials, userName: loginData.email, handler)
    }

    func loginIfStoredData(_ handler: @escaping (ProviderResult<SyncResult>) -> Void) {
        let valet = VALValet(identifier: KeychainKeys.ValetIdentifier, accessibility: VALAccessibility.afterFirstUnlock)
        let userEmail = valet?.string(forKey: KeychainKeys.userEmail)
        let userPassword = valet?.string(forKey: KeychainKeys.userPassword)

        if let userEmail = userEmail, let userPassword = userPassword {
            login(LoginData(email: userEmail, password: userPassword), register: false, handler)
        } else {
            if ((userEmail == nil && userPassword != nil) || (userEmail != nil && userPassword == nil)) {
                logger.e("Invalid state - there should be always user name and password stored or none of them.")
            }

            logger.i("No user email / password stored")
            handler(ProviderResult(status: ProviderStatusCode.notFound))
        }
    }

    fileprivate func storeLoginData(loginData: LoginData) {
        let valet = VALValet(identifier: KeychainKeys.ValetIdentifier, accessibility: VALAccessibility.afterFirstUnlock)
        if let valet = valet {
            if valet.setString(loginData.email, forKey: KeychainKeys.userEmail) {
                logger.i("Success storing user email")
                if valet.setString(loginData.email, forKey: KeychainKeys.userPassword) {
                    logger.i("Success storing user password")
                } else {
                    logger.e("Couldn't user email. Can access key chain: \(valet.canAccessKeychain())")
                }
            } else {
                // See https://github.com/square/Valet/issues/75 supposedly this happens only during debug. canAccessKeychain returns false with no apparent reason (device).
                logger.e("Couldn't user email. Can access key chain: \(valet.canAccessKeychain())")
            }
        } else {
            logger.e("Valet not set, couldn't store token")
        }
    }
    
    // We pass userName separately because it's not safely retrievable from SyncCredentials
    private func login(_ credentials: SyncCredentials, userName: String? = nil, _ handler: @escaping (ProviderResult<SyncResult>) -> Void) {

        logger.v("Logging in with credentials: \(credentials)")

        SyncUser.logIn(with: credentials, server: RealmConfig.syncAuthURL) {[weak self] user, error in

            DispatchQueue.main.async {

                if let user = user {
                    logger.v("logged in user: \(user)")

                    Realm.Configuration.defaultConfiguration = RealmConfig.syncedRealmConfigutation(user: user)

                    do {
                        self?.notificationToken = try RealmConfig.realm().observe { _,_  in
                            logger.d("Realm changed")
                        }

                        if let userName = userName { // for credentials login
//                            self?.storeEmail(user.identity) // not the user name / email
                            self?.storeEmail(userName)
                        } else {
                            logger.w("User: \(user) has no identity")
                        }

                        guard let localRealm = RealmConfig.localRealm() else {
                            logger.e("Couldn't create local realm - can't migrate!", .db)
                            handler(ProviderResult(status: .databaseUnknown))
                            return
                        }

                        RealmConfig.syncedRealm(user: user, onReady: { syncedRealm in
                            guard let syncedRealm = syncedRealm else {
                                logger.e("Couldn't create remote realm - can't migrate!", .db)
                                handler(ProviderResult(status: .databaseUnknown))
                                return
                            }
                            if syncedRealm.isEmpty {
                                RealmGlobalProvider().migrate(srcRealm: localRealm, targetRealm: syncedRealm)
                            }
                            handler(ProviderResult(status: .success, sucessResult: SyncResult(listInvites: [], inventoryInvites: [])))
                            Notification.send(.realmSwapped)
                        })

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
                        case -1004: handler(ProviderResult(status: .serverNotReachable))
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
        SyncUser.requestPasswordReset(forAuthServer: RealmConfig.syncAuthURL, userEmail: email, completion: { errorMaybe in
            DispatchQueue.main.async {
                if let error = errorMaybe {
                    logger.e("Error reseting password: \(error)", .db)
                    handler(ProviderResult(status: .databaseUnknown))
                } else {
                    logger.i("Reset password call success", .db)
                    handler(ProviderResult(status: .success))
                }
            }
        })
    }
    
    func removeAccount(_ handler: @escaping (ProviderResult<Any>) -> ()) {
        guard let currentUser = SyncUser.current else {
            logger.e("No current user! can't remove account", .api, .db)
            handler(ProviderResult(status: .unknown))
            return
        }

        guard let identity = currentUser.identity else {
            logger.e("User has no identity! can't remove account. User: \(currentUser)", .api, .db)
            handler(ProviderResult(status: .unknown))
            return
        }

        // TODO test that removing account works

        // TODO confirm that identity is what we send here
        let urlString = RealmConfig.syncUserUrl.appendingPathComponent(identity).absoluteString

        // TODO refresh token, see https://github.com/realm/realm-object-server/issues/315
        Alamofire.request(urlString, method: .delete, headers: ["authorization": "TODO token"])
            .responseJSON { response in
                if let error = response.result.error {
                    logger.e("Error ocurred deleting user from ros: \(error)", .api)
                    handler(ProviderResult(status: .serverError))
                } else {
                    handler(ProviderResult(status: .success))
                }
        }
    }
    
    func removeLoginToken() {
        logger.e("Not implemented") // this method is not necessary for realm provider?
    }
    
    func ping() {
        logger.e("Not implemented") // this method is not necessary for realm provider
    }
    
    var hasLoginToken: Bool {
        return SyncUser.current != nil
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
    func authenticateWithFacebook(_ token: String, _ handler: @escaping (ProviderResult<SyncResult>) -> ()) {
        let credentials = SyncCredentials.facebook(token: token)
        login(credentials, handler)
    }
    
    // TODO!!!! don't use default error handler here, if no connection etc we have to show an alert not ignore --- is this todo also relevant for this new realm user provider?
    func authenticateWithGoogle(_ token: String, _ handler: @escaping (ProviderResult<SyncResult>) -> ()) {
        let credentials = SyncCredentials.google(token: token)
        login(credentials, handler)
    }
    
    func authenticateWithICloud(_ handler: @escaping (ProviderResult<SyncResult>) -> Void) {
        
        let container = CKContainer.default()
        container.fetchUserRecordID(completionHandler: {(recordID: CKRecord.ID?, error: Error?) in
            if let error = error {
                logger.e("Couldn't fetch iCloud user record, error: \(error)")
                handler(ProviderResult(status: .iCloudLoginError))
                
            } else if let userAccessToken = recordID?.recordName {
                logger.d("Retrieved cloudKit token: \(userAccessToken), logging in...")
                
                let credentials = SyncCredentials.cloudKit(token: userAccessToken)
                self.login(credentials, handler)
                
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
