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
import QorumLogs

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
                    Providers.userProvider.register(user, successHandler{[weak self] syncResult in
                        if let weakSelf = self {
                            InvitationsHandler.handleInvitations(syncResult.listInvites, inventoryInvitations: syncResult.inventoryInvites, controller: weakSelf)
                        }
                        self?.onRegisterSuccess()
                    })
                    
                } else {
                    QL4("Validation was not implemented correctly")
                }
            }
        }
    }
    
    // TODO refactor, same code as in LoginController
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {        
        if let error = error {
            QL4("Facebook login error: \(error)")
            defaultErrorHandler()(providerResult: ProviderResult(status: .SocialLoginError))
            progressVisible(false)
            FBSDKLoginManager().logOut() // toggle "logout" label on button
        } else if result.isCancelled {
            QL1("Facebook login cancelled")
            progressVisible(false)
            FBSDKLoginManager().logOut() // toggle "logout" label on button
        } else {
            QL1("Facebook login success, calling our server...")
            progressVisible()
            let tokenString = result.token.tokenString
            Providers.userProvider.authenticateWithFacebook(tokenString, socialSignInResultHandler())
        }
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        FBSDKLoginManager().logOut()
    }
    
    // MARK: GIDSignInDelegate
    
    func signIn(signIn: GIDSignIn!, didSignInForUser user: GIDGoogleUser!, withError error: NSError!) {
        if (error == nil) {
            QL1("Google login success, calling our server...")
            progressVisible()
            Providers.userProvider.authenticateWithGoogle(user.authentication.accessToken, socialSignInResultHandler())
        } else {
            QL4("Google login error: \(error.localizedDescription)")
        }
    }
    
    func signIn(signIn: GIDSignIn!, didDisconnectWithUser user: GIDGoogleUser!, withError error: NSError!) {
        // Perform any operations when the user disconnects from app here.
    }
    
    func signIn(signIn: GIDSignIn!, presentViewController viewController: UIViewController!) {
        
    }
    
    func signIn(signIn: GIDSignIn!, dismissViewController viewController: UIViewController!) {
        
    }
    
    func signInWillDispatch(signIn: GIDSignIn!, error: NSError!) {

    }
    
    // Common FB/Google handling for social login/register result of our own server
    private func socialSignInResultHandler()(providerResult: ProviderResult<SyncResult>) {
        resultHandler(
            onSuccess: {[weak self] syncResult in
                QL1("Login success")
                self?.onRegisterSuccess()
                self?.progressVisible(false)
                
                if let weakSelf = self {
                    InvitationsHandler.handleInvitations(syncResult.listInvites, inventoryInvitations: syncResult.inventoryInvites, controller: weakSelf)
                }
            }, onError: {[weak self] providerResult in
                QL1("Login error: \(providerResult)")
                self?.progressVisible(false)
                self?.defaultErrorHandler()(providerResult: providerResult)
                if let weakSelf = self {
                    Providers.userProvider.logout(weakSelf.successHandler{}) // ensure everything cleared, buttons text resetted etc. Note this is also triggered by sync error (which is called directly after login)
                }
            })(providerResult: providerResult)
    }

    private func onRegisterSuccess() {
        self.delegate?.onRegisterSuccess() ?? print("Warn: no register delegate")
    }
}
