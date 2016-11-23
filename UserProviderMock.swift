//
//  UserProviderMock.swift
//  shoppin
//
//  Created by ischuetz on 03/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

// Emulates login etc. so we can test without internet or server
class UserProviderMock: UserProvider {
    
    var hasLoginToken: Bool {
        return isLoggedIn
    }
    
    fileprivate var isLoggedIn = false
    
    fileprivate let requestDelay: Double = 2
    
    fileprivate var email: String?
    
    var hasSignedInOnce: Bool {
        return hasLoginToken
    }
    
    func isDifferentUser(_ email: String) -> Bool {
        return self.email.map{$0 != email} ?? false
    }
    
    func login(_ loginData: LoginData, controller: UIViewController, _ handler: @escaping (ProviderResult<SyncResult>) -> ()) {
        delay(requestDelay) {[weak self] in
            self?.isLoggedIn = true
            self?.email = loginData.email
            handler(ProviderResult(status: .success, sucessResult: SyncResult(listInvites: [], inventoryInvites: [])))
        }
    }
    
    func register(_ user: UserInput, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        delay(requestDelay) {[weak self] in
            self?.isLoggedIn = true
            self?.email = user.email
            handler(ProviderResult(status: .success))
        }
    }
    
    func removeLoginToken() {
    }
    
    func ping() {
    }
    
    func isRegistered(_ email: String, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        delay(requestDelay) {
            handler(ProviderResult(status: .success, sucessResult: true))
        }
    }
    
    func logout(_ handler: @escaping (ProviderResult<Any>) -> ()) {
        isLoggedIn = false
        handler(ProviderResult(status: .success))
    }
    
    func sync(_ handler: @escaping (ProviderResult<SyncResult>) -> Void) {
        Providers.globalProvider.sync(false) {result in
            handler(result)
        }
    }
    
    func connectWebsocketIfLoggedIn() {
    }
    
    func disconnectWebsocket() {
    }
    
    func isWebsocketConnected() -> Bool {
        return false
    }
    
    func forgotPassword(_ email: String, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        delay(requestDelay) {
            handler(ProviderResult(status: .success, sucessResult: true))
        }
    }
    
    func removeAccount(_ handler: @escaping (ProviderResult<Any>) -> ()) {
        delay(requestDelay) {[weak self] in
            self?.isLoggedIn = false
            handler(ProviderResult(status: .success, sucessResult: true))
        }
    }
    

    var mySharedUser: SharedUser? {
        if let email = email {
            return SharedUser(email: email)
        } else {
            return nil
        }
    }
    
    func findAllKnownSharedUsers(_ handler: @escaping (ProviderResult<[SharedUser]>) -> Void) {
        let dummies = [
            SharedUser(email: "goo@gar.com"),
            SharedUser(email: "lalala@werw.com"),
            SharedUser(email: "hello@hello.hello"),
        ]
        handler(ProviderResult(status: .success, sucessResult: dummies))
    }
    
    // MARK: - Social login
    
    func authenticateWithFacebook(_ token: String, controller: UIViewController, _ handler: @escaping (ProviderResult<SyncResult>) -> ()) {
        delay(requestDelay) {
            let syncResult = SyncResult(listInvites: [], inventoryInvites: [])
            handler(ProviderResult(status: .success, sucessResult: syncResult))
        }
    }
    
    
    func authenticateWithGoogle(_ token: String, controller: UIViewController, _ handler: @escaping (ProviderResult<SyncResult>) -> ()) {
        delay(requestDelay) {
            let syncResult = SyncResult(listInvites: [], inventoryInvites: [])
            handler(ProviderResult(status: .success, sucessResult: syncResult))
        }
    }
}
