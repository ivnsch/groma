//
//  NSViewController.swift
//  shoppin
//
//  Created by ischuetz on 16/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Cocoa

extension NSViewController {
    
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
    }
    
    private func showProviderErrorAlert<T>(providerResult: ProviderResult<T>) {
//        let title = "Error"
        
        let message: String = RequestErrorToMsgMapper.message(providerResult.status)
        
        let alert = NSAlert()
        alert.addButtonWithTitle("ok")
        alert.messageText = message
        alert.alertStyle = NSAlertStyle.InformationalAlertStyle
        alert.runModal()
    }

}
