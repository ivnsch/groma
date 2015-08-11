//
//  LoginViewController.swift
//  shoppin
//
//  Created by ischuetz on 11/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Cocoa

protocol LoginDelegate {
    func onLoginSuccess()
    
    // LoginDelegate has register link, so the register event is forwarded to the container
    func onRegisterFromLoginSuccess()
}

class LoginViewController: NSViewController, RegisterDelegate {

    @IBOutlet weak var emailInputField: NSTextField!
    @IBOutlet weak var passwordInputField: NSTextField!

    var delegate: LoginDelegate?
    
    private let userProvider = ProviderFactory().userProvider
    
    @IBAction func loginTapped(sender: NSButton) {
        
        let email: String = self.emailInputField.stringValue
        let password: String = self.passwordInputField.stringValue
        
        guard !(email.isEmpty || password.isEmpty) else {print("TODO validation"); return}
        
        self.userProvider.login(LoginData(email: email, password: password)) {[weak self] result in
            if result.success {
                self?.delegate?.onLoginSuccess()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fillTestInput()
    }
    
    private func fillTestInput() {
        self.emailInputField.stringValue = "ivanschuetz@gmail.com"
        self.passwordInputField.stringValue = "test123Q"
    }
    
    @IBAction func registerTapped(sender: NSButton) {
        let registerViewController = NSStoryboard.registerViewController()
        registerViewController.delegate = self
        self.view.window?.contentViewController = registerViewController
    }
    
    func onRegisterSuccess() {
        self.delegate?.onRegisterFromLoginSuccess()
    }
}
