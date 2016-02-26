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
    
    func addChildViewControllerAndView(viewController: UIViewController) {
        self.addChildViewControllerAndView(viewController, viewIndex: self.view.subviews.count)
    }

    func addChildViewControllerAndViewFill(viewController: UIViewController) {
        self.addChildViewControllerAndView(viewController, viewIndex: self.view.subviews.count)
        viewController.view.fillSuperview()
    }

    func addChildViewControllerAndView(viewController: UIViewController, viewIndex:Int) {
        self.addChildViewController(viewController)
        
        self.view.insertSubview(viewController.view, atIndex: viewIndex)
        
        viewController.didMoveToParentViewController(self)
    }

    func addChildViewControllerAndMove(viewController: UIViewController) {
        addChildViewController(viewController)
        viewController.didMoveToParentViewController(self)
    }
    
    func removeFromParentViewControllerWithView() {
        removeFromParentViewController()
        view.removeFromSuperview()
    }
    
    func removeChildViewControllers() {
        for childViewController in self.childViewControllers {
            childViewController.removeFromParentViewController()
        }
    }
    
    func clearSubViewsAndViewControllers() {
        view.removeSubviews()
        removeChildViewControllers()
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
    func resultHandler<T>(onSuccess onSuccess: (T) -> Void, onError: ((ProviderResult<T>) -> Void)? = nil)(providerResult: ProviderResult<T>) {
        if providerResult.success {
            if let successResult = providerResult.sucessResult {
                onSuccess(successResult)
            } else {
                print("Error: Invalid state: handler expects result with payload, result is success but has no payload")
                showProviderErrorAlert(ProviderResult<Any>(status: ProviderStatusCode.Unknown))
            }
            
        } else {
            onError?(providerResult) ?? defaultErrorHandler()(providerResult: providerResult)
        }
        
        progressVisible(false)
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
            
            if providerResult.status == .ServerInvalidParamsError {
                if let error = providerResult.error {
                    showRemoteValidationErrorAlert(providerResult.status, error: error)
                } else {
                    print("UIViewController.defaultErrorHandler: Invalid state: Has invalid credentials status but no error obj: \(providerResult)")
                }
            } else {
                showProviderErrorAlert(providerResult)
            }
        }
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////
    
    private func showProviderErrorAlert<T>(providerResult: ProviderResult<T>) {
        switch providerResult.status {
        case .SizeLimit:
            let size = providerResult.errorObj.map{$0}
            let sizeStr = size.map{"(\($0))"} ?? ""
            AlertPopup.show(title: title, message: "size_limit_exceeded \(sizeStr)", controller: self)
  
        default: ProviderPopupManager.instance.showStatusPopup(providerResult.status, controller: self)
        }
    }
    
    private func showRemoteValidationErrorAlert(status: ProviderStatusCode, error: RemoteInvalidParametersResult) {
        ProviderPopupManager.instance.showRemoteValidationPopup(status, error: error, controller: self)
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