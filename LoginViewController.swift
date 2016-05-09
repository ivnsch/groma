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

// Things that make sense only for the re-login modal
protocol ExpiredLoginDelegate {
    func onUseAppOfflineTap()
}

enum LoginControllerMode {
    case Normal, Expired, AfterRegister
}

class LoginViewController: UIViewController, RegisterDelegate, ForgotPasswordDelegate, GIDSignInUIDelegate, GIDSignInDelegate, FBSDKLoginButtonDelegate, ExpiredLoginDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate, EyeViewDelegate {

    @IBOutlet weak var userNameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    @IBOutlet weak var fbButton: FBSDKLoginButton!

    @IBOutlet weak var registerButton: UIButton!
    
    @IBOutlet weak var eyeView: EyeView!
 
    // expired views
    @IBOutlet weak var pleaseLoginAgainLabel: UILabel!
    @IBOutlet weak var useAppOfflineButton: UIButton!
    @IBOutlet weak var useAppOfflineLabel: UILabel!
    
    var delegate: LoginDelegate?
    var expiredLoginDelegate: ExpiredLoginDelegate?
    
    private var validator: Validator?

    var mode: LoginControllerMode = .Normal {
        didSet {
            if registerButton != nil {
                
                let isNormal = mode == .Normal
                pleaseLoginAgainLabel.hidden = isNormal
                
                // on expired mode show below "use app offline" instead of register - there's no sense of registering here because the token just expired + we want to make clear to the users they can close the modal and continue using the app offline.
                let isExpired = mode == .Expired
                useAppOfflineButton.hidden = !isExpired
                useAppOfflineLabel.hidden = !isExpired
                registerButton.hidden = isExpired
                
                switch mode {
                case .Expired:
                    pleaseLoginAgainLabel.text = "Welcome back! Please log in again."
                case .AfterRegister:
                    pleaseLoginAgainLabel.text = "You will receive an email to confirm your registration soon.\nPlease confirm and login."
                case .Normal: break
                }
                

            } else {
                QL3("Setting mode before outlets are initialised")
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    var onUIReady: VoidFunction?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Products"

        passwordField.secureTextEntry = true
        
        GoogleSignInHelper.configure(uiDelegate: self, delegate: self)
        
        self.navigationController?.navigationBarHidden = false
        
        self.fillTestInput()
        
        self.initValidator()

        fbButton.readPermissions = ["public_profile"]

        let recognizer = UITapGestureRecognizer(target: self, action:#selector(LoginViewController.handleTap(_:)))
        recognizer.delegate = self
        view.addGestureRecognizer(recognizer)
        
        eyeView.delegate = self
        
        onUIReady?()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let storedEmail = Providers.userProvider.mySharedUser?.email {
            userNameField.text = storedEmail
            passwordField.becomeFirstResponder()
        }
        // If there's no email stored, user in most cases wants to register so we don't focus a text field
    }
    
    func handleTap(recognizer: UITapGestureRecognizer) {
        view.endEditing(true)
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
        login()
    }
    
    private func login() {
        
        
        guard self.validator != nil else {return}
        
        if let errors = self.validator?.validate() {
            for (field, _) in errors {
                field.showValidationError()
            }
            self.presentViewController(ValidationAlertCreator.create(errors), animated: true, completion: nil)
            
        } else {
            if let email = userNameField.text, password = passwordField.text {

                guard let rootController = UIApplication.sharedApplication().delegate?.window??.rootViewController else {
                    QL4("No root view controller, can't show invitations popup")
                    return
                }
                
                progressVisible()

                let loginData = LoginData(email: email, password: password)
                
                Providers.userProvider.login(loginData, controller: self, rootController.resultHandler(onSuccess: {[weak self] syncResult in guard let weakSelf = self else {return}
                    
                    weakSelf.onLoginSuccess()
                    
                    }, onError: {[weak self] result in guard let weakSelf = self else {return}
                        
                        switch result.status {
                        case .SyncFailed:
                            rootController.defaultErrorHandler()(providerResult: result) // show alert (on root view controller since in login success we switch controller)
                            self?.onLoginSuccess() // handle like success, this way user still can access settings like full download to try to solve sync problems.
                        case .IsNewDeviceLoginAndDeclinedOverwrite:
                            QL1("New device and declined overwrite") // if it's a new device login and user declined overwrite, nothing to do here, user stays in login form, provider logged user out.
                        case .CancelledLoginWithDifferentAccount:
                            QL1("New email and user cancelled clear local data popup") // nothing to do here, user stays in login form
                        default:
                            self?.defaultErrorHandler()(providerResult: result)
                            Providers.userProvider.logout(weakSelf.successHandler{}) // ensure everything cleared
                        }
                    }
                ))
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
    
    // MARK: - RegisterDelegate
    
    func onRegisterSuccess(email: String) {
        self.mode = .AfterRegister
        
        // Set the email in the input field so user don't have to type it again after confirming.
        // Note this is in memory only! If user leaves this screen and comes back this email is lost. The email in prefs is saved only after a successful login (this is a requirement for some checks to function correctly - don't change it!). If we see another email when we come back it should be an email of an account with which we previously logged in successfully.
        userNameField.text = email
        
        navigationController?.popViewControllerAnimated(true)
        self.delegate?.onRegisterFromLoginSuccess()
    }
    
    func onSocialSignupInRegisterScreenSuccess() {
        navigationController?.popViewControllerAnimated(true)
        self.delegate?.onLoginSuccess()
    }
    
    // MARK: -
    
    func textFieldShouldReturn(sender: UITextField) -> Bool {
        
        if sender == passwordField {
            login()
            sender.resignFirstResponder()
        } else {
            let textFields: [UITextField] = [userNameField, passwordField]
            if let index = textFields.indexOf(sender) {
                if let next = textFields[safe: index + 1] {
                    next.becomeFirstResponder()
                }
            }
        }
        
        return false
    }
    
    // Button is visible only in .Expired mode
    @IBAction func onUseAppOfflineTap() {
        expiredLoginDelegate?.onUseAppOfflineTap()
    }
    
    // MARK: ForgotPasswordDelegate
    
    func onForgotPasswordSuccess() {
        showInfoAlert(message: "An email to reset your password was sent")
    }
    
    // MARK:
    
    func onLoginSuccess() {
        delegate?.onLoginSuccess()
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
            Providers.userProvider.authenticateWithFacebook(tokenString, controller: self, socialSignInResultHandler())
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
            Providers.userProvider.authenticateWithGoogle(user.authentication.accessToken, controller: self, socialSignInResultHandler())
        } else {
            QL4("Google login error: \(error.localizedDescription)")
        }
    }
    
    func signIn(signIn: GIDSignIn!, didDisconnectWithUser user: GIDGoogleUser!, withError error: NSError!) {
        // Perform any operations when the user disconnects from app here.
    }
    
    func signIn(signIn: GIDSignIn!, presentViewController viewController: UIViewController!) {
        presentViewController(viewController, animated: true, completion: nil)
    }
    
    func signIn(signIn: GIDSignIn!, dismissViewController viewController: UIViewController!) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
//    func signInWillDispatch(signIn: GIDSignIn!, error: NSError!) {
//    }
    
    // Common FB/Google handling for social login/register result of our own server
    private func socialSignInResultHandler()(providerResult: ProviderResult<SyncResult>) {
        resultHandler(
            onSuccess: {[weak self] syncResult in
                QL1("Login success")
                self?.onLoginSuccess() // TODO!!!! we should probably refactor the login result handler with the credentials login? For example .IsNewDeviceLoginAndDeclinedOverwrite handling seems to be missing here.
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
    
    // MARK: - EyeViewDelegate
    
    func onEyeChange(open: Bool) {
        passwordField.secureTextEntry = open
    }
}
