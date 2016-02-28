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
import QorumLogs

protocol LoginDelegate {
    func onLoginSuccess()
    
    // LoginDelegate has register link, so the register event is forwarded to the container
    func onRegisterFromLoginSuccess()
}

class LoginViewController: UIViewController, RegisterDelegate, ForgotPasswordDelegate, GIDSignInUIDelegate, GIDSignInDelegate, FBSDKLoginButtonDelegate {

    @IBOutlet weak var userNameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    @IBOutlet weak var fbButton: FBSDKLoginButton!

    var delegate: LoginDelegate?
    
    private var validator: Validator?

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
        
        fbButton.readPermissions = ["public_profile"]
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
        validator.registerField(self.passwordField, rules: [RequiredRule(message: "validation_pw_required")]) // TODO repl with translation key, for now this so testers understand
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
                Providers.userProvider.login(loginData, successHandler{[weak self] syncResult in
                    if let weakSelf = self {
                        InvitationsHandler.handleInvitations(syncResult.listInvites, inventoryInvitations: syncResult.inventoryInvites, controller: weakSelf)
                    }
                    self?.onLoginSuccess()
                })
                
            } else {
                print("Error: validation was not implemented correctly")
            }
        }
    }
    
    @IBAction func onForgotPasswordTap(sender: UIButton) {
        let forgotPasswordViewController = UIStoryboard.forgotPasswordViewController()
        forgotPasswordViewController.delegate = self
        forgotPasswordViewController.email = userNameField.text
        self.navigationController?.pushViewController(forgotPasswordViewController, animated: true)
    }
    
    @IBAction func onRegisterTap(sender: UIButton) {
        let registerController = UIStoryboard.registerViewController()
        registerController.delegate = self
        self.navigationController?.pushViewController(registerController, animated: true)
    }
    
    func onRegisterSuccess() {
        self.delegate?.onRegisterFromLoginSuccess() ?? print("Warn: no login delegate")
    }
    
    // MARK: ForgotPasswordDelegate
    
    func onForgotPasswordSuccess() {
        showInfoAlert(message: "An email to reset your password was sent")
    }
    
    // MARK:
    
    func onLoginSuccess() {
        delegate?.onLoginSuccess() ?? print("Warn: no login delegate")
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
}
