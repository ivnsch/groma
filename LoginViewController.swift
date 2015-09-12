//
//  LoginViewController.swift
//  shoppin
//
//  Created by ischuetz on 26/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator
import FBSDKCoreKit
import FBSDKLoginKit

protocol LoginDelegate {
    func onLoginSuccess()
    
    // LoginDelegate has register link, so the register event is forwarded to the container
    func onRegisterFromLoginSuccess()
}

class LoginViewController: UIViewController, RegisterDelegate, GIDSignInUIDelegate, GIDSignInDelegate {

    let userProvider = ProviderFactory().userProvider
    
    @IBOutlet weak var userNameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    var delegate: LoginDelegate?
    
    private var validator: Validator?

    @IBOutlet weak var signInButton: GIDSignInButton!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        passwordField.secureTextEntry = true
        
        googleLoginSetup()
        
        self.navigationController?.navigationBarHidden = false
        
        self.fillTestInput()
        
        self.initValidator()
    }

    
    private func googleLoginSetup() {
        // Google sign-in
        var configureError: NSError?
        GGLContext.sharedInstance().configureWithError(&configureError)
        assert(configureError == nil, "Error configuring Google services: \(configureError)")
        GIDSignIn.sharedInstance().delegate = self
        
        GIDSignIn.sharedInstance().uiDelegate = self
        // Uncomment to automatically sign in the user.
        //GIDSignIn.sharedInstance().signInSilently()
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
                self.userProvider.login(loginData, successHandler{[weak self] in
                    self?.onLoginSuccess()
                })
                
            } else {
                print("Error: validation was not implemented correctly")
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
    
    func onLoginSuccess() {
        delegate?.onLoginSuccess() ?? print("Warn: no login delegate")
    }
    
    @IBAction func onFacebookLoginTap(sender: UIButton) {
        self.progressVisible()
        userProvider.facebookLogin(resultHandler(onSuccess: {[weak self] in
            self?.onLoginSuccess()
            
        }, onError: defaultErrorHandler([.SocialLoginCancelled])))
    }
    
    @IBAction func onGoogleLoginTap(sender: UIButton) {
        GIDSignIn.sharedInstance().signIn()
    }
    
    
    // MARK: GIDSignInDelegate
    
    func signIn(signIn: GIDSignIn!, didSignInForUser user: GIDGoogleUser!, withError error: NSError!) {
        if (error == nil) {
            userProvider.authenticateWithGoogle(user.authentication.accessToken, resultHandler(onSuccess: {[weak self] in
                self?.onLoginSuccess()
                
            }, onError: defaultErrorHandler([.SocialLoginCancelled])))

            
        } else {
            print("\(error.localizedDescription)")
        }
    }
    
    func signIn(signIn: GIDSignIn!, didDisconnectWithUser user:GIDGoogleUser!, withError error: NSError!) {
        // Perform any operations when the user disconnects from app here.
    }
}
