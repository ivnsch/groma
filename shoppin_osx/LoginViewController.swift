//
//  LoginViewController.swift
//  shoppin
//
//  Created by ischuetz on 11/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Cocoa
import Accounts

protocol LoginDelegate: class {
    func onLoginSuccess()
    
    // LoginDelegate has register link, so the register event is forwarded to the container
    func onRegisterFromLoginSuccess()
}

class LoginViewController: NSViewController, RegisterDelegate, PhFacebookDelegate {

    @IBOutlet weak var emailInputField: NSTextField!
    @IBOutlet weak var passwordInputField: NSTextField!

    weak var delegate: LoginDelegate?
    
    private let userProvider = ProviderFactory().userProvider

    private let facebookAppId = "335124139955932" // "testing"
//        private let facebookAppId = "649442088421837" // "openfeedback"
    
    private lazy var accountStore: ACAccountStore = ACAccountStore()
    
    private var fb: PhFacebook!
    
    @IBAction func loginTapped(sender: NSButton) {
        
        let email: String = self.emailInputField.stringValue
        let password: String = self.passwordInputField.stringValue
        
        guard !(email.isEmpty || password.isEmpty) else {print("TODO validation"); return}
        
        progressVisible(true)
        self.userProvider.login(LoginData(email: email, password: password), successHandler {[weak self] in
            self?.delegate?.onLoginSuccess()
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        self.fillTestInput()

        initFacebook()
    }
    
    private func initFacebook() {
        fb = PhFacebook(applicationID: facebookAppId, delegate: self)
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
    
    @IBAction func onLoginWithFacebookTap(sender: NSButton) {
        loginWithFacebookWeb()
    }
    

    private func loginWithFacebookWeb() {
        fb.getAccessTokenForPermissions(["public_profile"], cached: false)
    }
    
    // MARK: - PhFacebookDelegate
    
    func tokenResult(result: [NSObject : AnyObject]!) {

        if let value = result["valid"], valid = (value as? Int) {
            if valid == 1 {
                print("got facebook token: \(fb.accessToken())")
                
                let tokenString = fb.accessToken()

                Prov.userProvider.authenticateWithFacebook(tokenString, successHandler{[weak self] result in
                    
                    // FIXME "already exists@ on login? is it like this also in iOS?
                    // map already exists status to "social aleready exists", to show a different error message
//                    if result.status == .AlreadyExists {
//                        handler(ProviderResult(status: .SocialAlreadyExists))
//                        
//                    } else {
                    
                    if let weakSelf = self {
//                        weakSelf.createFBACAccount(weakSelf.fb.authenticationToken()) // see TODO in method
                        weakSelf.delegate?.onLoginSuccess()
                    }
                    
//                    }
                })
            }
            
        } else {
            print("Facebook login, not valid result: \(result)")
        }
    }
    
    // TODO create account after login in with webview, this way user doesn't have to use webinterface again
    // So far not possible, we get an error because our app is not permitted to create a Facebook account. If and how is possible to get this permission is unclear
    // Error:
    // error saving account: Error Domain=com.apple.accounts Code=7 "The application is not permitted to access Facebook accounts" UserInfo=0x600000e689c0 {NSLocalizedDescription=The application is not permitted to access Facebook accounts}
    // According to http://stackoverflow.com/a/21251863/930450 this is not possible in iOS. No info about OSX. Disabling sandbox mode also didn't help.
    // As a temporary solution we can also show the user a message suggesting to create the account manually
    private func createFBACAccount(token: PhAuthenticationToken) {
        let credential = ACAccountCredential(OAuth2Token: token.authenticationToken, refreshToken: "", expiryDate: token.expiry)
        let accountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierFacebook)
        let account = ACAccount(accountType: accountType)
        account.credential = credential
        
        accountStore.saveAccount(account, withCompletionHandler: {success, error in
            
            if success {
                print("Account saved!!!")
                
            } else {
                print("error saving account: \(error)")
            }
        })
    }
    
    
    
    // Called when doing requests to Facebook (e.g. get friends). We don't use this. It's required by the protocol.
    func requestResult(result: [NSObject: AnyObject]!) {
    }
    
    // TODO get this working, strange behaviour
    // Requisite: Have Facebook in accounts
    // First it would at least show the request dialog. When approving, outputs not granted, and an error - it seemed to be related with the bundle id
    // the problem is iOS and OSX have different bundle ids and the facebook app has the iOS bundle id. So this was probably the cause
    // Used then another already existing Facebook app, which was updated with OSX bundle id, correct url etc. Updated app id here in the app
    // Then it doesn't show the request dialog, only 'Not granted, error: nil'
    // After many intents, tried again with the previous app id - now also get same error 'Not granted, error: nil'
    // so no idea. Really weird that previous app id stopped working, this app was not modified in Facebook and the code here neither except changing the app id. Cleaned etc.
    // Here SO with similar problem but no useful solutions http://stackoverflow.com/questions/19103809/acaccountstore-requestaccesstoaccountswithtypeoptionscompletion-returning-nil
    private func loginWithFacebookAccount() {
        let accountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierFacebook)
        
        let permissions = ["email", "public_profile"]
        
        let options: [NSObject: AnyObject] = [
            ACFacebookAppIdKey: facebookAppId,
            ACFacebookPermissionsKey: permissions,
            ACFacebookAudienceKey: ACFacebookAudienceOnlyMe
        ]
        
        accountStore.requestAccessToAccountsWithType(accountType, options: options, completion: {[weak self] granted, error in
            
            if granted {
                
                if let weakSelf = self {
                    let accounts = weakSelf.accountStore.accountsWithAccountType(accountType)
                    
                    switch accounts.count {
                        
                    case 0:
                        print("TODO No Accounts found")
                        
                    case 1:
                        if let account = accounts.last as? ACAccount {
                            
                            print("--------------------------------------------")
                            print(account.identifier)
                            print(account.accountType)
                            print(account.accountDescription)
                            print(account.username)
                            print(account.credential)
                            print("--------------------------------------------")
                            
                            // TODO where is token? - pass a callback to loginWithFacebookAccount where we pass the token, in this callback call our provider's login
                            
                        } else {
                            print("Account is not ACAccount (???)")
                        }
                        
                    default:
                        print("TODO Multiple Accounts found")
                    }
                }
                
            } else {
                print("Not granted, error: \(error)")
            }
        })
    }
}
