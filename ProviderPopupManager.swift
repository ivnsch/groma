//
//  ProviderPopupManager.swift
//  shoppin
//
//  Created by ischuetz on 25/09/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

import Providers

class ProviderPopupManager {

    static let instance: ProviderPopupManager = ProviderPopupManager()
    
    fileprivate var currentStatus: ProviderStatusCode?
    
    fileprivate init() {
    }
    
    /**
    * Shows a popup with a message corresponding to passed status code
    * If a popup is being already shown for the same status code, this method does nothing
    */
    func showStatusPopup(_ status: ProviderStatusCode, controller: UIViewController) {
        
        if controller.presentedViewController == nil && ((currentStatus.map {$0 != status}) ?? true) { // if there's no popup or if there's a popup with different status code
            currentStatus = status
            
            let title = trans("popup_title_error")
            let message: String = RequestErrorToMsgMapper.message(status)

            AlertPopup.show(title: title, message: message, controller: controller, onDismiss: {[weak self] in
                // IMPORTANT: When implementing dismissal by tapping outside, ensure the status is also cleared. See http://stackoverflow.com/a/25469305/930450
                self?.currentStatus = nil
            })
        } else {
            logger.d("Skipping error popup, currentStatus: \(String(describing: currentStatus)), status: \(status)")
            delay(1) {[weak self] in // If for somOe reason a popup wasn't closed properly, clear status after a while. Since this is used only to not show many popups of the same type at the same time, clearing after a delay is ok. This situation shouldn't happen, now that we added controller.presentedViewController == nil check, but adding this anyway as it's very, very bad when user can't see popups anymore until the next restart of the app, so even if it's just a small possibility we want to avoid this.
                self?.currentStatus = nil
            }
        }
    }
    
    // TODO!! test this
    func showRemoteValidationPopup(_ status: ProviderStatusCode, error: RemoteInvalidParametersResult, controller: UIViewController) {
        
        if controller.presentedViewController == nil && ((currentStatus.map {$0 != status}) ?? true) { // if there's no popup or if there's a popup with different status code
            currentStatus = status

            let title = trans("popup_title_validation_failed")

            let message = error.pathErrors.map {e in
                let pathErrorsStr = e.validationErrors.map{$0.msg}.joined(separator: ", ")
                return ("\(e.path): \(pathErrorsStr)")
            }.joined(separator: "\n")
            
            AlertPopup.show(title: title, message: message, controller: controller, onDismiss: {[weak self] in
                // IMPORTANT: When implementing dismissal by tapping outside, ensure the status is also cleared. See http://stackoverflow.com/a/25469305/930450
                self?.currentStatus = nil
            })
        } else {
            logger.d("Skipping error popup, currentStatus: \(String(describing: currentStatus)), status: \(status)")
            delay(1) {[weak self] in
                // see note on delay in showStatusPopup method
                self?.currentStatus = nil
            }
        }
    }
}
