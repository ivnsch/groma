//
//  UserDetailsViewController.swift
//  shoppin
//
//  Created by ischuetz on 27/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Cocoa

protocol UserDetailsViewControllerDelegate {
    func onLogoutSuccess()
    func onLogoutError()
}


class UserDetailsViewController: NSViewController {
    
    let userProvider = ProviderFactory().userProvider
    
    var delegate: UserDetailsViewControllerDelegate?
    
    @IBAction func onLogoutTap(sender: NSButton) {
        
        self.userProvider.logout {remoteResult in
            if remoteResult.success ?? false {
                self.delegate?.onLogoutSuccess() ?? print("Warn: no login delegate")
                
            } else {
                self.delegate?.onLogoutError() ?? print("Warn: no login delegate")
            }
        }
    }
}