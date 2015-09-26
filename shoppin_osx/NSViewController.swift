//
//  NSViewController.swift
//  shoppin
//
//  Created by ischuetz on 16/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Cocoa

extension NSViewController {

    func addChildViewControllerAndView(viewController: NSViewController) {
        self.addChildViewController(viewController)
        self.view.addSubview(viewController.view)
    }
    
    func clearSubViewsAndViewControllers() {
        for subview in self.view.subviews {
            subview.removeFromSuperview()
        }
        for childViewController in self.childViewControllers {
            childViewController.removeFromParentViewController()
        }
    }
    
    func successHandler(onSuccess: () -> ()) -> ((providerResult: ProviderResult<Any>) -> ()) {
        return self.resultHandler(onSuccess: onSuccess, onError: nil)
    }
    
    func successHandler<T>(onSuccess: (T) -> ()) -> ((providerResult: ProviderResult<T>) -> ()) {
        return self.resultHandler(onSuccess: onSuccess, onError: nil)
    }
    
    func resultHandler(onSuccess onSuccess: () -> (), onError: (() -> ())? = nil)(providerResult: ProviderResult<Any>) {
        if providerResult.success {
            onSuccess()
            
        } else {
            onError?() ?? self.showProviderErrorAlert(providerResult)
        }
        progressVisible(false)
    }
    
    // Result handlar for result with payload
    func resultHandler<T>(onSuccess onSuccess: (T) -> (), onError: (() -> ())? = nil)(providerResult: ProviderResult<T>) {
        if providerResult.success {
            if let successResult = providerResult.sucessResult {
                onSuccess(successResult)
            } else {
                print("Error: Invalid state: handler expects result with payload, result is success but has no payload")
                self.showProviderErrorAlert(ProviderResult<Any>(status: ProviderStatusCode.Unknown))
            }
            
        } else {
            onError?() ?? self.showProviderErrorAlert(providerResult)
        }
        progressVisible(false)
    }
    
    private func showProviderErrorAlert<T>(providerResult: ProviderResult<T>) {
//        let title = "Error"
        if let window = view.window {
            ProviderPopupManager.instance.showStatusPopup(providerResult.status, window: window)
        } else {
            print("Trying to display modal for status code: \(providerResult.status) but view controller has no window!")
        }
    }
    
    // MARK: - Utils
    
    func progressVisible(visible: Bool) {
        self.view.defaultProgressVisible(visible)
    }
}
