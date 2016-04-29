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

    private var addButton: UIButton?
    
    private var keyboardHeight: CGFloat = 216
    
    private weak var parentView: UIView?
    
    private let buttonHeight: CGFloat = 40
    
    private var tapHandler: VoidFunction?
    
    private var centerYOverride: CGFloat? // quick fix - if it's necessary to override the default centerY which is calculated in this helper. Doesn't include -keyboardHeight and buttonHeight! keyboardHeight and buttonHeight/2  are subtracted from this value TODO better solution to position the button correctly in all cases. The default is just the result of trial and error.
    
    init(parentView: UIView, overrideCenterY: CGFloat? = nil, tapHandler: VoidFunction?) {
        
        self.parentView = parentView
        self.tapHandler = tapHandler
        self.centerYOverride = overrideCenterY
        
        super.init()
    }
    
    func addObserver() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"keyboardWillChangeFrame:", name: UIKeyboardWillChangeFrameNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"keyboardWillDisappear:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func removeObserver() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func keyboardWillChangeFrame(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            if let frame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue() {
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
    
    func keyboardWillDisappear(notification: NSNotification) {
        // when showing validation popup the keyboard disappears so we have to remove the button - otherwise it looks weird
        QL3("add button - Keyboard will disappear - hiding")
        animateVisible(false)
    }
    
    func animateVisible(visible: Bool) {
        if let centerY = centerY(visible) {
            animate(centerY, removeOnFinish: !visible)
        } else {
            QL3("No center y")
        }
    }
    
    private func animate(endY: CGFloat, removeOnFinish: Bool) {
        
        if addButton == nil {
            addAddButton(false)
            parentView?.setNeedsLayout()
            parentView?.layoutIfNeeded()
        }
        guard let addButton = addButton else {QL3("No add button, can't animate"); return}

        if endY != addButton.center.y { // animate only if there's a change in the position (open, close keyboard / changed between normal and emoji keyboard)
            
            UIView.animateWithDuration(0.1, animations: {
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
    
    private func centerY(visible: Bool) -> CGFloat? {
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
    
    private func center(keyboardHeight: CGFloat) -> CGFloat? {
        guard let window = parentView?.window else {QL3("No parentView: \(parentView) or window, can't calculate button's center"); return nil}

        return window.frame.height - keyboardHeight - buttonHeight / 2
    }
    
    private func addAddButton(visible: Bool = true) {
        if let parentView = parentView, window = parentView.window, centerY = centerY(visible) {
            let frameY = centerY - buttonHeight / 2
            let addButton = AddItemButton(frame: CGRectMake(0, frameY, parentView.frame.width, buttonHeight))
            self.addButton = addButton
            parentView.addSubview(addButton)
            
            addButton.center = addButton.center.copy(y: window.frame.height + buttonHeight)
            addButton.setNeedsLayout()
            addButton.layoutIfNeeded()
            
//            animateVisible(true)
            parentView.bringSubviewToFront(addButton)
            addButton.tapHandler = {[weak self] in
                self?.tapHandler?()
            }
        } else {
            QL3("No parent view: \(parentView) or window: \(parentView?.window) for add button")
        }
    }
}
