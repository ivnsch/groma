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

    func successHandler(onSuccess: () -> ()) -> ((providerResult: ProviderResult<Any>) -> ()) {
        return self.resultHandler(onSuccess: onSuccess, onError: nil)
    }
    
    func successHandler<T>(onSuccess: (T) -> ()) -> ((providerResult: ProviderResult<T>) -> ()) {
        return self.resultHandler(onSuccess: onSuccess, onError: nil)
    }
    
    func resultHandler(#onSuccess: () -> (), onError: (() -> ())? = nil)(providerResult: ProviderResult<Any>) {
        if providerResult.success {
            onSuccess()
            
        } else {
            onError?() ?? self.showProviderErrorAlert(providerResult)
        }
    }
    
    // Result handlar for result with payload
    func resultHandler<T>(#onSuccess: (T) -> (), onError: (() -> ())? = nil)(providerResult: ProviderResult<T>) {
        if providerResult.success {
            if let successResult = providerResult.sucessResult {
                onSuccess(successResult)
            } else {
                println("Error: Invalid state: handler expects result with payload, result is success but has no payload")
                self.showProviderErrorAlert(ProviderResult<Any>(status: ProviderStatusCode.Unknown))
            }
            
        } else {
            onError?() ?? self.showProviderErrorAlert(providerResult)
        }
    }
    
    private func showProviderErrorAlert<T>(providerResult: ProviderResult<T>) {
        let title = "Error"
        
        let message: String = {
            switch providerResult.status {
                case .NotAuthenticated: return "error_not_authenticated"
                case .AlreadyExists: return "error_already_exists"
                case .NotFound: return "error_not_found"
                case .InvalidCredentials: return "error_invalid_credentials"
                case .ServerError: return "error_server"
                case .ServerNotReachable: return "error_server_not_reachable"
                case .UnknownServerCommunicationError: return "error_server_communication_unknown"
                case .DatabaseUnknown: return "error_unknown_database"
                case .Unknown: return "error_unknown"
                case .Success: return "success" // this is not used but we want exhaustive switch (without default case)
            }
        }()
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "ok", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    

}