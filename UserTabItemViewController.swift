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

        self.showLoginController()
    }

    // MARK: - LoginDelegate
    
    func onLoginError() {
        println("login error!") // TODO handle
    }
    
    func onLoginSuccess() {
        self.onLoginOrRegisterSuccess()
    }
    
    func onRegisterFromLoginError() {
        println("register error!") // TODO handle
    }
    
    func onRegisterFromLoginSuccess() {
        self.onLoginOrRegisterSuccess()
    }
    
    private func onLoginOrRegisterSuccess() {
        let userDetailsController = UIStoryboard.userDetailsViewController()
        userDetailsController.delegate = self
        self.replaceController(userDetailsController)
    }

    // MARK: - UserDetailsViewControllerDelegate

    func onLogoutSuccess() {
        self.showLoginController()
    }

    func onLogoutError() {
        println("login error!") // TODO handle
    }
    
    // MARK:
    
    private func showLoginController() {
        let loginController = UIStoryboard.loginViewController()
        loginController.delegate = self
        
        let navigationController = UINavigationController()
        navigationController.pushViewController(loginController, animated: false)
        self.replaceController(navigationController)
    }
    
    private func replaceController(newController: UIViewController) {
        if let tabBarController = self.tabBarController, var controllers = tabBarController.viewControllers {
            
            // these loops could be replaced with first? but loop just feels better
            for view in self.view.subviews {
                view.removeFromSuperview()
            }
            for controller in self.childViewControllers {
                controller.removeFromParentViewController()
            }
            self.addChildViewControllerAndView(newController)
            newController.view.matchSize(self.view)
            
        } else {
            println("Error: trying to replace tab but there's no tab bar controller or view controllers")
        }
    }
}