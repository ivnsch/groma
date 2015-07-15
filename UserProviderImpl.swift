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
    
    func login(loginData: LoginData, _ handler: ProviderResult<Any> -> ()) {
        self.remoteProvider.login(loginData, handler: {result in
            let providerStatus = DefaultRemoteResultMapper.toProviderStatus(result.status) // status here should be always success
            handler(ProviderResult(status: providerStatus))
        })
    }
    
    func register(user: UserInput, _ handler: ProviderResult<Any> -> ()) {
        self.remoteProvider.register(user, handler: remoteResultHandler(handler))
    }
    
    func logout(handler: ProviderResult<Any> -> ()) {
        self.remoteProvider.logout(remoteResultHandler(handler))
    }
}
