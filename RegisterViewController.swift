//
//  RegisterViewController.swift
//  shoppin
//
//  Created by ischuetz on 26/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator

protocol RegisterDelegate {
    func onRegisterSuccess()
}

class RegisterViewController: UIViewController {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var firstNameField: UITextField!
    @IBOutlet weak var lastNameField: UITextField!
    
    let userProvider = ProviderFactory().userProvider
    
    var delegate: RegisterDelegate?

    private var validator: Validator?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBarHidden = false
        
        fillTestInput()
        
        initValidator()
    }
    
    private func initValidator() {
        let validator = Validator()
        validator.registerField(self.emailField, rules: [EmailRule(message: "validation_email_format")])
        validator.registerField(self.passwordField, rules: [PasswordRule(message: "password: 8 letter, 1 uppercase, 1 number")]) // TODO repl with translation key, for now this so testers understand
        validator.registerField(self.firstNameField, rules: [MinLengthRule(length: 1, message: "validation_first_name_min_length")]) // TODO repl with translation key, for now this so testers understand
        validator.registerField(self.lastNameField, rules: [MinLengthRule(length: 1, message: "validation_last_name_min_length")]) // TODO repl with translation key, for now this so testers understand
        self.validator = validator
    }
    
    private func fillTestInput() {
        emailField.text = "ivanschuetz@gmail.com"
        firstNameField.text = "Ivan"
        lastNameField.text = "Schuetz"
        passwordField.text = "test123Q"
    }


    @IBAction func onRegisterTap(sender: UIButton) {
        
        guard self.validator != nil else {return}
        
        if let errors = self.validator?.validate() {
            for (field, _) in errors {
                field.showValidationError()
            }
            self.presentViewController(ValidationAlertCreator.create(errors), animated: true, completion: nil)
            
        } else {
            
            if let email = emailField.text, password = passwordField.text, firstName = firstNameField.text, lastName = lastNameField.text {
                
                let user = UserInput(email: email, password: password, firstName: firstName, lastName: lastName)
                
                self.progressVisible()
                self.userProvider.register(user, successHandler{result in
                    self.delegate?.onRegisterSuccess() ?? print("Warn: no register delegate")
                })
                
            } else {
                print("Error: validation was not implemented correctly")
            }
        }
    }
}
