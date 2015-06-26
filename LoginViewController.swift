//
//  LoginViewController.swift
//  shoppin
//
//  Created by ischuetz on 26/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {

    let userProvider = ProviderFactory().userProvider
    
    @IBOutlet weak var userNameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    var onLoginSuccess: (() -> ())?
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBarHidden = false
    }

    @IBAction func loginTapped(sender: AnyObject) {
        
        let email = userNameField.text
        let password = passwordField.text
        
        let loginData = LoginData(email: email, password: password)
        
        self.userProvider.login(loginData, handler: {try in
            if try.success ?? false {
                self.onLoginSuccess?() ?? println("Warn: no login success block")
                
            } else {
                // show login error
            }
        })
    }
}
