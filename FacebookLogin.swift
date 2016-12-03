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
import QorumLogs

/**
* Helper class to use Facebook login service
* Facebook SDK is only for iOS, which is why this is not in a generic provider.
*/
class FacebookLogin {
    
    static func authenticate(_ controller: UIViewController, handler: @escaping (ProviderResult<String>) -> ()) {
        let login = FBSDKLoginManager()
        login.logIn(withReadPermissions: ["public_profile"]) {result, error in
            if let error = error {
                QL4("Error: Facebook login: error: \(error)")
                handler(ProviderResult(status: .socialLoginError))
                
            } else if let result = result {
                if result.isCancelled {
                    QL2("Facebook login cancelled")
                    handler(ProviderResult(status: .socialLoginCancelled))
                    
                } else {
                    QL1("Facebook login success")
                    if let tokenString = result.token.tokenString {
                        handler(ProviderResult(status: .success, sucessResult: tokenString))
                        
                    } else {
                        QL4("Facebook no token")
                        handler(ProviderResult(status: .socialLoginError))
                    }
                }
            } else {
                QL4("No result")
            }
        }
    }
    
    /// Authenticates to FB and logs in to server
    static func login(_ controller: UIViewController, handler: @escaping (ProviderResult<SyncResult>) -> ()) {
        authenticate(controller) {result in
            if let tokenString = result.sucessResult {
                Providers.userProvider.authenticateWithFacebook(tokenString, controller: controller) {result in
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
