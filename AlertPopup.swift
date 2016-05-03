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
    
    // Frame of popup (including semitransparent background) in case this is different than the frame controller's view.
    static func show(title title: String? = nil, message: String, controller: UIViewController, frame: CGRect? = nil, okMsg: String = "Ok", rootControllerStartPoint: CGPoint? = nil, onDismiss: VoidFunction? = nil) {
//        let alert = create(title: title, message: message, okMsg: okMsg, onDismiss: onDismiss)
//        controller.presentViewController(alert, animated: true, completion: nil)

        guard controller.view.viewWithTag(ViewTags.NotePopup) == nil else {QL2("Already showing popup, return"); return}
        
        let myAlert = NSBundle.loadView("MyAlert", owner: self) as! MyAlert
        myAlert.translatesAutoresizingMaskIntoConstraints = true
        myAlert.frame = frame ?? controller.view.bounds
        controller.view.addSubview(myAlert)
        controller.view.bringSubviewToFront(myAlert)
        myAlert.tag = ViewTags.NotePopup
        
        myAlert.text = message
        myAlert.buttonText = okMsg
        myAlert.onDismiss = onDismiss
        myAlert.dismissAnimation = .None
        myAlert.dismissWithSwipe = false
        myAlert.hasOkButton = false
        
        if let point = rootControllerStartPoint {
            // close
            myAlert.onTapAnywhere = {
                myAlert.animateScale(false, anchorPoint: point, parentView: controller.view, frame: frame) {
                    myAlert.dismiss()
                }
            }
            
            // open
            myAlert.animateScale(true, anchorPoint: point, parentView: controller.view, frame: frame)
        }
    }
    
    
}
