//
//  AddButtonHelper.swift
//  shoppin
//
//  Created by ischuetz on 30/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

import Providers

class AddButtonHelper: NSObject {

    fileprivate var addButton: UIView?
    
    fileprivate var keyboardHeight: CGFloat = 216
    
    fileprivate weak var parentView: UIView?
    
    fileprivate let buttonHeight: CGFloat = Theme.submitViewHeight
    
    fileprivate var tapHandler: VoidFunction?
    
    fileprivate var centerYOverride: CGFloat? // quick fix - if it's necessary to override the default centerY which is calculated in this helper. Doesn't include -keyboardHeight and buttonHeight! keyboardHeight and buttonHeight/2  are subtracted from this value TODO better solution to position the button correctly in all cases. The default is just the result of trial and error. EDIT: better explanation: this is the reference view frame used to calculate the center!

    fileprivate var isObserving: Bool = false

    init(parentView: UIView, overrideCenterY: CGFloat? = nil, tapHandler: VoidFunction?) {
        
        self.parentView = parentView
        self.tapHandler = tapHandler
        self.centerYOverride = overrideCenterY
        
        super.init()
    }
    
    func addObserver() {
        isObserving = true
        NotificationCenter.default.addObserver(self, selector:#selector(AddButtonHelper.keyboardWillChangeFrame(_:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(AddButtonHelper.keyboardWillDisappear(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func removeObserver() {
        NotificationCenter.default.removeObserver(self)
        isObserving = false
    }

    func addObserverSafe() {
        if !isObserving {
            addObserver()
        }
    }

    @objc func keyboardWillChangeFrame(_ notification: Foundation.Notification) {
        if let userInfo = (notification as NSNotification).userInfo {
            if let frame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
//                logger.v("keyboardWillChangeFrame, frame: \(frame)")
                keyboardHeight = frame.height
            } else {
                logger.w("Couldn't retrieve keyboard size from user info")
            }
        } else {
            logger.w("Notification has no user info")
        }
        animateVisible(true)
    }
    
    @objc func keyboardWillDisappear(_ notification: Foundation.Notification) {
        // when showing validation popup the keyboard disappears so we have to remove the button - otherwise it looks weird
//        logger.w("add button - Keyboard will disappear - hiding")
        animateVisible(false)
    }
    
    
    // overrideKeyboardHeight: sometimes when calling show add button animation, AddButtonHelper hasn't had the opportunity to store the keyboard height yet. This happens when e.g. the keyboard was already open before switching to the controller where we add the button helper - in this case keyboardWillChangeFrame is never called and when we call animateVisible it will use the default hardcoded height which can be wrong. So in these cases we allow to pass the keyboard height manually. This we can "catch" keyboard height wherever the keyboard is opened and pass it here. Not a good solution of course, this complete class needs re-thinking.
    func animateVisible(_ visible: Bool, overrideKeyboardHeight: CGFloat? = nil) {
        if let centerY = centerY(visible, overrideKeyboardHeight: overrideKeyboardHeight) {
            animate(centerY, removeOnFinish: !visible)
        } else {
            logger.w("No center y")
        }
    }
    
    fileprivate func animate(_ endY: CGFloat, removeOnFinish: Bool) {
        
        if addButton == nil {
            addAddButton(false)
            parentView?.setNeedsLayout()
            parentView?.layoutIfNeeded()
        }
        guard let addButton = addButton else {logger.w("No add button, can't animate"); return}

        if endY != addButton.center.y { // animate only if there's a change in the position (open, close keyboard / changed between normal and emoji keyboard)
            
            UIView.animate(withDuration: 0.4, animations: {
//                logger.v("Animating add button to \(endY)")
                addButton.center = addButton.center.copy(y: endY)
                }, completion: {[weak self] finished in
                    if removeOnFinish {
//                        logger.v("Finish animation, removing add button")
                        self?.addButton?.removeFromSuperview()
                        self?.addButton = nil
                    }
                }
            )
        }
    }
    
    fileprivate func centerY(_ visible: Bool, overrideKeyboardHeight: CGFloat? = nil) -> CGFloat? {
        guard let window = parentView?.window else {logger.w("No parentView: \(String(describing: parentView)) or window, can't calculate button's center"); return nil}
        
        let keyboardHeight = overrideKeyboardHeight ?? self.keyboardHeight
        
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
        guard let window = parentView?.window else {logger.w("No parentView: \(String(describing: parentView)) or window, can't calculate button's center"); return nil}

        return window.frame.height - keyboardHeight - buttonHeight / 2
    }
    
    fileprivate func addAddButton(_ visible: Bool = true) {
        if let parentView = parentView, let window = parentView.window, let centerY = centerY(visible) {
            let frameY = centerY - buttonHeight / 2
            let addButton = AddItemViewNew(frame: CGRect(x: 0, y: frameY, width: parentView.frame.width, height: buttonHeight)) {[weak self] in
                self?.tapHandler?()
            }
            
            self.addButton = addButton
            parentView.addSubview(addButton)
            
            addButton.center = addButton.center.copy(y: window.frame.height + buttonHeight)
            addButton.setNeedsLayout()
            addButton.layoutIfNeeded()
            
//            animateVisible(true)
            parentView.bringSubview(toFront: addButton)

        } else {
            logger.w("No parent view: \(String(describing: parentView)) or window: \(String(describing: parentView?.window)) for add button")
        }
    }
}
