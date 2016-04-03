//
//  AlertPopup.swift
//  shoppin
//
//  Created by ischuetz on 15/09/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

class AlertPopup {
    
    static func create(title title: String? = nil, message: String, okMsg: String = "Ok", onDismiss: VoidFunction? = nil) -> UIViewController {
        let alert: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: okMsg, style: UIAlertActionStyle.Default, handler: { alertAction in
            onDismiss?()
        }))
        return alert
    }
    
    static func show(title title: String? = nil, message: String, controller: UIViewController, okMsg: String = "Ok", onDismiss: VoidFunction? = nil) {
        let alert = create(title: title, message: message, okMsg: okMsg, onDismiss: onDismiss)
        controller.presentViewController(alert, animated: true, completion: nil)
    }
}
