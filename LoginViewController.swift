//
//  LoginViewController.swift
//  shoppin
//
//  Created by ischuetz on 26/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator

protocol LoginDelegate {
    func onLoginSuccess()
    func onLoginError()
    
    // LoginDelegate has register link, so the register event is forwarded to the container
    func onRegisterFromLoginSuccess()
    func onRegisterFromLoginError()
}

class LoginViewController: UIViewController, RegisterDelegate {

    let userProvider = ProviderFactory().userProvider
    
    @IBOutlet weak var userNameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    var delegate: LoginDelegate?
    
    private var validator: Validator?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBarHidden = false
        
        self.fillTestInput()
        
        self.initValidator()
    }

    private func initValidator() {
        let validator = Validator()
        validator.registerField(self.userNameField, rules: [EmailRule(message: "validation_email_format")])
        validator.registerField(self.passwordField, rules: [PasswordRule(message: "password: 8 letter, 1 uppercase, 1 number")]) // TODO repl with translation key, for now this so testers understand
        self.validator = validator
    }
    
    private func fillTestInput() {
        userNameField.text = "ivanschuetz@gmail.com"
        passwordField.text = "test123Q"
    }
    
    @IBAction func loginTapped(sender: AnyObject) {

        guard self.validator != nil else {return}

        if let errors = self.validator?.validate() {
            for (field, _) in errors {
                field.showValidationError()
            }
            self.presentViewController(ValidationAlertCreator.create(errors), animated: true, completion: nil)
            
        } else {
            if let email = userNameField.text, password = passwordField.text {
                let loginData = LoginData(email: email, password: password)
                
                self.progressVisible()
                self.userProvider.login(loginData, successHandler{result in
                    self.delegate?.onLoginSuccess() ?? print("Warn: no login delegate")
                    })
                
            } else {
                print("TODO loginTapped, validation")
            }
        }
    }
    
    @IBAction func onRegisterTap(sender: UIButton) {
        let registerController = UIStoryboard.registerViewController()
        registerController.delegate = self
        self.navigationController?.pushViewController(registerController, animated: true)
    }
    
    func onRegisterSuccess() {
        self.delegate?.onRegisterFromLoginSuccess() ?? print("Warn: no login delegate")
    }
    
    func onRegisterError() {
        self.delegate?.onRegisterFromLoginError() ?? print("Warn: no login delegate")
    }
}
