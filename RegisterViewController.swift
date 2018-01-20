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
import GoogleSignIn
import Providers

protocol RegisterDelegate: class {
    func onRegisterSuccess(_ email: String)
    
    // can be login or register
    func onSocialSignupInRegisterScreenSuccess()
    
    func onLoginFromRegisterSuccess()
}

class RegisterViewController: UIViewController, GIDSignInUIDelegate, GIDSignInDelegate, FBSDKLoginButtonDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate, EyeViewDelegate, LoginDelegate {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
//    @IBOutlet weak var firstNameField: UITextField!
//    @IBOutlet weak var lastNameField: UITextField!
    
    @IBOutlet weak var regButton: UIButton!
    
    @IBOutlet weak var termsButton: UIButton!
    
    @IBOutlet weak var fbButton: FBSDKLoginButton!

    @IBOutlet weak var eyeView: EyeView!
    
    weak var delegate: RegisterDelegate?

    fileprivate var validator: Validator?

    fileprivate var acceptedTerms: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = trans("title_register")

        navigationController?.isNavigationBarHidden = false
        
        passwordField.isSecureTextEntry = true

        GoogleSignInHelper.configure(uiDelegate: self, delegate: self)

        fillTestInput()
        
        initValidator()
        
        staticLayout()
        
        eyeView.delegate = self
        
        fbButton.readPermissions = ["public_profile"]
        
        let buttonTranslation = trans("register_accept_terms")
        let attributedText = buttonTranslation.underlineBetweenFirstSeparators("%%")
        termsButton.setAttributedTitle(attributedText, for: UIControlState())
        
        let recognizer = UITapGestureRecognizer(target: self, action:#selector(RegisterViewController.handleTap(_:)))
        recognizer.delegate = self
        view.addGestureRecognizer(recognizer)
    }
    
    fileprivate func staticLayout() {
        regButton.layer.cornerRadius = DimensionsManager.userDetailsLogoutButtonRadius
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        emailField.becomeFirstResponder()
    }
    
    @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
        view.endEditing(true)
    }

    @IBAction func onAcceptTermsChanged(_ sender: UISwitch) {
        acceptedTerms = sender.isOn
    }
    
    fileprivate func initValidator() {
        let validator = Validator()
//        validator.registerField(self.emailField, rules: [EmailRule(message: "validation_email_format")])
//        validator.registerField(self.passwordField, rules: [PasswordRule(message: "validation_password_characters")]) // TODO repl with translation key, for now this so testers understand
        
//        validator.registerField(self.firstNameField, rules: [MinLengthRule(length: 1, message: "validation_first_name_min_length")]) // TODO repl with translation key, for now this so testers understand
//        validator.registerField(self.lastNameField, rules: [MinLengthRule(length: 1, message: "validation_last_name_min_length")]) // TODO repl with translation key, for now this so testers understand
        self.validator = validator
    }
    
    fileprivate func fillTestInput() {
        emailField.text = "test"
        passwordField.text = "test"
//        emailField.text = "ivanschuetz@gmail.com"
//        passwordField.text = "test123Q"
//        firstNameField.text = "Ivan"
//        lastNameField.text = "Schuetz"
    }

    @IBAction func onRegisterTap(_ sender: UIButton) {
        register()
    }
    
