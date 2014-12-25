//
//  UIViewController.swift
//  shoppin
//
//  Created by ischuetz on 25.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit

extension UIViewController {

    func addChildViewControllerAndView(viewController:UIViewController) {
        self.addChildViewControllerAndView(viewController, viewIndex: self.view.subviews.count)
    }
    
    func addChildViewControllerAndView(viewController:UIViewController, viewIndex:Int) {
        self.addChildViewController(viewController)
        
        self.view.insertSubview(viewController.view, atIndex: viewIndex)
        
        viewController.didMoveToParentViewController(self)
    }
}