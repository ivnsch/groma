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
        
        self.userProvider.logout {try in
            if try.success ?? false {
                self.delegate?.onLogoutSuccess() ?? println("Warn: no login delegate")
                
            } else {
                self.delegate?.onLogoutError() ?? println("Warn: no login delegate")
            }
        }
    }
}
