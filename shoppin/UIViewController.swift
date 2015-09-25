//
//  UIViewController.swift
//  shoppin
//
//  Created by ischuetz on 25.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit

extension UIViewController {

    // MARK: - Hierachy
    
    func addChildViewControllerAndView(viewController:UIViewController) {
        self.addChildViewControllerAndView(viewController, viewIndex: self.view.subviews.count)
    }
    
    func addChildViewControllerAndView(viewController:UIViewController, viewIndex:Int) {
        self.addChildViewController(viewController)
        
        self.view.insertSubview(viewController.view, atIndex: viewIndex)
        
        viewController.didMoveToParentViewController(self)
    }

    func clearSubViewsAndViewControllers() {
        for subview in self.view.subviews {
            subview.removeFromSuperview()
        }
        for childViewController in self.childViewControllers {
            childViewController.removeFromParentViewController()
        }
    }

    // MARK: - Provider result handling
    
    func successHandler(onSuccess: () -> ()) -> ((providerResult: ProviderResult<Any>) -> ()) {
        return self.resultHandler(onSuccess: onSuccess, onError: nil)
    }
    
    func successHandler<T>(onSuccess: (T) -> ()) -> ((providerResult: ProviderResult<T>) -> ()) {
        return self.resultHandler(onSuccess: onSuccess, onError: nil)
    }
    
    func resultHandler(onSuccess onSuccess: () -> (), onError: ((ProviderResult<Any>) -> ())? = nil)(providerResult: ProviderResult<Any>) {
        if providerResult.success {
            onSuccess()
            
        } else {
            onError?(providerResult) ?? self.defaultErrorHandler()(providerResult: providerResult)
        }
        self.progressVisible(false)
    }
    
    // Result handlar for result with payload
    func resultHandler<T>(onSuccess onSuccess: (T) -> (), onError: ((ProviderResult<T>) -> ())? = nil)(providerResult: ProviderResult<T>) {
        if providerResult.success {
            if let successResult = providerResult.sucessResult {
                onSuccess(successResult)
            } else {
                print("Error: Invalid state: handler expects result with payload, result is success but has no payload")
                self.showProviderErrorAlert(ProviderResult<Any>(status: ProviderStatusCode.Unknown))
            }
            
        } else {
            onError?(providerResult) ?? self.defaultErrorHandler()(providerResult: providerResult)
        }
        
        self.progressVisible(false)
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // TODO how do we unify these functions? we don't need the to know possible payload's type here, so Any would be ok but it doesn't compile for resultHandler<T>
    
    func defaultErrorHandler(ignore: [ProviderStatusCode] = [])(providerResult: ProviderResult<Any>) {
        if !ignore.contains(providerResult.status) {
            self.showProviderErrorAlert(providerResult)
        }
    }

    func defaultErrorHandler<T>(ignore: [ProviderStatusCode] = [])(providerResult: ProviderResult<T>) {
        if !ignore.contains(providerResult.status) {
            self.showProviderErrorAlert(providerResult)
        }
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////
    
    private func showProviderErrorAlert<T>(providerResult: ProviderResult<T>) {
        ProviderPopupManager.instance.showStatusPopup(providerResult.status, controller: self)
    }
    
    // MARK: - Popup
    
    func showInfoAlert(title title: String? = nil, message: String) {
        AlertPopup.show(title: title, message: message, controller: self)
    }
    
    
    // MARK: - Utils
    
    func progressVisible(visible: Bool = true) {
        self.view.defaultProgressVisible(visible)
    }
}