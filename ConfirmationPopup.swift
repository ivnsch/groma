//
//  ConfirmationPopup.swift
//  shoppin
//
//  Created by ischuetz on 26/09/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

class ConfirmationPopup {
    
    static func create(title title: String? = nil, message: String, okTitle: String, cancelTitle: String, onOk: VoidFunction? = nil, onCancel: VoidFunction? = nil) -> UIViewController {
        let alert: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: okTitle, style: UIAlertActionStyle.Default, handler: { alertAction in
            onOk?()
        }))
        alert.addAction(UIAlertAction(title: cancelTitle, style: UIAlertActionStyle.Cancel, handler: { alertAction in
            onCancel?()
        }))
        return alert
    }
    
    static func show(title title: String? = nil, message: String, okTitle: String = "Ok", cancelTitle: String = "Cancel", controller: UIViewController, onOk: VoidFunction? = nil, onCancel: VoidFunction? = nil, onCannotPresent: VoidFunction? = nil) {
        let alert = create(title: title, message: message, okTitle: okTitle, cancelTitle: cancelTitle, onOk: onOk, onCancel: onCancel)
        
        if controller.presentedViewController == nil {
            controller.presentViewController(alert, animated: true, completion: nil)
        } else {
            QL3("Already showing a confirmation popup: \(controller.presentedViewController), skipping new one: title: \(title), message: \(message)")
            onCannotPresent?()
        }
    }
}
