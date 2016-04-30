//
//  UserTabViewController.swift
//  shoppin
//
//  Created by ischuetz on 27/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Cocoa

class UserTabViewController: NSViewController, UserDetailsViewControllerDelegate, LoginDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if ProviderFactory().userProvider.loggedIn {
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
    
    private func showUserDetailsController() {
        let userDetailsController = NSStoryboard.userDetailsViewController()
        userDetailsController.delegate = self
        self.replaceController(userDetailsController)
    }
    
    // MARK:
    
    private func showLoginController() {
        let loginController = NSStoryboard.loginViewController()
        loginController.delegate = self
        
        self.replaceController(loginController)
    }
    
    private func replaceController(newController: NSViewController) {
        self.clearSubViewsAndViewControllers()
        self.addChildViewControllerAndView(newController)
//        newController.view.centerHorizontallyInParent() // TODO this makes the superview shrink to newController width, why?
    }
}
