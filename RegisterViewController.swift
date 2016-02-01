//
//  RegisterViewController.swift
//  shoppin
//
//  Created by ischuetz on 26/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator
import FBSDKCoreKit
import FBSDKLoginKit

protocol RegisterDelegate {
    func onRegisterSuccess()
}

class RegisterViewController: UIViewController, GIDSignInUIDelegate, GIDSignInDelegate, FBSDKLoginButtonDelegate {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var firstNameField: UITextField!
    @IBOutlet weak var lastNameField: UITextField!
    
    @IBOutlet weak var termsButton: UIButton!
    
    let userProvider = ProviderFactory().userProvider
    
    var delegate: RegisterDelegate?

    private var validator: Validator?

    private var acceptedTerms: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBarHidden = false
        
        passwordField.secureTextEntry = true

        googleLoginSetup()

        fillTestInput()
        
        initValidator()
        
        let buttonTranslation = "I accept the %%terms and conditions%%" // TODO translations
        let attributedText = buttonTranslation.underlineBetweenFirstSeparators("%%")
        attributedText.setTextColor(UIColor.blackColor())
        termsButton.setAttributedTitle(attributedText, forState: .Normal)
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
    
    @IBAction func onShowPasswordChanged(sender: UISwitch) {
        passwordField.secureTextEntry = !sender.on
    }

    @IBAction func onAcceptTermsChanged(sender: UISwitch) {
        acceptedTerms = sender.on
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
            
            if !acceptedTerms {
                AlertPopup.show(message: "Please accept the terms and conditions", controller: self)
                
            } else {
                if let email = emailField.text, password = passwordField.text, firstName = firstNameField.text, lastName = lastNameField.text {
                    
                    let user = UserInput(email: email, password: password, firstName: firstName, lastName: lastName)
                    
                    self.progressVisible()
                    self.userProvider.register(user, successHandler{[weak self] result in
                        self?.onRegisterSuccess()
                    })
                    
                } else {
                    print("Error: validation was not implemented correctly")
                }
            }
        }
    }
    
    // TODO refactor, same code as in LoginController
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {        
        if let error = error {
            print("Error: Facebook login: error: \(error)")
            defaultErrorHandler()(providerResult: ProviderResult(status: .SocialLoginError))
            progressVisible(false)
            FBSDKLoginManager().logOut() // toggle "logout" label on button
        } else if result.isCancelled {
            print("Facebook login cancelled")
            progressVisible(false)
            FBSDKLoginManager().logOut() // toggle "logout" label on button
        } else {
            print("Facebook login success, calling our server...")
            let tokenString = result.token.tokenString
            Providers.userProvider.authenticateWithFacebook(tokenString) {[weak self] providerResult in
                // map already exists status to "social aleready exists", to show a different error message
                if providerResult.status == .AlreadyExists {
                    self?.defaultErrorHandler()(providerResult: ProviderResult(status: .SocialAlreadyExists))
                } else {
                    //                handler(result)
                    self?.onRegisterSuccess()
                }
                self?.progressVisible(false)
            }
        }
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        FBSDKLoginManager().logOut()
    }
    
    private func onRegisterSuccess() {
        self.delegate?.onRegisterSuccess() ?? print("Warn: no register delegate")
    }
    
    // MARK: GIDSignInDelegate
    
    func signIn(signIn: GIDSignIn!, didSignInForUser user: GIDGoogleUser!, withError error: NSError!) {
        if (error == nil) {
            userProvider.authenticateWithGoogle(user.authentication.accessToken, resultHandler(onSuccess: {[weak self] in
                self?.onRegisterSuccess()
                
                }, onError: defaultErrorHandler([.SocialLoginCancelled])))
            
        } else {
            print("\(error.localizedDescription)")
        }
    }
    
    func signIn(signIn: GIDSignIn!, didDisconnectWithUser user: GIDGoogleUser!, withError error: NSError!) {
        // Perform any operations when the user disconnects from app here.
    }
}
