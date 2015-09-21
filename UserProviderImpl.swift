//
//  UserProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 26/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import FBSDKLoginKit

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
    
    func sync(handler: VoidFunction) {

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
    
    func forgotPassword(email: String, _ handler: ProviderResult<Any> -> ()) {
        remoteProvider.forgotPassword(email) {result in
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
    
    // TODO move fb sdk logic to view controller, this is not available in osx!
    func facebookLogin(handler: ProviderResult<Any> -> ()) {
        let login = FBSDKLoginManager()
        login.logInWithReadPermissions(["public_profile"]) {[weak self] result, error in
            if let error = error {
                print("Error: Facebook login: error: \(error)")
                handler(ProviderResult(status: .SocialLoginError))
                
            } else if result.isCancelled {
                print("Facebook login cancelled")
                handler(ProviderResult(status: .SocialLoginCancelled))
                
            } else {
                print("Facebook login success, calling our server...")
                let tokenString = result.token.tokenString
                self?.authenticateWithFacebook(tokenString) {result in
                    
                    // map already exists status to "social aleready exists", to show a different error message
                    if result.status == .AlreadyExists {
                        handler(ProviderResult(status: .SocialAlreadyExists))
                    } else {
                        handler(result)
                    }
                }
            }
        }
    }
    
    private func authenticateWithFacebook(token: String, _ handler: ProviderResult<Any> -> ()) {
        self.remoteProvider.authenticateWithFacebook(token) {[weak self] result in
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

    
    func authenticateWithGoogle(token: String, _ handler: ProviderResult<Any> -> ()) {
        self.remoteProvider.authenticateWithGoogle(token) {[weak self] result in
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
    
}
