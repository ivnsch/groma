//
//  RemoteUserProvider.swift
//  shoppin
//
//  Created by ischuetz on 22/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation


class RemoteUserProvider {
    
    // TODO refactor providers to return remoteresult. mapping to try and NSError seems nonsensical
    
    func login(_ loginData: LoginData, handler: @escaping (RemoteResult<RemoteLoginResult>) -> ()) {
        let parameters: [String: AnyObject] = [
            "email": loginData.email as AnyObject,
            "password": loginData.password as AnyObject
        ]
        RemoteProvider.request(.post, Urls.login, parameters) {[weak self] (result: RemoteResult<RemoteLoginResult>) in
            if let successResult = result.successResult {
                self?.storeToken(successResult.token)
            } else {
                if result.status != .invalidCredentials {
                    logger.e("No token. Result: \(result)")
                }
            }
            handler(result)
        }
    }
    
    func register(_ user: UserInput, handler: @escaping (RemoteResult<NoOpSerializable>) -> ()) {
        
        let parameters = self.toRequestParams(user)
        
        RemoteProvider.request(.post, Urls.register, parameters) {(result: RemoteResult<NoOpSerializable>) in
            if result.success {

            } else {
                logger.e("Error registering. Result: \(result)")
            }
            handler(result)
        }
    }
    
    func ping(_ handler: @escaping (RemoteResult<RemotePingResult>) -> ()) {
        RemoteProvider.authenticatedRequest(.get, Urls.ping) {(result: RemoteResult<RemotePingResult>) in
            if result.success {
                if let successResult = result.successResult {
                    AccessTokenHelper.storeToken(successResult.token) // update (replace) the token
                } else {
                    logger.e("No token. Result: \(result)")
                }
                handler(result)
            }
            handler(result)
        }
    }
    
    func isRegistered(_ email: String, handler: @escaping (RemoteResult<NoOpSerializable>) -> ()) {
        RemoteProvider.authenticatedRequest(.post, Urls.isRegistered + "/\(email)") {(result: RemoteResult<NoOpSerializable>) in
            handler(result)
        }
    }
    
    func forgotPassword(_ email: String, handler: @escaping (RemoteResult<NoOpSerializable>) -> ()) {
        let parameters: [String: AnyObject] = ["email": email as AnyObject, "foo": "" as AnyObject] // foo is a filler parameter bc of a bug in the server
        RemoteProvider.request(.post, Urls.forgotPassword, parameters) {result in
            handler(result)
        }
    }
    
    func removeAccount(_ handler: @escaping (RemoteResult<NoOpSerializable>) -> ()) {
        RemoteProvider.authenticatedRequest(.delete, Urls.removeAccount) {(result: RemoteResult<NoOpSerializable>) in
            if result.success {
                AccessTokenHelper.removeToken()
            }
            handler(result)
        }
    }
    
    func findAllKnownSharedUsers(_ handler: @escaping (RemoteResult<[RemoteSharedUser]>) -> Void) {
        RemoteProvider.authenticatedRequestArray(.get, Urls.allKnownSharedUsers) {(result: RemoteResult<[RemoteSharedUser]>) in
            handler(result)
        }
    }
    
    func logout(_ handler: (RemoteResult<NoOpSerializable>) -> ()) {
        // with JWT we just have to remove token from client no need to call the server TODO verify this
        AccessTokenHelper.removeToken()
        handler(RemoteResult<NoOpSerializable>(status: .success))
    }
    
    func authenticateWithFacebook(_ token: String, handler: @escaping (RemoteResult<RemoteSocialLoginResult>) -> ()) {
        let parameters: [String: AnyObject] = ["access_token": token as AnyObject]
        RemoteProvider.request(.post, Urls.authFacebook, parameters) {[weak self] (result: RemoteResult<RemoteSocialLoginResult>) in
            if let successResult = result.successResult {
                self?.storeToken(successResult.token)
            }
            handler(result)
        }
    }

    func authenticateWithGoogle(_ token: String, handler: @escaping (RemoteResult<RemoteSocialLoginResult>) -> ()) {
        let parameters: [String: AnyObject] = ["access_token": token as AnyObject]
        RemoteProvider.request(.post, Urls.authGoogle, parameters) {[weak self] (result: RemoteResult<RemoteSocialLoginResult>) in
            if let successResult = result.successResult {
                self?.storeToken(successResult.token)
            }
            handler(result)
        }
    }
    
    fileprivate func storeToken(_ token: String) {
        AccessTokenHelper.storeToken(token)
    }
    
    func toRequestParams(_ user: UserInput) -> [String: AnyObject] {
        return [
            "email": user.email as AnyObject,
            "firstName": user.firstName as AnyObject,
            "lastName": user.lastName as AnyObject,
            "password": user.password as AnyObject
        ]
    }

}
