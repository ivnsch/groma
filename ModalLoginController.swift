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
            loginController.mode = .Expired
        }
        loginController.expiredLoginDelegate = self
        viewControllers = [loginController]
        
        loginController.navigationItem.title = "Login"
        loginController.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: "onCancelTap:")
    }
    
    func onCancelTap(sender: UIBarButtonItem) {
        dismiss()
    }
    
    private func dismiss() {
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
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