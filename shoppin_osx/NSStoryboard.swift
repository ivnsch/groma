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
    
    class func mainViewController() -> ViewController {
        return self.mainStoryboard().instantiateControllerWithIdentifier("MainViewController") as! ViewController
    }

    class func loginViewController() -> LoginViewController {
        return self.signupStoryboard().instantiateControllerWithIdentifier("LoginViewController") as! LoginViewController
    }
    
    class func registerViewController() -> RegisterViewController {
        return self.signupStoryboard().instantiateControllerWithIdentifier("RegisterViewController") as! RegisterViewController
    }
}
