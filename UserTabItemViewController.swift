//
//  UserTabItemViewController.swift
//  shoppin
//
//  Created by ischuetz on 26/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

class UserTabItemViewController: UIViewController, LoginDelegate, UserDetailsViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if ProviderFactory().userProvider.hasLoginToken {
            self.showUserDetailsController()
        } else {
            self.showLoginController()
        }
    }

    // MARK: - LoginDelegate
    
    func onLoginError() {
        print("login error!") // TODO handle
    }
    
    func onLoginSuccess() {
        self.onLoginOrRegisterSuccess()
    }
    
    func onRegisterFromLoginError() {
        print("register error!") // TODO handle
    }
    
    func onRegisterFromLoginSuccess() {
        navigationController?.popViewControllerAnimated(true)
        self.onLoginOrRegisterSuccess()
    }
    
    private func onLoginOrRegisterSuccess() {
        self.showUserDetailsController()
    }

    // MARK: - UserDetailsViewControllerDelegate

    func onLogoutSuccess() {
        self.showLoginController()
    }

    func onLogoutError() {
        print("login error!") // TODO handle
    }
    
    func onRemoveAccount() {
        showLoginController()
    }
    
    private func showUserDetailsController() {
        let userDetailsController = UIStoryboard.userDetailsViewController()
        userDetailsController.delegate = self
        self.replaceController(userDetailsController)
    }
    
    // MARK:
    
    private func showLoginController() {
        let loginController = UIStoryboard.loginViewController()
        loginController.delegate = self
        self.replaceController(loginController)
    }
    
    private func replaceController(newController: UIViewController) {
        // these loops could be replaced with first? but loop just feels better
        for view in self.view.subviews {
            view.removeFromSuperview()
        }
        for controller in self.childViewControllers {
            controller.removeFromParentViewController()
        }
        self.addChildViewControllerAndViewFill(newController)
    }
}