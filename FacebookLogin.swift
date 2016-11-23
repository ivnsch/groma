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

/**
* Helper class to use Facebook login service
* Facebook SDK is only for iOS, which is why this is not in a generic provider.
*/
class FacebookLogin {
    
    static func login(_ controller: UIViewController, handler: @escaping (ProviderResult<SyncResult>) -> ()) {
        let login = FBSDKLoginManager()
        login.logIn(withReadPermissions: ["public_profile"]) {result, error in
            if let error = error {
                print("Error: Facebook login: error: \(error)")
                handler(ProviderResult(status: .socialLoginError))
                
            } else if let result = result {
                if result.isCancelled {
                    print("Facebook login cancelled")
                    handler(ProviderResult(status: .socialLoginCancelled))
                    
                } else {
                    print("Facebook login success, calling our server...")
                    if let tokenString = result.token.tokenString {
                        Providers.userProvider.authenticateWithFacebook(tokenString, controller: controller) {result in
                            
                            // map already exists status to "social aleready exists", to show a different error message
                            if result.status == .alreadyExists {
                                handler(ProviderResult(status: .socialAlreadyExists))
                            } else {
                                handler(result)
                            }
                        }
                    } else {
                        print("Facebook no token")
                        handler(ProviderResult(status: .socialLoginError))
                    }
                    
                }
            } else {
                print("No result")
            }
        }
    }
}
