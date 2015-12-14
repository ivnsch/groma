//
//  UserDetailsViewController.swift
//  shoppin
//
//  Created by ischuetz on 26/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit

protocol UserDetailsViewControllerDelegate {
    func onLogoutSuccess()
    func onLogoutError() // TODO do we really need to notify the delegate about error?
    func onRemoveAccount()
}

class UserDetailsViewController: UIViewController {

    var delegate: UserDetailsViewControllerDelegate?
    
    @IBAction func onLogoutTap(sender: UIButton) {
        
        Providers.userProvider.logout {remoteResult in
            
            FBSDKLoginManager().logOut() // in case we logged in using fb
            GIDSignIn.sharedInstance().signOut()  // in case we logged in using google
            
            if remoteResult.success ?? false {
                self.delegate?.onLogoutSuccess() ?? print("Warn: no login delegate")
                
            } else {
                self.delegate?.onLogoutError() ?? print("Warn: no login delegate")
            }
        }
    }
    
    
    @IBAction func onRemoveAccountTap(sender: UIButton) {
        ConfirmationPopup.show(message: "Are you sure you want to remove your account?", controller: self, onOk: {[weak self] in
            
            if let weakSelf = self {
                
                Providers.userProvider.removeAccount(weakSelf.successHandler({
                    // note possible credentials login token deleted in removeAccount
                    FBSDKLoginManager().logOut() // in case we logged in using fb
                    GIDSignIn.sharedInstance().signOut()  // in case we logged in using google
                    
                    AlertPopup.show(title: "Success", message: "The account was removed", controller: weakSelf, onDismiss: {
                        weakSelf.delegate?.onRemoveAccount() ?? print("Warn: no login delegate")
                    })
                }))
            }
        })
    }
}
