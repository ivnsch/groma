//
//  ModalLoginController.swift
//  shoppin
//
//  Created by ischuetz on 29/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

class ModalLoginController: UINavigationController, LoginDelegate, ExpiredLoginDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let loginController = UIStoryboard.loginViewController()
        loginController.onUIReady = {
            loginController.mode = .expired
        }
        loginController.expiredLoginDelegate = self
        viewControllers = [loginController]
        
        loginController.navigationItem.title = trans("generic_login")
        loginController.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: self, action: #selector(ModalLoginController.onCancelTap(_:)))
    }
    
    func onCancelTap(_ sender: UIBarButtonItem) {
        dismiss()
    }
    
    fileprivate func dismiss() {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - LoginDelegate
    
    func onLoginSuccess() {
        dismiss()
    }
    
    func onRegisterFromLoginSuccess() {
        dismiss()
    }
    
    // MARK: - ExpiredLoginDelegate
    
    func onUseAppOfflineTap() {
        // The result handler (AlamofireExtensions) removed already the login token, so we are already in offline modus. Only need to close the modal.
        dismiss()
    }
}
