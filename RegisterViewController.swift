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
        
        fillTestInput()
    }
    
    private func fillTestInput() {
        emailField.text = "ivanschuetz@gmail.com"
        firstNameField.text = "Ivan"
        lastNameField.text = "Schuetz"
        passwordField.text = "test123"
    }


    @IBAction func onRegisterTap(sender: UIButton) {
        
        if let email = emailField.text, password = passwordField.text, firstName = firstNameField.text, lastName = lastNameField.text {
            
            let user = UserInput(email: email, password: password, firstName: firstName, lastName: lastName)
            
            self.progressVisible()
            self.userProvider.register(user, resultHandler(onSuccess: {result in
                self.delegate?.onRegisterSuccess() ?? print("Warn: no register delegate")
                
                }, onError: {
                    self.delegate?.onRegisterError() ?? print("Warn: no register delegate")
            }))
            
        } else {
            print("TODO onRegisterTap, validation")
        }
    }
}
