//
//  RemoteUserProvider.swift
//  shoppin
//
//  Created by ischuetz on 22/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import Valet
import QorumLogs

class RemoteUserProvider {
    
    // TODO refactor providers to return remoteresult. mapping to try and NSError seems nonsensical
    
    func login(loginData: LoginData, handler: RemoteResult<RemoteLoginResult> -> ()) {
        let parameters: [String: AnyObject] = [
            "email": loginData.email,
            "password": loginData.password
        ]
        RemoteProvider.request(.POST, Urls.login, parameters) {[weak self] (result: RemoteResult<RemoteLoginResult>) in
            if let successResult = result.successResult {
                self?.storeUserData(successResult.token, email: loginData.email)
            } else {
                QL4("No token. Result: \(result)")
            }
            handler(result)
        }
    }
    
    func register(user: UserInput, handler: RemoteResult<RemoteRegisterResult> -> ()) {
        
        let parameters = self.toRequestParams(user)
        
        RemoteProvider.request(.POST, Urls.register, parameters) {[weak self] (result: RemoteResult<RemoteRegisterResult>) in
            if let successResult = result.successResult {
                self?.storeUserData(successResult.token, email: user.email)
            } else {
                QL4("No token. Result: \(result)")
            }
            handler(result)
        }
    }
    
    func ping(handler: RemoteResult<RemotePingResult> -> ()) {
        RemoteProvider.authenticatedRequest(.GET, Urls.ping) {[weak self] (result: RemoteResult<RemotePingResult>) in
            if result.success {
                if let successResult = result.successResult {
                    self?.storeToken(successResult.token) // update (replace) the token
                } else {
                    QL4("No token. Result: \(result)")
                }
                handler(result)
            }
            handler(result)
        }
    }
    
    func isRegistered(email: String, handler: RemoteResult<NoOpSerializable> -> ()) {
        RemoteProvider.authenticatedRequest(.POST, Urls.isRegistered + "/\(email)") {(result: RemoteResult<NoOpSerializable>) in
            handler(result)
        }
    }
    
    func forgotPassword(email: String, handler: RemoteResult<NoOpSerializable> -> ()) {
        let parameters = ["email": email, "foo": "foo"] // foo is a filler parameter bc of a bug in the server
        RemoteProvider.request(.POST, Urls.forgotPassword, parameters) {result in
            handler(result)
        }
    }
    
    func removeAccount(handler: RemoteResult<NoOpSerializable> -> ()) {
        RemoteProvider.authenticatedRequest(.DELETE, Urls.removeAccount) {[weak self] (result: RemoteResult<NoOpSerializable>) in
            if result.success {
                self?.removeToken()
            }
            handler(result)
        }
    }
    
    func hasToken() -> Bool {
        let valet = VALValet(identifier: KeychainKeys.ValetIdentifier, accessibility: VALAccessibility.AfterFirstUnlock)
        if let valet = valet {
            return valet.containsObjectForKey(KeychainKeys.token)
        } else {
            QL4("Valet not set, returning false")
            return false
        }
    }
    
    private func storeToken(token: String) {
        let valet = VALValet(identifier: KeychainKeys.ValetIdentifier, accessibility: VALAccessibility.AfterFirstUnlock)
        if let valet = valet {
            if valet.setString(token, forKey: KeychainKeys.token) {
                QL1("Stored token: \(token)")
                PreferencesManager.savePreference(PreferencesManagerKey.lastTokenUpdate, value: NSDate())
            } else {
                QL4("Couldn't store token")
            }
        } else {
            QL4("Valet not set, couldn't store token")
        }
    }
    
    private func removeToken() {
        let valet = VALValet(identifier: KeychainKeys.ValetIdentifier, accessibility: VALAccessibility.AfterFirstUnlock)
        if let valet = valet {
            if !valet.removeObjectForKey(KeychainKeys.token) {
                QL4("Remove token returned false")
            }
        } else {
            QL4("Valet not set")
        }
    }
    
    // For now store the user's email as simple preference, we need it to be added automatically to list shared users. This may change in the future
    private func storeEmail(email: String) {
        PreferencesManager.savePreference(PreferencesManagerKey.email, value: NSString(string: email))
    }
    
    func logout(handler: RemoteResult<NoOpSerializable> -> ()) {
        // with JWT we just have to remove token from client no need to call the server TODO verify this
        self.removeToken()
        handler(RemoteResult<NoOpSerializable>(status: .Success))
    }
    
    func authenticateWithFacebook(token: String, handler: RemoteResult<RemoteSocialLoginResult> -> ()) {
        let parameters = ["access_token": token]
        RemoteProvider.request(.POST, Urls.authFacebook, parameters) {[weak self] (result: RemoteResult<RemoteSocialLoginResult>) in
            if let successResult = result.successResult {
                self?.storeUserData(successResult.token, email: successResult.email)
            }
            handler(result)
        }
    }

    func authenticateWithGoogle(token: String, handler: RemoteResult<RemoteSocialLoginResult> -> ()) {
        let parameters = ["access_token": token]
        RemoteProvider.request(.POST, Urls.authGoogle, parameters) {[weak self] (result: RemoteResult<RemoteSocialLoginResult>) in
            if let successResult = result.successResult {
                self?.storeUserData(successResult.token, email: successResult.email)
            }
            handler(result)
        }
    }
    
    private func storeUserData(token: String, email: String) {
        self.storeToken(token)
        self.storeEmail(email)
    }
    
    func toRequestParams(user: UserInput) -> [String: AnyObject] {
        return [
            "email": user.email,
            "firstName": user.firstName,
            "lastName": user.lastName,
            "password": user.password
        ]
    }

}
