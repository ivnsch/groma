//
//  AlertPopup.swift
//  shoppin
//
//  Created by ischuetz on 15/09/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

import Providers

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
    static func showCustom(title: String? = nil, message: String, controller: UIViewController, frame: CGRect? = nil, okMsg: String = trans("popup_button_ok"), confirmMsg: String = trans("popup_button_ok"), cancelMsg: String = trans("popup_button_cancel"), hasOkButton: Bool = false, isConfirm: Bool = false, rootControllerStartPoint: CGPoint? = nil, okAction: VoidFunction? = nil, onDismiss: VoidFunction? = nil) -> MyAlertWrapper? {
        
        guard controller.view.viewWithTag(ViewTags.NotePopup) == nil else {logger.d("Already showing popup, return"); return nil} // TODO is this really necessary? (maybe when tap very quickly multiple times to open)
        
        let myAlert = Bundle.loadView("MyAlert", owner: self) as! MyAlert
        
        
        
        myAlert.translatesAutoresizingMaskIntoConstraints = true
        myAlert.frame = frame ?? controller.view.bounds
        
        // It was not possible to get bg working correctly inside MyAlert view, so here. Attempt consisted in having it as sibling of content view & content view being a wrapper around current content view, transparent and with same size as bg / parent, but the autolayout used inside content breaks the (non-autolayout)positioning of the wrapper. With translatesAutoresizingMaskIntoConstraints = false, etc.
        let bg = UIView(frame: myAlert.frame)
        bg.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        controller.view.addSubview(bg)

        func setBGVisible(_ visible: Bool, removeIfInvisible: Bool = true) {
            bg.alpha = visible ? 0 : 1
            anim {
                bg.alpha = visible ? 1 : 0
            }
            
            anim(Theme.defaultAnimDuration, { 
                bg.alpha = visible ? 1 : 0
            }) {
                if removeIfInvisible {
                    if !visible {
                        bg.removeFromSuperview()
                    }
                }
            }
        }
        
        setBGVisible(true)
        
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
//        myAlert.enableDismissWithSwipe()
        
        myAlert.onOk = okAction
        
        // "grow from point" animation
        if let point = rootControllerStartPoint {
            
            myAlert.dismissAnimation = .none
            
            // close
            myAlert.onTapAnywhere = {
                myAlert.animateScale(false, anchorPoint: point, parentView: controller.view, frame: frame) {
                    myAlert.dismiss()
                    setBGVisible(false)
                }
            }
            
            // open
            myAlert.animateScale(true, anchorPoint: point, parentView: controller.view, frame: frame)
            
        } else { // normal alert animation
            myAlert.dismissAnimation = .fade
            
            if !isConfirm && !hasOkButton {
                myAlert.onTapAnywhere = {
                    myAlert.dismiss()
                    setBGVisible(false)
                }
            }
        }
        
        return MyAlertWrapper(myAlert: myAlert, bg: bg)
    }
}


struct MyAlertWrapper {
    let myAlert: MyAlert
    let bg: UIView
    
    func dismiss() {
        myAlert.dismiss()
        setBGVisible(false)
    }
    
    func setBGVisible(_ visible: Bool, removeIfInvisible: Bool = true) {
        bg.alpha = visible ? 0 : 1
        let copy = self
        anim {
            copy.bg.alpha = visible ? 1 : 0
        }
        
        anim(Theme.defaultAnimDuration, {
            copy.bg.alpha = visible ? 1 : 0
        }) {
            if removeIfInvisible {
                if !visible {
                    copy.bg.removeFromSuperview()
                }
            }
        }
    }
}
