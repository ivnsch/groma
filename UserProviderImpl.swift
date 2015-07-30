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
    
    private func sync(handler: () -> ()) {
        // TODO create 1 privider service to sync everything, call it here
        handler()
    }
}
