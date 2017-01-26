//
//  GromFromViewControlerAnimator.swift
//  shoppin
//
//  Created by Ivan Schuetz on 22/01/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

// TODO use a transition?
struct GromFromViewControlerAnimator {
    
    weak var parent: UIViewController?
    weak var button: UIView?
    weak var currentController: UIViewController?
    
    var controllerCreator: (() -> UIViewController?)?
    fileprivate weak var controller: UIViewController?
    
    var isShowing: Bool {
        return controller != nil
    }
    
    init(parent: UIViewController, currentController: UIViewController, controllerCreator: (() -> UIViewController)? = nil) {
        self.parent = parent
        self.currentController = currentController
        self.controllerCreator = controllerCreator
    }
    
    mutating func open(button: UIView? = nil, controllerCreator: (() -> UIViewController?)? = nil, onFinish: (() -> Void)? = nil) {
        
        if button != nil {
            self.button = button
        }
        
        if controllerCreator != nil {
            self.controllerCreator = controllerCreator
        }
        
        guard let parent = parent, let button = button, let currentController = currentController, let controllerCreator = self.controllerCreator else {QL4("No fields"); return}
        guard let controller = controllerCreator() else {QL4("Couldn't create controller"); return}
        
        self.controller = controller
        
        let topBarHeight: CGFloat = 64
        
        controller.view.frame = CGRect(x: 0, y: topBarHeight, width: parent.view.frame.width, height: parent.view.frame.height - topBarHeight)
        
        parent.addChildViewControllerAndView(controller) // add to superview (lists controller) because it has to occupy full space (navbar - tab)
        
        let buttonPointInParent = parent.view.convert(CGPoint(x: button.center.x, y: button.center.y - topBarHeight), from: currentController.view)
        let fractionX = buttonPointInParent.x / parent.view.frame.width
        let fractionY = buttonPointInParent.y / (parent.view.frame.height - topBarHeight)
        
        controller.view.layer.anchorPoint = CGPoint(x: fractionX, y: fractionY)
        
        controller.view.frame = CGRect(x: 0, y: topBarHeight, width: parent.view.frame.width, height: parent.view.frame.height - topBarHeight)
        
        controller.view.transform = CGAffineTransform(scaleX: 0, y: 0)
        
        UIView.animate(withDuration: 0.3, animations: {
            controller.view.transform = CGAffineTransform(scaleX: 1, y: 1)
            
            onFinish?()
        })
    }
    
    mutating func close(onFinish: (() -> Void)? = nil) {
        
        guard let controller = controller, let button = button else {QL4("Fields missing, controller: \(self.controller), button: \(self.button)"); return}
        
        var selfCopy = self // http://stackoverflow.com/a/38060448/930450
        
        UIView.animate(withDuration: 0.3, animations: {
            controller.view.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
            
        }, completion: {finished in
            selfCopy.controller = nil
            controller.removeFromParentViewControllerWithView()
            
            onFinish?() // we call this before the short button animation since it doesn't belong to the main flow
            
            UIView.animate(withDuration: 0.15, animations: {
                button.transform = CGAffineTransform(scaleX: 2, y: 2)
                UIView.animate(withDuration: 0.15, animations: {
                    button.transform = CGAffineTransform(scaleX: 1, y: 1)
                    
                    
                })
            })
        })
    }
}
