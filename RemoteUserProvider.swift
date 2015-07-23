//
//  RemoteUserProvider.swift
//  shoppin
//
//  Created by ischuetz on 22/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import Alamofire
import Valet

class RemoteUserProvider {
    
    // TODO refactor providers to return remoteresult. mapping to try and NSError seems nonsensical
    
    func login(loginData: LoginData, handler: RemoteResult<RemoteLoginResult> -> ()) {
        let parameters = [
            "email": loginData.email,
            "password": loginData.password
        ]
        Alamofire.request(.POST, Urls.login, parameters: parameters, encoding: .JSON).responseMyObject {[weak self] (request, _, remoteResult: RemoteResult<RemoteLoginResult>, error) in
            
            if let successResult = remoteResult.successResult {
                self?.storeToken(successResult.token)
                self?.storeEmail(loginData.email)
            }

            handler(remoteResult)
        }
    }
    
    
    func register(user: UserInput, handler: RemoteResult<RemoteRegisterResult> -> ()) {
        
        let parameters = self.toRequestParams(user)
        
        Alamofire.request(.POST, Urls.register, parameters: parameters, encoding: .JSON).responseMyObject {[weak self] (request, _, remoteResult: RemoteResult<RemoteRegisterResult>, error) in

            if let successResult = remoteResult.successResult {
                self?.storeToken(successResult.token)
                self?.storeEmail(user.email)
            }

            handler(remoteResult)
        }
    }
    
    private func storeToken(token: String) {
        let valet = VALValet(identifier: KeychainKeys.ValetIdentifier, accessibility: VALAccessibility.AfterFirstUnlock)
        valet?.setString(token, forKey: KeychainKeys.token)
    }
    
    private func removeToken() {
        let valet = VALValet(identifier: KeychainKeys.ValetIdentifier, accessibility: VALAccessibility.AfterFirstUnlock)
        valet?.removeObjectForKey(KeychainKeys.token)
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
    
    
    func toRequestParams(user: UserInput) -> [String: AnyObject] {
        return [
            "email": user.email,
            "firstName": user.firstName,
            "lastName": user.lastName,
            "password": user.password
        ]
    }

}
