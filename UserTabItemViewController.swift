//
//  UserTabItemViewController.swift
//  shoppin
//
//  Created by ischuetz on 26/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

import Providers

class UserTabItemViewController: UIViewController, LoginOrRegisterDelegate, UserDetailsViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        if Prov.userProvider.hasLoginToken {
            self.showUserDetailsController()
        } else {
            self.showLoginController()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(UserTabItemViewController.onLogoutNotification(_:)), name: NSNotification.Name(rawValue: Notification.LogoutUI.rawValue), object: nil)
    }

    // MARK: - LoginOrRegisterDelegate

    func onLoginOrRegisterSuccess() {
        showUserDetailsController()
    }

//    // MARK: - LoginDelegate
//
//    func onLoginError() {
//        print("login error!") // TODO handle
//    }
//
//    func onLoginSuccess() {
//        showUserDetailsController()
//    }
//
//    func onRegisterFromLoginError() {
//        print("register error!") // TODO handle
//    }
//
//    func onRegisterFromLoginSuccess() {
//    }

    // MARK: - UserDetailsViewControllerDelegate

    func onLogoutSuccess() {
        self.showLoginController()
    }

    func onLogoutError() {
        print("login error!") // TODO handle
    }
    
    fileprivate func showUserDetailsController() {
        let userDetailsController = UIStoryboard.userDetailsViewController()
        userDetailsController.delegate = self
        navigationItem.title = trans("title_user")
        self.replaceController(userDetailsController)
    }
    
    // MARK:
    
    fileprivate func showLoginController() {
//        let loginController = UIStoryboard.loginViewController()
        let loginController = UIStoryboard.loginOrRegisterViewController()
        loginController.delegate = self
//        loginController.onUIReady = {[weak loginController] in
//            loginController?.mode = .normal
//        }
        navigationItem.title = trans("title_login")
        self.replaceController(loginController)
    }
    
    fileprivate func replaceController(_ newController: UIViewController) {

        let currentChildControllers = childViewControllers // normally this should be only 1 - the login controller or user details view
        
        newController.view.translatesAutoresizingMaskIntoConstraints = false
        newController.view.alpha = 0
        addChildViewControllerAndViewFill(newController)
        
        // cross fade
        UIView.animate(withDuration: 0.3, animations: {
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
    
    // MARK: - Notification
    
    @objc func onLogoutNotification(_ note: Foundation.Notification) {
        if !(childViewControllers.first is LoginViewController) {
            showLoginController()
        }
    }
    
    deinit {
        logger.v("Deinit user tab controller")
        NotificationCenter.default.removeObserver(self)
    }
}
