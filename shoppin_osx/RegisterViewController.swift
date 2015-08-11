//
//  RegisterViewController.swift
//  shoppin
//
//  Created by ischuetz on 11/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Cocoa

protocol RegisterDelegate {
    func onRegisterSuccess()
}

class RegisterViewController: NSViewController {

    @IBOutlet weak var emailInputField: NSTextField!
    @IBOutlet weak var passwordInputField: NSTextField!
    @IBOutlet weak var firstNameInputField: NSTextField!
    @IBOutlet weak var lastNameInputField: NSTextField!
    
    var delegate: RegisterDelegate?
    
    let userProvider = ProviderFactory().userProvider
    
    @IBAction func registerTapped(sender: NSButton) {
        let email: String = self.emailInputField.stringValue
        let password: String = self.passwordInputField.stringValue
        let firstName: String = self.firstNameInputField.stringValue
        let lastName: String = self.lastNameInputField.stringValue
        
        guard !(email.isEmpty || password.isEmpty || firstName.isEmpty || lastName.isEmpty) else {print("TODO validation"); return}
        
        let registerData = UserInput(email: email, password: password, firstName: firstName, lastName: lastName)
        
        self.userProvider.register(registerData) {[weak self] result in
            if result.success {
                self?.delegate?.onRegisterSuccess()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fillTestInput()
    }
    
    private func fillTestInput() {
        self.emailInputField.stringValue = "ivanschuetz@gmail.com"
        self.firstNameInputField.stringValue = "Ivan"
        self.lastNameInputField.stringValue = "Schuetz"
        self.passwordInputField.stringValue = "test123Q"
    }
    
    @IBAction func loginTapped(sender: NSButton) {
        self.view.window?.contentViewController = NSStoryboard.loginViewController()
    }
}
