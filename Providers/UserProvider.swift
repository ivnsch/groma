//
//  UserProvider.swift
//  shoppin
//
//  Created by ischuetz on 26/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

public protocol UserProvider {
   
    /**
    * If there's a login token stored (a token is saved on login, register and ping response).
    * Can be used as an approximation of "is logged in". We try to avoid token expiration via ping, but it can happen that it is expired. On unauthorized response the token is removed. So after the first call with an expired/invalid token, hasLoginToken returns false. The token is also removed on logout.
    */
    var hasLoginToken: Bool {get}
    
    func removeLoginToken()
    
    // Updates token
    func ping()
    
    // If the user has logged in or registered with this device at least once
    // This is a flag used for example to know if user uses the app in offline modus. Note that it's not very accurate - user may have logged in once but then logout and keep using the app forever in offline modus, this case hasSignedInOnce still returns true. We don't know if the user is offline only shortly or forever so this is all we have.
    // Currently this is the same as mySharedUser != nil but maybe we change the specification of mySharedUser later, so it's better to have a separate variable.
    var hasSignedInOnce: Bool {get}
    
    /**
    * User data which is stored after successful login or register (credentials or social media)
    * This is never removed, only overwritten in case another user logs in or register
    * This can be useful to know if there was ever a synchronisation with the server - if there's no saved user it means all database data is local-only, but NOTE: no guarantee as sync is a separate request after login/register and maybe sth goes wrong with it, in which case we saved the user but didn't do sync. This is maybe temporary though as the next time user does sync (by either log out/in or toggle connection state) it may succeed.
    */
    var mySharedUser: DBSharedUser? {get}

    func isDifferentUser(_ email: String) -> Bool
    
    // TODO don't pass controller, no UIKit things in providers. Pass a block instead.
    func login(_ loginData: LoginData, controller: UIViewController, _ handler: @escaping (ProviderResult<SyncResult>) -> Void)
    
    func register(_ user: UserInput, controller: UIViewController, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    func isRegistered(_ email: String, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    func logout(_ handler: @escaping (ProviderResult<Any>) -> Void)
    
    // TODO don't pass controller, no UIKit things in providers. Pass a block instead.
    func authenticateWithFacebook(_ token: String, controller: UIViewController, _ handler: @escaping (ProviderResult<SyncResult>) -> Void)
    
    // TODO don't pass controller, no UIKit things in providers. Pass a block instead.
    func authenticateWithGoogle(_ token: String, controller: UIViewController, _ handler: @escaping (ProviderResult<SyncResult>) -> Void)

    func authenticateWithICloud(controller: UIViewController, _ handler: @escaping (ProviderResult<SyncResult>) -> Void)

    func forgotPassword(_ email: String, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    func removeAccount(_ handler: @escaping (ProviderResult<Any>) -> Void)
    
    func connectWebsocketIfLoggedIn()
    
    func disconnectWebsocket()
    
    func isWebsocketConnected() -> Bool
    
    func findAllKnownSharedUsers(_ handler: @escaping (ProviderResult<[DBSharedUser]>) -> Void)
}
