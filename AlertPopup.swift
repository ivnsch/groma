//
//  AlertPopup.swift
//  shoppin
//
//  Created by ischuetz on 15/09/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

class AlertPopup {
    
    static func create(title title: String? = nil, message: String, onDismiss: VoidFunction? = nil) -> UIViewController {
        let alert: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: { alertAction in
            onDismiss?()
        }))
        return alert
    }
    
    static func show(title title: String? = nil, message: String, controller: UIViewController, onDismiss: VoidFunction? = nil) {
        let alert = create(title: title, message: message, onDismiss: onDismiss)
        controller.presentViewController(alert, animated: true, completion: nil)
    }
}