//    @IBAction func onLoginTap(_ sender: UIButton) {
//        let loginController = UIStoryboard.loginViewController()
//        loginController.delegate = self
//        loginController.onUIReady = {
//            loginController.mode = .normal
//        }
//        
//        navigationController?.pushViewController(loginController, animated: true)
//    }
    
    // MARK: LoginDelegate
    
    func onLoginSuccess() {
        _ = navigationController?.popViewController(animated: true)
        self.delegate?.onLoginFromRegisterSuccess()
    }
    
    func onRegisterFromLoginSuccess() {
        // TODO delete register link from login screen, since we now use register first
    }
    
    // MARK: -
    
    fileprivate func register() {
        
        guard self.validator != nil else {return}
        
        if let errors = self.validator?.validate() {
            for (_, error) in errors {
                error.field.showValidationError()
            }
            present(ValidationAlertCreator.create(errors), animated: true, completion: nil)
            
        } else {
            
            if !acceptedTerms {
                MyPopupHelper.showPopup(parent: self, type: .info, message: trans("popup_please_accept_terms"), centerYOffset: -80)

            } else {
                if let email = emailField.text, let password = passwordField.text/*, firstName = firstNameField.text, lastName = lastNameField.text*/ {
                    
                    let user = UserInput(email: email, password: password, firstName: "", lastName: "")
                    
                    self.progressVisible()
                    Prov.userProvider.register(user, controller: self, successHandler{[weak self] in
                        self?.delegate?.onRegisterSuccess(email)
                    })
                    
                } else {
                    logger.e("Validation was not implemented correctly")
                }
            }
        }
    }
    
    func textFieldShouldReturn(_ sender: UITextField) -> Bool {
        
        if sender == passwordField {
            register()
            sender.resignFirstResponder()
        } else {
            let textFields: [UITextField] = [emailField, passwordField/*, firstNameField, lastNameField*/]

            if let index = textFields.index(of: sender) {
                if let next = textFields[safe: index + 1] {
                    next.becomeFirstResponder()
                }
            }
        }
        
        return false
    }
    
    // TODO refactor, same code as in LoginController
    public func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if let error = error {
            logger.e("Facebook login error: \(error)")
            defaultErrorHandler()(ProviderResult(status: .socialLoginError))
            progressVisible(false)
            FBSDKLoginManager().logOut() // toggle "logout" label on button
        } else if result.isCancelled {
            logger.v("Facebook login cancelled")
            progressVisible(false)
            FBSDKLoginManager().logOut() // toggle "logout" label on button
        } else {
            logger.v("Facebook login success, calling our server...")
            progressVisible()
            if let tokenString = result.token.tokenString {
                Prov.userProvider.authenticateWithFacebook(tokenString, controller: self, socialSignInResultHandler())
            } else {
                logger.e("Facebook: No token")
            }
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        FBSDKLoginManager().logOut()
    }
    
    // MARK: GIDSignInDelegate
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if (error == nil) {
            logger.v("Google login success, calling our server...")
            progressVisible()
            Prov.userProvider.authenticateWithGoogle(user.authentication.accessToken, controller: self, socialSignInResultHandler())
        } else {
            logger.e("Google login error: \(error.localizedDescription)")
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
    }
    
    func sign(_ signIn: GIDSignIn!, present viewController: UIViewController!) {
        present(viewController, animated: true, completion: nil)
    }
    
    func sign(_ signIn: GIDSignIn!, dismiss viewController: UIViewController!) {
        dismiss(animated: true, completion: nil)
    }
    
    //    func signInWillDispatch(signIn: GIDSignIn!, error: NSError!) {
    //    }
    
    // Common FB/Google handling for social login/register result of our own server
    fileprivate func socialSignInResultHandler() -> (ProviderResult<SyncResult>) -> Void {
        return {[weak self] providerResult in
            self?.resultHandler(
                onSuccess: {[weak self] syncResult in
                    logger.v("Login success")
                    self?.delegate?.onSocialSignupInRegisterScreenSuccess()
                    self?.progressVisible(false)
                    
                    if let weakSelf = self {
                        InvitationsHandler.handleInvitations(syncResult.listInvites, inventoryInvitations: syncResult.inventoryInvites, controller: weakSelf)
                    }
                }, onError: {[weak self] providerResult in
                    logger.v("Login error: \(providerResult)")
                    self?.progressVisible(false)
                    self?.defaultErrorHandler()(providerResult)
                    if let weakSelf = self {
                        Prov.userProvider.logout(weakSelf.successHandler{}) // ensure everything cleared, buttons text resetted etc. Note this is also triggered by sync error (which is called directly after login)
                    }
                })(providerResult)
        }
    }
    
    // MARK: - EyeViewDelegate
    
    func onEyeChange(_ open: Bool) {
        passwordField.isSecureTextEntry = open
    }
    
    deinit {
        logger.v("Deinit register controller")
    }
}
