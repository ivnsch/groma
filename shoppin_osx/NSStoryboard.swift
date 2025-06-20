//
//  NSStoryboard.swift
//  shoppin
//
//  Created by ischuetz on 11/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Cocoa

extension NSStoryboard {

    private class func mainStoryboard() -> NSStoryboard { return NSStoryboard(name: "Main", bundle: NSBundle.mainBundle()) }
    private class func signupStoryboard() -> NSStoryboard { return NSStoryboard(name: "LoginRegister", bundle: NSBundle.mainBundle()) }
    private class func userDetailsStoryboard() -> NSStoryboard { return NSStoryboard(name: "UserDetails", bundle: NSBundle.mainBundle()) }
    
    class func tabViewController() -> NSTabViewController {
        return self.mainStoryboard().instantiateControllerWithIdentifier("TabViewController") as! NSTabViewController
    }

    class func loginViewController() -> LoginViewController {
        return self.signupStoryboard().instantiateControllerWithIdentifier("LoginViewController") as! LoginViewController
    }
    
    class func registerViewController() -> RegisterViewController {
        return self.signupStoryboard().instantiateControllerWithIdentifier("RegisterViewController") as! RegisterViewController
    }
    
    class func userDetailsViewController() -> UserDetailsViewController {
        return self.userDetailsStoryboard().instantiateControllerWithIdentifier("UserDetailsViewController") as! UserDetailsViewController
    }
}
