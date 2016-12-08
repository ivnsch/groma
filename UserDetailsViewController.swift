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
import QorumLogs

protocol UserDetailsViewControllerDelegate: class {
    func onLogoutSuccess()
    func onLogoutError() // TODO do we really need to notify the delegate about error?
}

class UserDetailsViewController: UIViewController {

    weak var delegate: UserDetailsViewControllerDelegate?

    @IBOutlet weak var userIdLabel: UILabel!
    @IBOutlet weak var logoutButton: UIButton!
    
    override func viewDidLoad() {
        if let me = Providers.userProvider.mySharedUser {
            initContents(me)
        } else {
            QL4("Invalid state, we are in user details but there's no stored user")
        }
        
        logoutButton.layer.cornerRadius = DimensionsManager.userDetailsLogoutButtonRadius
    }
    
    fileprivate func initContents(_ user: DBSharedUser) {
        if let userIdLabel = userIdLabel {
            userIdLabel.text = user.email
        } else {
            QL3("Outlets not initialised yet, can't show user data")
        }
    }
    
    @IBAction func onLogoutTap(_ sender: UIButton) {
        
        Providers.userProvider.logout {[weak self] remoteResult in
            
            FBSDKLoginManager().logOut() // in case we logged in using fb
            GIDSignIn.sharedInstance().signOut()  // in case we logged in using google
            
            if remoteResult.success {
                self?.delegate?.onLogoutSuccess()
                
            } else {
                self?.delegate?.onLogoutError()
            }
        }
    }

}
