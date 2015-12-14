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
                Providers.userProvider.login(loginData, successHandler{[weak self] in
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
    
    @IBAction func onGoogleLoginTap(sender: UIButton) {
        GIDSignIn.sharedInstance().signIn()
    }
    
    
    // MARK: GIDSignInDelegate
    
    func signIn(signIn: GIDSignIn!, didSignInForUser user: GIDGoogleUser!, withError error: NSError!) {
        if (error == nil) {
            Providers.userProvider.authenticateWithGoogle(user.authentication.accessToken, resultHandler(onSuccess: {[weak self] in
                self?.onLoginSuccess()
                
            }, onError: defaultErrorHandler([.SocialLoginCancelled])))

            
        } else {
            print("\(error.localizedDescription)")
        }
    }
    
    func signIn(signIn: GIDSignIn!, didDisconnectWithUser user: GIDGoogleUser!, withError error: NSError!) {
        // Perform any operations when the user disconnects from app here.
    }
    
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        
        if let error = error {
            print("Error: Facebook login: error: \(error)")
            defaultErrorHandler()(providerResult: ProviderResult(status: .SocialLoginError))
            progressVisible(false)
            
        } else if result.isCancelled {
            print("Facebook login cancelled")
            progressVisible(false)
            
        } else {
            
            
            print("Facebook login success, calling our server...")
            let tokenString = result.token.tokenString
            Providers.userProvider.authenticateWithFacebook(tokenString) {[weak self] providerResult in
                // map already exists status to "social aleready exists", to show a different error message
                if providerResult.status == .AlreadyExists {
                    self?.defaultErrorHandler()(providerResult: ProviderResult(status: .SocialAlreadyExists))
                } else {
                    //                handler(result)
                    self?.onLoginSuccess()
                }
                self?.progressVisible(false)
            }
        }
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        FBSDKLoginManager().logOut()
    }
}
