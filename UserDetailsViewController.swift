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
import GoogleSignIn
import Providers

protocol UserDetailsViewControllerDelegate: class {
    func onLogoutSuccess()
    func onLogoutError() // TODO do we really need to notify the delegate about error?
    func onAccountRemoved()
}

class UserDetailsViewController: UIViewController {

    weak var delegate: UserDetailsViewControllerDelegate?

    @IBOutlet weak var userIdLabel: UILabel!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var deleteAccountButton: UIButton!
    @IBOutlet weak var helpButtonImage: UIImageView!

    override func viewDidLoad() {
        if let me = Prov.userProvider.mySharedUser {
            initContents(me)
        } else {
            logger.e("Invalid state, we are in user details but there's no stored user")
        }

        helpButtonImage.tintColor = Theme.lightGray2 // for some reason not working in storyboard
        
        logoutButton.layer.cornerRadius = DimensionsManager.userDetailsLogoutButtonRadius
    }
    
    fileprivate func initContents(_ user: DBSharedUser) {
        if let userIdLabel = userIdLabel {
            userIdLabel.text = user.email
        } else {
            logger.w("Outlets not initialised yet, can't show user data")
        }
    }
    
    @IBAction func onLogoutTap(_ sender: UIButton) {
        
        Prov.userProvider.logout {[weak self] remoteResult in
            self?.logoutFromSocialMedia()

            if remoteResult.success {
                self?.delegate?.onLogoutSuccess()
            } else {
                self?.delegate?.onLogoutError()
            }
        }
    }

    fileprivate func logoutFromSocialMedia() {
        FBSDKLoginManager().logOut() // in case we logged in using fb
        GIDSignIn.sharedInstance().signOut()  // in case we logged in using google
    }

    @IBAction func onDeleteAccountHelpTap(_ sender: UIButton) {
        MyPopupHelper.showPopup(parent: self, type: .info, message: trans("popup_remove_account_help"), centerYOffset: 0, maxMsgLines: 5, onOk: {
        }, onCancel: {})
    }

    @IBAction func onDeleteAccountTap(_ sender: UIButton) {
        MyPopupHelper.showPopup(
            parent: self,
            type: .warning,
            title: trans("popup_title_confirm"),
            message: trans("popup_are_you_sure_remove_account"),
            okText: trans("popup_button_yes"),
            centerYOffset: 0, onOk: { [weak self] in guard let weakSelf = self else { return }
                Prov.userProvider.removeAccount(weakSelf.successHandler {
                    let message = trans("popup_your_account_was_removed")
                    MyPopupHelper.showPopup(parent: weakSelf, type: .info, message: message, centerYOffset: 0, onOk: {
                        self?.logoutFromSocialMedia()
                        self?.delegate?.onAccountRemoved()
                    }, onCancel: {})
                })
            }, onCancel: {}
        )
    }
}
