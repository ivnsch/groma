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
    
    static func show(title title: String? = nil, message: String, controller: UIViewController, okMsg: String = "Ok", rootControllerStartPoint: CGPoint? = nil, onDismiss: VoidFunction? = nil) {
//        let alert = create(title: title, message: message, okMsg: okMsg, onDismiss: onDismiss)
//        controller.presentViewController(alert, animated: true, completion: nil)
                
        if let controller = UIApplication.sharedApplication().delegate?.window??.rootViewController {
    
            let myAlert = NSBundle.loadView("MyAlert", owner: self) as! MyAlert
            myAlert.translatesAutoresizingMaskIntoConstraints = true
            myAlert.frame = CGRectMake(0, 0, controller.view.frame.width, controller.view.frame.height)
            controller.view.addSubview(myAlert)
            controller.view.bringSubviewToFront(myAlert)

            myAlert.text = message
            myAlert.buttonText = okMsg
            myAlert.onDismiss = onDismiss
            myAlert.dismissAnimation = .None
            myAlert.dismissWithSwipe = false
            myAlert.hasOkButton = false
            
            if let point = rootControllerStartPoint {
                // close
                myAlert.onTapAnywhere = {
                    myAlert.animateScale(false, anchorPoint: point, parentView: controller.view) {
                        myAlert.dismiss()
                    }
                }
                
                // open
                myAlert.animateScale(true, anchorPoint: point, parentView: controller.view)
            }

        } else {
            QL4("No root view controller, can't handle buy cart success result")
        }
    }
    
    
}
