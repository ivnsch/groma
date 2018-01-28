//
//  LoginOrRegisterController.swift
//  groma
//
//  Created by Ivan Schuetz on 28.01.18.
//  Copyright © 2018 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator
import FBSDKCoreKit
import FBSDKLoginKit
import GoogleSignIn
import Providers

protocol LoginOrRegisterDelegate: class {
    func onLoginOrRegisterSuccess()
}

class LoginOrRegisterController: UIViewController, ForgotPasswordDelegate, GIDSignInUIDelegate, GIDSignInDelegate, FBSDKLoginButtonDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate, EyeViewDelegate {

    @IBOutlet weak var userNameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var fbButton: FBSDKLoginButton!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var eyeView: UIButton!

    weak var delegate: LoginOrRegisterDelegate?

    fileprivate var validator: Validator?

    var onUIReady: VoidFunction?

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.isNavigationBarHidden = false

        navigationItem.title = trans("Login")

        passwordField.isSecureTextEntry = true

        GoogleSignInHelper.configure(uiDelegate: self, delegate: self)

        self.fillTestInput()

        self.initValidator()

        fbButton.readPermissions = ["public_profile"]

        let recognizer = UITapGestureRecognizer(target: self, action:#selector(LoginViewController.handleTap(_:)))
        recognizer.delegate = self
        recognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(recognizer)

        eyeView.imageView?.contentMode = .scaleAspectFit
//        eyeView.delegate = self

        staticLayout()

        onUIReady?()
    }

    fileprivate func staticLayout() {
        loginButton.layer.cornerRadius = DimensionsManager.userDetailsLogoutButtonRadius
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let storedEmail = Prov.userProvider.mySharedUser?.email {
            userNameField.text = storedEmail
            passwordField.becomeFirstResponder()
        }
        // If there's no email stored, user in most cases wants to register so we don't focus a text field
    }

    @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
        view.endEditing(true)
    }

    fileprivate func initValidator() {
        let validator = Validator()
        //        validator.registerField(self.userNameField, rules: [EmailRule(message: trans("validation_email_format"))])
        validator.registerField(self.passwordField, rules: [RequiredRule(message: trans("validation_missing_password"))]) // TODO repl with translation key, for now this so testers understand
        self.validator = validator
    }

    fileprivate func fillTestInput() {
        userNameField.text = "test"
        passwordField.text = "test"
        //        userNameField.text = "ivanschuetz@gmail.com"
        //        passwordField.text = "test123Q"
    }

    @IBAction func loginOrRegisterTapped(_ sender: AnyObject) {
        login()
    }

    fileprivate func login() {


        guard self.validator != nil else {return}

        if let errors = self.validator?.validate() {
            for (_, error) in errors {
                error.field.showValidationError()
            }
            present(ValidationAlertCreator.create(errors), animated: true, completion: nil)

        } else {
            if let email = userNameField.text, let password = passwordField.text {

                guard let rootController = UIApplication.shared.delegate?.window??.rootViewController else {
                    logger.e("No root view controller, can't show invitations popup")
                    return
                }

                progressVisible()

                let loginData = LoginData(email: email, password: password)

                Prov.userProvider.login(loginData, controller: self, rootController.resultHandler(onSuccess: {[weak self] syncResult in guard let weakSelf = self else {return}

                    weakSelf.onLoginSuccess()

                    }, onError: {[weak self] result in guard let weakSelf = self else {return}

                        switch result.status {
                        case .syncFailed:
                            rootController.defaultErrorHandler()(result) // show alert (on root view controller since in login success we switch controller)
                            self?.onLoginSuccess() // handle like success, this way user still can access settings like full download to try to solve sync problems.
                        case .isNewDeviceLoginAndDeclinedOverwrite:
                            logger.v("New device and declined overwrite") // if it's a new device login and user declined overwrite, nothing to do here, user stays in login form, provider logged user out.
                        case .cancelledLoginWithDifferentAccount:
                            logger.v("New email and user cancelled clear local data popup") // nothing to do here, user stays in login form
                        default:
                            self?.defaultErrorHandler()(result)
                            Prov.userProvider.logout(weakSelf.successHandler{}) // ensure everything cleared
                        }
                    }
                ))
            } else {
                print("Error: validation was not implemented correctly")
            }
        }
    }

    @IBAction func onForgotPasswordTap(_ sender: UIButton) {
        let forgotPasswordViewController = UIStoryboard.forgotPasswordViewController()
        forgotPasswordViewController.delegate = self
        forgotPasswordViewController.email = userNameField.text
        self.navigationController?.pushViewController(forgotPasswordViewController, animated: true)
    }

    @IBAction func onRegisterTap(_ sender: UIButton) {
        // TODO#
//        let registerController = UIStoryboard.registerViewController()
//        registerController.delegate = self
//        self.navigationController?.pushViewController(registerController, animated: true)
    }

    // MARK: - RegisterDelegate

    func onRegisterSuccess(_ email: String) {
        //        self.mode = .afterRegister // TODO# ?

        // Set the email in the input field so user don't have to type it again after confirming.
        // Note this is in memory only! If user leaves this screen and comes back this email is lost. The email in prefs is saved only after a successful login (this is a requirement for some checks to function correctly - don't change it!). If we see another email when we come back it should be an email of an account with which we previously logged in successfully.
        userNameField.text = email

        _ = navigationController?.popViewController(animated: true)
        //        self.delegate?.onRegisterFromLoginSuccess() // TODO#
    }

    func onLoginFromRegisterSuccess() {
        // TODO remove register from login
    }

    func onSocialSignupInRegisterScreenSuccess() {
        _ = navigationController?.popViewController(animated: true)
        self.delegate?.onLoginOrRegisterSuccess()
    }


    // MARK: -

    func textFieldShouldReturn(_ sender: UITextField) -> Bool {

        if sender == passwordField {
            login()
            sender.resignFirstResponder()
        } else {
            let textFields: [UITextField] = [userNameField, passwordField]
            if let index = textFields.index(of: sender) {
                if let next = textFields[safe: index + 1] {
                    next.becomeFirstResponder()
                }
            }
        }

        return false
    }


    // MARK: ForgotPasswordDelegate

    func onForgotPasswordSuccess() {
        showInfoAlert(message: trans("An email to reset your password was sent"))
    }

    // MARK:

    func onLoginSuccess() {
        delegate?.onLoginOrRegisterSuccess()
    }

    // TODO refactor, same code as in LoginController
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
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
                logger.e("Facebook no token")
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
            Prov.userProvider.authenticateWithGoogle(user.authentication.idToken, controller: self, socialSignInResultHandler())
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
                    self?.onLoginSuccess() // TODO!!!! we should probably refactor the login result handler with the credentials login? For example .IsNewDeviceLoginAndDeclinedOverwrite handling seems to be missing here.
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
        logger.v("Deinit loginOrRegister controller")
    }

}
