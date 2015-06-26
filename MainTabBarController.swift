//
//  MainTabBarController.swift
//  shoppin
//
//  Created by ischuetz on 26/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let loginController = UIStoryboard.loginViewController()
        var viewControllers = self.viewControllers
        viewControllers?.append(loginController)
        self.viewControllers = viewControllers
        
        (self.tabBar.items?[2] as! UITabBarItem).title = "User"
    }
}
