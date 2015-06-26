//
//  RegisterViewController.swift
//  shoppin
//
//  Created by ischuetz on 26/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit


protocol RegisterDelegate {
    func onRegisterSuccess()
    func onRegisterError()
}

class RegisterViewController: UIViewController {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var firstNameField: UITextField!
    @IBOutlet weak var lastNameField: UITextField!
    
    let userProvider = ProviderFactory().userProvider
    
    var delegate: RegisterDelegate?

    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBarHidden = false
    }

    @IBAction func onRegisterTap(sender: UIButton) {
        
        let user = User(email: emailField.text, password: passwordField.text, firstName: firstNameField.text, lastName: lastNameField.text)
        
        self.userProvider.register(user, handler: {try in
            
            if try.success ?? false {
                self.delegate?.onRegisterSuccess() ?? println("Warn: no register delegate")
                
            } else {
                self.delegate?.onRegisterError() ?? println("Warn: no register delegate")
            }
        })
    }
}
