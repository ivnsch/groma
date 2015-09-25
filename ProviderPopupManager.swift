//
//  ProviderPopupManager.swift
//  shoppin
//
//  Created by ischuetz on 25/09/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

class ProviderPopupManager {

    static let instance: ProviderPopupManager = ProviderPopupManager()
    
    private var currentStatus: ProviderStatusCode?
    
    private init() {
    }
    
    /**
    * Shows a popup with a message corresponding to passed status code
    * If a popup is being already shown for the same status code, this method does nothing
    */
    func showStatusPopup(status: ProviderStatusCode, controller: UIViewController) {

        if (currentStatus.map {$0 != status}) ?? true { // if there's no popup or if there's a popup with different status code
            currentStatus = status
            
            let title = "Error"
            let message: String = RequestErrorToMsgMapper.message(status)

            AlertPopup.show(title: title, message: message, controller: controller, onDismiss: {[weak self] in
                // IMPORTANT: When implementing dismissal by tapping outside, ensure the status is also cleared. See http://stackoverflow.com/a/25469305/930450
                self?.currentStatus = nil
            })
        }
    }
}