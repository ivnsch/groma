//
//  UserProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 26/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

class UserProviderImpl: UserProvider {
   
    let remoteProvider = RemoteUserProvider()
    
    func login(loginData: LoginData, handler: Try<Bool> -> ()) {
        self.remoteProvider.login(loginData, handler: handler)
    }
    
    func register(user: User, handler: Try<Bool> -> ()) {
        self.remoteProvider.register(user, handler: handler)
    }
    
    func logout(handler: Try<Bool> -> ()) {
        self.remoteProvider.logout(handler)
    }
}
