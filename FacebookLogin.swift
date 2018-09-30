//
//  FacebookLogin.swift
//  shoppin
//
//  Created by ischuetz on 25/09/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit

import Providers

/**
* Helper class to use Facebook login service
* Facebook SDK is only for iOS, which is why this is not in a generic provider.
*/
class FacebookLogin {
    
    static func authenticate(_ controller: UIViewController, handler: @escaping (ProviderResult<String>) -> ()) {
        let login = FBSDKLoginManager()
        
        login.logIn(withReadPermissions: ["public_profile"], from: controller) {result, error in
            if let error = error {
                logger.e("Error: Facebook login: error: \(error)")
                handler(ProviderResult(status: .socialLoginError))
                
            } else if let result = result {
                if result.isCancelled {
                    logger.d("Facebook login cancelled")
                    handler(ProviderResult(status: .socialLoginCancelled))
                    
                } else {
                    logger.v("Facebook login success")
                    if let tokenString = result.token.tokenString {
                        handler(ProviderResult(status: .success, sucessResult: tokenString))
                        
                    } else {
                        logger.e("Facebook no token")
                        handler(ProviderResult(status: .socialLoginError))
                    }
                }
            } else {
                logger.e("No result")
            }
        }
    }
    
    /// Authenticates to FB and logs in to server
    static func login(_ controller: UIViewController, handler: @escaping (ProviderResult<SyncResult>) -> ()) {
        authenticate(controller) {result in
            if let tokenString = result.sucessResult {
                Prov.userProvider.authenticateWithFacebook(tokenString) {result in
                    // map already exists status to "social aleready exists", to show a different error message
                    if result.status == .alreadyExists {
                        handler(ProviderResult(status: .socialAlreadyExists))
                    } else {
                        handler(result)
                    }
                }
            } else {
                handler(ProviderResult(status: result.status))
            }
        }
    }
}
