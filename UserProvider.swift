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
   
    var mySharedUser: SharedUser? {get}

    func login(loginData: LoginData, _ handler: ProviderResult<Any> -> ())
    
    func register(user: UserInput, _ handler: ProviderResult<Any> -> ())
    
    func logout(handler: ProviderResult<Any> -> ())
    
    func facebookLogin(handler: ProviderResult<Any> -> ())
    
    func authenticateWithGoogle(token: String, _ handler: ProviderResult<Any> -> ())
    
    func sync(handler: () -> ())

}