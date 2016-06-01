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
    
    private var isLoggedIn = false
    
    private let requestDelay: Double = 2
    
    private var email: String?
    
    var hasSignedInOnce: Bool {
        return hasLoginToken
    }
    
    func isDifferentUser(email: String) -> Bool {
        return self.email.map{$0 != email} ?? false
    }
    
    func login(loginData: LoginData, controller: UIViewController, _ handler: ProviderResult<SyncResult> -> ()) {
        delay(requestDelay) {[weak self] in
            self?.isLoggedIn = true
            self?.email = loginData.email
            handler(ProviderResult(status: .Success, sucessResult: SyncResult(listInvites: [], inventoryInvites: [])))
        }
    }
    
    func register(user: UserInput, _ handler: ProviderResult<Any> -> ()) {
        delay(requestDelay) {[weak self] in
            self?.isLoggedIn = true
            self?.email = user.email
            handler(ProviderResult(status: .Success))
        }
    }
    
    func removeLoginToken() {
    }
    
    func ping() {
    }
    
    func isRegistered(email: String, _ handler: ProviderResult<Any> -> ()) {
        delay(requestDelay) {
            handler(ProviderResult(status: .Success, sucessResult: true))
        }
    }
    
    func logout(handler: ProviderResult<Any> -> ()) {
        isLoggedIn = false
        handler(ProviderResult(status: .Success))
    }
    
    func sync(handler: ProviderResult<SyncResult> -> Void) {
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
    
    func forgotPassword(email: String, _ handler: ProviderResult<Any> -> ()) {
        delay(requestDelay) {
            handler(ProviderResult(status: .Success, sucessResult: true))
        }
    }
    
    func removeAccount(handler: ProviderResult<Any> -> ()) {
        delay(requestDelay) {[weak self] in
            self?.isLoggedIn = false
            handler(ProviderResult(status: .Success, sucessResult: true))
        }
    }
    

    var mySharedUser: SharedUser? {
        if let email = email {
            return SharedUser(email: email)
        } else {
            return nil
        }
    }
    
    func findAllKnownSharedUsers(handler: ProviderResult<[SharedUser]> -> Void) {
        let dummies = [
            SharedUser(email: "goo@gar.com"),
            SharedUser(email: "lalala@werw.com"),
            SharedUser(email: "hello@hello.hello"),
        ]
        handler(ProviderResult(status: .Success, sucessResult: dummies))
    }
    
    // MARK: - Social login
    
    func authenticateWithFacebook(token: String, controller: UIViewController, _ handler: ProviderResult<SyncResult> -> ()) {
        delay(requestDelay) {
            let syncResult = SyncResult(listInvites: [], inventoryInvites: [])
            handler(ProviderResult(status: .Success, sucessResult: syncResult))
        }
    }
    
    
    func authenticateWithGoogle(token: String, controller: UIViewController, _ handler: ProviderResult<SyncResult> -> ()) {
        delay(requestDelay) {
            let syncResult = SyncResult(listInvites: [], inventoryInvites: [])
            handler(ProviderResult(status: .Success, sucessResult: syncResult))
        }
    }
}