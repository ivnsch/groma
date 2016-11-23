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
    
    static func create(title: String? = nil, message: String, okMsg: String = trans("popup_button_ok"), onDismiss: VoidFunction? = nil) -> UIViewController {
        let alert: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: okMsg, style: UIAlertActionStyle.default, handler: { alertAction in
            onDismiss?()
        }))
        return alert
    }

    static func show(title: String? = nil, message: String, controller: UIViewController, okMsg: String = trans("popup_button_ok"), cancelMsg: String = trans("popup_button_cancel"), okAction: VoidFunction? = nil, onDismiss: VoidFunction? = nil) {
        let alert = create(title: title, message: message, okMsg: okMsg, onDismiss: onDismiss)
        controller.present(alert, animated: true, completion: nil)
    }

    // TODO better structure, alert and confirm should be 2 different classes, which share part of the view and code
    // Frame of popup (including semitransparent background) in case this is different than the frame controller's view.
    static func showCustom(title: String? = nil, message: String, controller: UIViewController, frame: CGRect? = nil, okMsg: String = trans("popup_button_ok"), confirmMsg: String = trans("popup_button_ok"), cancelMsg: String = trans("popup_button_cancel"), hasOkButton: Bool = false, isConfirm: Bool = false, rootControllerStartPoint: CGPoint? = nil, okAction: VoidFunction? = nil, onDismiss: VoidFunction? = nil) {
        
        guard controller.view.viewWithTag(ViewTags.NotePopup) == nil else {QL2("Already showing popup, return"); return}
        
        let myAlert = Bundle.loadView("MyAlert", owner: self) as! MyAlert
        
        myAlert.translatesAutoresizingMaskIntoConstraints = true
        myAlert.frame = frame ?? controller.view.bounds
        controller.view.addSubview(myAlert)
        controller.view.bringSubview(toFront: myAlert)
        myAlert.tag = ViewTags.NotePopup
        
        myAlert.confirmText = confirmMsg
        myAlert.cancelText = cancelMsg
        myAlert.buttonText = okMsg
        
        myAlert.isConfirm = isConfirm
        myAlert.hasOkButton = hasOkButton // this only has an effect when isConfirm = false, order also matters - has to be called after setting isConfirm and before setting title and text :)
        
        myAlert.title = title
        myAlert.text = message
        
        myAlert.onDismiss = onDismiss
        myAlert.dismissWithSwipe = false
        
        myAlert.onOk = okAction
        
        // "grow from point" animation
        if let point = rootControllerStartPoint {
            
            myAlert.dismissAnimation = .none
            
            // close
            myAlert.onTapAnywhere = {
                myAlert.animateScale(false, anchorPoint: point, parentView: controller.view, frame: frame) {
                    myAlert.dismiss()
                }
            }
            
            // open
            myAlert.animateScale(true, anchorPoint: point, parentView: controller.view, frame: frame)
            
        } else { // normal alert animation
            myAlert.dismissAnimation = .fade
            
            if !isConfirm && !hasOkButton {
                myAlert.onTapAnywhere = {
                    myAlert.dismiss()
                }
            }
        }
    }
}
