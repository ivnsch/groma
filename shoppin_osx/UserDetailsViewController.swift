//
//  UserDetailsViewController.swift
//  shoppin
//
//  Created by ischuetz on 27/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Cocoa

protocol UserDetailsViewControllerDelegate: class {
    func onLogoutSuccess()
    func onLogoutError()
    func onRemoveAccount()
}


class UserDetailsViewController: NSViewController {
    
    let userProvider = ProviderFactory().userProvider
    
    weak var delegate: UserDetailsViewControllerDelegate?
    
    @IBAction func onLogoutTap(sender: NSButton) {
        
        self.userProvider.logout {remoteResult in
            if remoteResult.success ?? false {
                self.delegate?.onLogoutSuccess() ?? print("Warn: no login delegate")
                
            } else {
                self.delegate?.onLogoutError() ?? print("Warn: no login delegate")
            }
        }
    }
    
    @IBAction func onRemoveAccountTap(sender: NSButton) {
        
        if let window = view.window {
            
            ConfirmationPopup.show(message: "Are you sure you want to remove your account?", window: window, onOk: {[weak self] in
                
                if let weakSelf = self {

                    weakSelf.progressVisible(true)
                    weakSelf.userProvider.removeAccount(weakSelf.successHandler({

                        AlertPopup.show(title: trans("popup_title_success"), message: trans("popup_your_account_was_removed"), window: window, onDismiss: {
                            weakSelf.delegate?.onRemoveAccount() ?? print("Warn: no login delegate")
                        })
                    }))
                }
            })
            
        } else {
            print("Could not display confirmation popup because view controller has no window!")
        }
    }
}
