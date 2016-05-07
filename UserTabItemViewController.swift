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
        showUserDetailsController()
    }
    
    func onRegisterFromLoginError() {
        print("register error!") // TODO handle
    }
    
    func onRegisterFromLoginSuccess() {
    }

    // MARK: - UserDetailsViewControllerDelegate

    func onLogoutSuccess() {
        self.showLoginController()
    }

    func onLogoutError() {
        print("login error!") // TODO handle
    }
    
    private func showUserDetailsController() {
        let userDetailsController = UIStoryboard.userDetailsViewController()
        userDetailsController.delegate = self
        navigationItem.title = "User"
        self.replaceController(userDetailsController)
    }
    
    // MARK:
    
    private func showLoginController() {
        let loginController = UIStoryboard.loginViewController()
        loginController.delegate = self
        navigationItem.title = "Login"
        self.replaceController(loginController)
    }
    
    private func replaceController(newController: UIViewController) {

        let currentChildControllers = childViewControllers // normally this should be only 1 - the login controller or user details view
        
        newController.view.translatesAutoresizingMaskIntoConstraints = false
        newController.view.alpha = 0
        addChildViewControllerAndViewFill(newController)
        
        // cross fade
        UIView.animateWithDuration(0.3, animations: {
            for controller in currentChildControllers {
                controller.view.alpha = 0
            }
            newController.view.alpha = 1
            }, completion: {finished in
            for controller in currentChildControllers {
                controller.removeFromParentViewControllerWithView()
            }
        })
    }
}