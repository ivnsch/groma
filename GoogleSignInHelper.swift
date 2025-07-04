//
//  GoogleSignInHelper.swift
//  shoppin
//
//  Created by ischuetz on 03/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import Providers
import GoogleSignIn

struct GoogleSignInHelper {

    static func configure(uiDelegate: GIDSignInUIDelegate, delegate: GIDSignInDelegate) {
        // Google sign-in
//        var configureError: NSError?

        // From GoogleService-Info.plist
        GIDSignIn.sharedInstance().clientID = "1092160392759-bcm55vcn1e11agl7s03qeo901im11sk1.apps.googleusercontent.com"

        GIDSignIn.sharedInstance().delegate = delegate
        
        // So far research these are the current scopes https://developers.google.com/+/web/api/rest/oauth

        // According to the documentation this should work, but it doesn't. It shows "have offline access" and a blue buttom
        //        GIDSignIn.sharedInstance().scopes = ["profile"]
        //        GIDSignIn.sharedInstance().scopes = ["email"]
        // This also doesn't make a difference
        //        GIDSignIn.sharedInstance().shouldFetchBasicProfile = true
        
        // This works but requires a lot of permissions, see link above
//        GIDSignIn.sharedInstance().scopes = ["https://www.googleapis.com/auth/plus.login"]
        // This works and the permissions are ok, though we should try to use "profile" instead
        GIDSignIn.sharedInstance().scopes = ["https://www.googleapis.com/auth/plus.profile.emails.read"]
        
        // Note: the deprecated scopes from link above also doesn't seem to work anymore, also get "have offline access" and a blue buttom

        GIDSignIn.sharedInstance().uiDelegate = uiDelegate
        // Uncomment to automatically sign in the user.
//        GIDSignIn.sharedInstance().signInSilently()
    }
}
