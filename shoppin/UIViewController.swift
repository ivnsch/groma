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
    
    func successHandler<T>(onSuccess: (T?) -> ()) -> ((providerResult: ProviderResult<T>) -> ()) {
        return self.resultHandler(onSuccess: onSuccess, onError: nil)
    }
    
    func resultHandler<T>(#onSuccess: (T?) -> (), onError: (() -> ())? = nil)(providerResult: ProviderResult<T>) {
        
        if providerResult.success {
            onSuccess(providerResult.sucessResult)
            
        } else {
            onError?() ?? {
                let title = "todo"
                let message = "todo"
                
                let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "ok", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }()
        }
    }
}