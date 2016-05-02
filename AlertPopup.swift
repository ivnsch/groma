//
//  AlertPopup.swift
//  shoppin
//
//  Created by ischuetz on 15/09/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

class AlertPopup: NSObject {
    
    static func create(title title: String? = nil, message: String, okMsg: String = "Ok", onDismiss: VoidFunction? = nil) -> UIViewController {
        let alert: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: okMsg, style: UIAlertActionStyle.Default, handler: { alertAction in
            onDismiss?()
        }))
        return alert
    }
    
    static func show(title title: String? = nil, message: String, controller: UIViewController, okMsg: String = "Ok", onDismiss: VoidFunction? = nil) {
//        let alert = create(title: title, message: message, okMsg: okMsg, onDismiss: onDismiss)
//        controller.presentViewController(alert, animated: true, completion: nil)
        
        let myAlert = NSBundle.loadView("MyAlert", owner: self) as! MyAlert

        if let controller = UIApplication.sharedApplication().delegate?.window??.rootViewController {
            controller.view.addSubview(myAlert)
            myAlert.translatesAutoresizingMaskIntoConstraints = false
            myAlert.fillSuperview()
            myAlert.text = message
            myAlert.onDismiss = onDismiss
            controller.view.bringSubviewToFront(myAlert)
            
        } else {
            QL4("No root view controller, can't handle buy cart success result")
        }
    }
}
