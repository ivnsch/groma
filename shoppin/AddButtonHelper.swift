//
//  AddButtonHelper.swift
//  shoppin
//
//  Created by ischuetz on 30/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

class AddButtonHelper: NSObject {

    fileprivate var addButton: UIButton?
    
    fileprivate var keyboardHeight: CGFloat = 216
    
    fileprivate weak var parentView: UIView?
    
    fileprivate let buttonHeight: CGFloat = 40
    
    fileprivate var tapHandler: VoidFunction?
    
    fileprivate var centerYOverride: CGFloat? // quick fix - if it's necessary to override the default centerY which is calculated in this helper. Doesn't include -keyboardHeight and buttonHeight! keyboardHeight and buttonHeight/2  are subtracted from this value TODO better solution to position the button correctly in all cases. The default is just the result of trial and error.
    
    init(parentView: UIView, overrideCenterY: CGFloat? = nil, tapHandler: VoidFunction?) {
        
        self.parentView = parentView
        self.tapHandler = tapHandler
        self.centerYOverride = overrideCenterY
        
        super.init()
    }
    
    func addObserver() {
        NotificationCenter.default.addObserver(self, selector:#selector(AddButtonHelper.keyboardWillChangeFrame(_:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(AddButtonHelper.keyboardWillDisappear(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func removeObserver() {
        NotificationCenter.default.removeObserver(self)
    }
    
    func keyboardWillChangeFrame(_ notification: Foundation.Notification) {
        if let userInfo = (notification as NSNotification).userInfo {
            if let frame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                QL1("keyboardWillChangeFrame, frame: \(frame)")
                keyboardHeight = frame.height
            } else {
                QL3("Couldn't retrieve keyboard size from user info")
            }
        } else {
            QL3("Notification has no user info")
        }
        animateVisible(true)
    }
    
    func keyboardWillDisappear(_ notification: Foundation.Notification) {
        // when showing validation popup the keyboard disappears so we have to remove the button - otherwise it looks weird
        QL3("add button - Keyboard will disappear - hiding")
        animateVisible(false)
    }
    
    func animateVisible(_ visible: Bool) {
        if let centerY = centerY(visible) {
            animate(centerY, removeOnFinish: !visible)
        } else {
            QL3("No center y")
        }
    }
    
    fileprivate func animate(_ endY: CGFloat, removeOnFinish: Bool) {
        
        if addButton == nil {
            addAddButton(false)
            parentView?.setNeedsLayout()
            parentView?.layoutIfNeeded()
        }
        guard let addButton = addButton else {QL3("No add button, can't animate"); return}

        if endY != addButton.center.y { // animate only if there's a change in the position (open, close keyboard / changed between normal and emoji keyboard)
            
            UIView.animate(withDuration: 0.4, animations: {
                QL1("Animating add button to \(endY)")
                addButton.center = addButton.center.copy(y: endY)
                }, completion: {[weak self] finished in
                    if removeOnFinish {
                        QL3("Finish animation, removing add button")
                        self?.addButton?.removeFromSuperview()
                        self?.addButton = nil
                    }
                }
            )
        }
    }
    
    fileprivate func centerY(_ visible: Bool) -> CGFloat? {
        guard let window = parentView?.window else {QL3("No parentView: \(parentView) or window, can't calculate button's center"); return nil}
        if let centerYOverride = centerYOverride {
            switch visible {
            case true: return centerYOverride - keyboardHeight - buttonHeight / 2
            case false: return window.frame.height + buttonHeight
            }
        } else {
            switch visible {
            case true: return window.frame.height - keyboardHeight - buttonHeight / 2
            case false: return window.frame.height + buttonHeight
            }
        }
    }
    
    fileprivate func center(_ keyboardHeight: CGFloat) -> CGFloat? {
        guard let window = parentView?.window else {QL3("No parentView: \(parentView) or window, can't calculate button's center"); return nil}

        return window.frame.height - keyboardHeight - buttonHeight / 2
    }
    
    fileprivate func addAddButton(_ visible: Bool = true) {
        if let parentView = parentView, let window = parentView.window, let centerY = centerY(visible) {
            let frameY = centerY - buttonHeight / 2
            let addButton = AddItemButton(frame: CGRect(x: 0, y: frameY, width: parentView.frame.width, height: buttonHeight))
            self.addButton = addButton
            parentView.addSubview(addButton)
            
            addButton.center = addButton.center.copy(y: window.frame.height + buttonHeight)
            addButton.setNeedsLayout()
            addButton.layoutIfNeeded()
            
//            animateVisible(true)
            parentView.bringSubview(toFront: addButton)
            addButton.tapHandler = {[weak self] in
                self?.tapHandler?()
            }
        } else {
            QL3("No parent view: \(parentView) or window: \(parentView?.window) for add button")
        }
    }
}
