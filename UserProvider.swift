//
//  UserProvider.swift
//  shoppin
//
//  Created by ischuetz on 26/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

protocol UserProvider {
   
    var loggedIn: Bool {get}
   
    /**
    * User data which is stored after successful login or register (credentials or social media)
    * This is never removed, only overwritten in case another user logs in or register
    * This can be useful to know if there was ever a synchronisation with the server - if there's no saved user it means all database data is local-only, but NOTE: no guarantee as sync is a separate request after login/register and maybe sth goes wrong with it, in which case we saved the user but didn't do sync. This is maybe temporary though as the next time user does sync (by either log out/in or toggle connection state) it may succeed.
    */
    var mySharedUser: SharedUser? {get}

    func login(loginData: LoginData, _ handler: ProviderResult<Any> -> ())
    
    func register(user: UserInput, _ handler: ProviderResult<Any> -> ())
    
    func isRegistered(email: String, _ handler: ProviderResult<Any> -> ())
    
    func logout(handler: ProviderResult<Any> -> ())
    
    func authenticateWithFacebook(token: String, _ handler: ProviderResult<Any> -> ())
    
    func authenticateWithGoogle(token: String, _ handler: ProviderResult<Any> -> ())

    func forgotPassword(email: String, _ handler: ProviderResult<Any> -> ())
    
    func removeAccount(handler: ProviderResult<Any> -> ())
    
    func connectWebsocketIfLoggedIn()
    
    func disconnectWebsocket()
    
    // Updates token
    func ping()
}