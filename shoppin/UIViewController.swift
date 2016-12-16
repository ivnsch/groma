//
//  UIViewController.swift
//  shoppin
//
//  Created by ischuetz on 25.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs
import Providers

extension UIViewController {

    // MARK: - Hierachy
    
    func addChildViewControllerAndView(_ viewController: UIViewController) {
        self.addChildViewControllerAndView(viewController, viewIndex: self.view.subviews.count)
    }

    func addChildViewControllerAndViewFill(_ viewController: UIViewController) {
        self.addChildViewControllerAndView(viewController, viewIndex: self.view.subviews.count)
        viewController.view.fillSuperview()
    }

    func addChildViewControllerAndView(_ viewController: UIViewController, viewIndex:Int) {
        self.addChildViewController(viewController)
        
        self.view.insertSubview(viewController.view, at: viewIndex)
        
        viewController.didMove(toParentViewController: self)
    }

    func addChildViewControllerAndMove(_ viewController: UIViewController) {
        addChildViewController(viewController)
        viewController.didMove(toParentViewController: self)
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
    
    func successHandler(_ onSuccess: @escaping () -> ()) -> ((_ providerResult: ProviderResult<Any>) -> ()) {
        return self.resultHandler(onSuccess: onSuccess, onError: nil)
    }
    
    func successHandler<T>(_ onSuccess: @escaping (T) -> ()) -> ((_ providerResult: ProviderResult<T>) -> ()) {
        return self.resultHandler(onSuccess: onSuccess, onError: nil)
    }

    func resultHandler(resetProgress: Bool = true, onSuccess: @escaping VoidFunction, onErrorAdditional: @escaping ((ProviderResult<Any>) -> Void)) -> (_ providerResult: ProviderResult<Any>) -> Void {
        return {[weak self] providerResult in
            if providerResult.success {
                onSuccess()
                
            } else {
                onErrorAdditional(providerResult)
                self?.defaultErrorHandler()(providerResult)
            }
            if resetProgress {
                self?.progressVisible(false)
            }
        }
    }

    // Result handler for result with payload
    func resultHandler<T>(resetProgress: Bool = true, onSuccess: @escaping (T) -> Void, onErrorAdditional: @escaping ((ProviderResult<T>) -> Void)) -> (_ providerResult: ProviderResult<T>) -> Void {
        return {[weak self] providerResult in
            if providerResult.success {
                if let successResult = providerResult.sucessResult {
                    onSuccess(successResult)
                } else {
                    QL4("Invalid state: handler expects result with payload, result is success but has no payload. Result: \(providerResult)")
                    self?.handleResultHelper(.unknown, error: nil, errorObj: nil)
                }
                
            } else {
                onErrorAdditional(providerResult)
                self?.defaultErrorHandler()(providerResult)
            }
            if resetProgress {
                self?.progressVisible(false)
            }
        }
    }
    
    func resultHandler(resetProgress: Bool = true, onSuccess: @escaping VoidFunction, onError: ((ProviderResult<Any>) -> Void)? = nil) -> (_ providerResult: ProviderResult<Any>) -> Void {
        return {[weak self] providerResult in
            if providerResult.success {
                onSuccess()
                
            } else {
                if let onError = onError {
                    onError(providerResult)
                } else {
                    self?.defaultErrorHandler()(providerResult)
                }
            }
            if resetProgress {
                self?.progressVisible(false)
            }
        }
    }
    
    // Result handler for result with payload
    func resultHandler<T>(resetProgress: Bool = true, onSuccess: @escaping (T) -> Void, onError: ((ProviderResult<T>) -> Void)? = nil) -> (_ providerResult: ProviderResult<T>) -> Void {
        return {[weak self] providerResult in
            if providerResult.success {
                if let successResult = providerResult.sucessResult {
                    onSuccess(successResult)
                } else {
                    QL4("Invalid state: handler expects result with payload, result is success but has no payload. Result: \(providerResult)")
                    self?.handleResultHelper(.unknown, error: nil, errorObj: nil)
                }
                
            } else {
                if let onError = onError {
                    onError(providerResult)
                } else {
                    self?.defaultErrorHandler()(providerResult)
                }
            }
            if resetProgress {
                self?.progressVisible(false)
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // TODO how do we unify these functions? we don't need the to know possible payload's type here, so Any would be ok but it doesn't compile for resultHandler<T>
    
    func defaultErrorHandler(_ ignore: [ProviderStatusCode] = []) -> (_ providerResult: ProviderResult<Any>) -> Void {
        return {[weak self] providerResult in
            if !ignore.contains(providerResult.status) {
                self?.handleResultHelper(providerResult.status, error: providerResult.error, errorObj: providerResult.errorObj)
                self?.progressVisible(false)
            }
        }
    }

    func defaultErrorHandler<T>(_ ignore: [ProviderStatusCode] = []) -> (_ providerResult: ProviderResult<T>) -> Void {
        return {[weak self] providerResult in
            if !ignore.contains(providerResult.status) {
                self?.handleResultHelper(providerResult.status, error: providerResult.error, errorObj: providerResult.errorObj)
                self?.progressVisible(false)
            } else {
                QL1("Ignoring status code: \(providerResult.status), result: \(providerResult)")
            }
        }
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////
    
    fileprivate func handleResultHelper(_ status: ProviderStatusCode, error: RemoteInvalidParametersResult?, errorObj: Any?) {
        switch status {
        case .serverInvalidParamsError:
            if let error = error {
                showRemoteValidationErrorAlert(status, error: error)
            } else {
                QL4("Invalid state: Has invalid params status but no error, status: \(status), error: \(error), errorObj: \(errorObj)")
                ProviderPopupManager.instance.showStatusPopup(status, controller: self)
            }
        case .sizeLimit:
            let size = errorObj.map{$0}
            let sizeStr = size.map{"(\($0))"} ?? ""
            AlertPopup.show(title: title, message: trans("size_limit_exceeded", sizeStr), controller: self)
        
        case .mustUpdateApp:
            QL1("Controller received: \(status), do nothing.") // popup in this case is shown by AppDelegate
            
        default: ProviderPopupManager.instance.showStatusPopup(status, controller: self)
        }
    }
    
    fileprivate func showRemoteValidationErrorAlert(_ status: ProviderStatusCode, error: RemoteInvalidParametersResult) {
        ProviderPopupManager.instance.showRemoteValidationPopup(status, error: error, controller: self)
    }
    
    // MARK: - Popup
    
    func showInfoAlert(title: String? = nil, message: String) {
        AlertPopup.show(title: title, message: message, controller: self)
    }
    
    
    // MARK: - Utils
    
    func progressVisible(_ visible: Bool = true) {
        self.view.defaultProgressVisible(visible)
    }
}
