//
//  UserDetailsViewController.swift
//  shoppin
//
//  Created by ischuetz on 26/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

protocol UserDetailsViewControllerDelegate {
    func onLogoutSuccess()
    func onLogoutError()
}

class UserDetailsViewController: UIViewController {

    let userProvider = ProviderFactory().userProvider

    var delegate: UserDetailsViewControllerDelegate?
    
    @IBAction func onLogoutTap(sender: UIButton) {
        
        self.userProvider.logout {remoteResult in
            if remoteResult.success ?? false {
                self.delegate?.onLogoutSuccess() ?? print("Warn: no login delegate")
                
            } else {
                self.delegate?.onLogoutError() ?? print("Warn: no login delegate")
            }
        }
    }
}
