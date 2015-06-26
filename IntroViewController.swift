//
//  IntroViewController.swift
//  shoppin
//
//  Created by ischuetz on 26/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved/≥.
//

import UIKit

class IntroViewController: UIViewController, RegisterDelegate, LoginDelegate {

    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.navigationBarHidden = true
    }
    
    @IBAction func loginTapped(sender: UIButton) {
        let loginController = UIStoryboard.loginViewController()
        loginController.delegate = self
        self.navigationController?.pushViewController(loginController, animated: true)
    }

    
    @IBAction func registerTapped(sender: UIButton) {
        let registerController = UIStoryboard.registerViewController()
        registerController.delegate = self
        self.navigationController?.pushViewController(registerController, animated: true)
    }

    
    @IBAction func skipTapped(sender: UIButton) {
        self.startMainStoryboard()
    }
    
    func onRegisterError() {
        println("register error!") // TODO handle
    }
    
    func onRegisterSuccess() {
        self.startMainStoryboard()
    }
    
    private func startMainStoryboard() {
        let tabController = UIStoryboard.mainTabController()
        self.navigationController?.setViewControllers([tabController], animated: true)
    }
    
    func onLoginError() {
        println("login error!") // TODO handle
    }
    
    func onLoginSuccess() {
        self.startMainStoryboard()
    }
}

