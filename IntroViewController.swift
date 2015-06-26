//
//  IntroViewController.swift
//  shoppin
//
//  Created by ischuetz on 26/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved/≥.
//

import UIKit

class IntroViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.navigationBarHidden = true
    }
    
    @IBAction func loginTapped(sender: UIButton) {
        let loginController = UIStoryboard.loginViewController()
        self.navigationController?.pushViewController(loginController, animated: true)
    }

    
    @IBAction func registerTapped(sender: UIButton) {
    }

    
    @IBAction func skipTapped(sender: UIButton) {
        let tabController = UIStoryboard.mainTabController()
        self.navigationController?.setViewControllers([tabController], animated: true)
    }
}

