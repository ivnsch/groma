//
//  GromFromViewControlerAnimator.swift
//  shoppin
//
//  Created by Ivan Schuetz on 22/01/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs
import Providers

// TODO use a transition?
class GromFromViewControlerAnimator {
    
    weak var parent: UIViewController?
    weak var button: UIView?
    weak var currentController: UIViewController?
    
    var controllerCreator: (() -> UIViewController?)?
    fileprivate(set) weak var controller: UIViewController?
    
    fileprivate weak var backgroundView: UIView?
    
    var isShowing: Bool {
        return controller != nil
    }
    
    var animateButtonAtEnd = true
    
    init(parent: UIViewController, currentController: UIViewController, animateButtonAtEnd: Bool = true, controllerCreator: (() -> UIViewController)? = nil) {
        self.parent = parent
        self.currentController = currentController
        self.controllerCreator = controllerCreator
        self.animateButtonAtEnd = animateButtonAtEnd
    }
    
    /// Scroll offset: If button is in a scrollable view (table view, collection view) current content view offset
    /// frame has priority over inserts. If frame is passed, inset is ignored.
    func open(button: UIView? = nil, frame: CGRect? = nil, inset: Insets = (left: 0, top: 0, right: 0, bottom: 0), addTopBarHeightToY: Bool = true, scrollOffset: CGFloat = 0, addOverlay: Bool = true, controllerCreator: (() -> UIViewController?)? = nil, onFinish: (() -> Void)? = nil) {
        
        if button != nil {
            self.button = button
        }
        
        if controllerCreator != nil {
            self.controllerCreator = controllerCreator
        }
        
        guard let parent = parent, let button = button, let currentController = currentController, let controllerCreator = self.controllerCreator else {QL4("No fields"); return}
        guard let controller = controllerCreator() else {QL4("Couldn't create controller"); return}
        
        self.controller = controller
        
        let topBarHeight: CGFloat = addTopBarHeightToY ? 64 : 0
        
        let backgroundView = HandlingButton(frame: CGRect(x: 0, y: topBarHeight, width: parent.view.frame.width, height: parent.view.frame.height - topBarHeight))
        backgroundView.alpha = 0

        self.backgroundView = backgroundView
        
        let controllerViewHeight = frame?.height ?? backgroundView.height - inset.top - inset.bottom
        
        // Quick & dirty: addOverlay == false means that we make the overlay transparent and not interactive. Not adding the overlay would require more time to implement.
        if addOverlay {
            backgroundView.tapHandler = {[weak self] in
                self?.close()
            }
            backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        } else {
            backgroundView.backgroundColor = UIColor.clear
//            backgroundView.isUserInteractionEnabled = false
            backgroundView.height = controllerViewHeight // hack - transparent overlay blocks touch and user interaction doesn't seem to be useful to avoid this
        }
//        controller.view.isUserInteractionEnabled = true // ensure this is enabled if we had to disable it in background view
        
        controller.view.frame = frame ?? CGRect(x: 0 + inset.left, y: inset.top, width: backgroundView.width - inset.left - inset.right, height: controllerViewHeight)
        
        backgroundView.addSubview(controller.view)
        parent.addChildViewController(controller)
        parent.view.addSubview(backgroundView)

        
//        parent.addChildViewControllerAndView(controller) // add to superview (lists controller) because it has to occupy full space (navbar - tab)
        
        let buttonPointInParent = parent.view.convert(CGPoint(x: button.center.x, y: button.center.y - scrollOffset - topBarHeight), from: currentController.view)
//        let fractionX = (buttonPointInParent.x - inset.x) / (controller.view.width)
//        let fractionY = (buttonPointInParent.y - inset.y) / (controller.view.height)
        let fractionX = (buttonPointInParent.x) / (backgroundView.width)
        let fractionY = (buttonPointInParent.y) / (backgroundView.height)
        backgroundView.layer.anchorPoint = CGPoint(x: fractionX, y: fractionY)
        
//        controller.view.frame = CGRect(x: 0 + inset.x, y: topBarHeight + inset.y, width: parent.view.frame.width - inset.x * 2, height: parent.view.frame.height - topBarHeight - inset.y * 2)
        backgroundView.frame = CGRect(x: 0, y: topBarHeight, width: parent.view.frame.width, height: parent.view.frame.height - topBarHeight)
        backgroundView.height = controllerViewHeight // hack - transparent overlay blocks touch and user interaction doesn't seem to be useful to avoid this
        
        
        
//        controller.view.transform = CGAffineTransform(scaleX: 0, y: 0)
        backgroundView.transform = CGAffineTransform(scaleX: 0, y: 0)
        
        UIView.animate(withDuration: 0.3, animations: {
//            controller.view.transform = CGAffineTransform(scaleX: 1, y: 1)
            backgroundView.transform = CGAffineTransform(scaleX: 1, y: 1)
            backgroundView.alpha = 1
            onFinish?()
        })
    }
    
    func close(onFinish: (() -> Void)? = nil) {
        
        guard let controller = controller, let button = button else {QL4("Fields missing, controller: \(self.controller), button: \(self.button)"); return}
        guard let backgroundView = backgroundView else {QL4("No brackground view"); return}
        
//        var selfCopy = self // http://stackoverflow.com/a/38060448/930450
        
        UIView.animate(withDuration: 0.3, animations: {
            backgroundView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
            backgroundView.alpha = 0
            
        }, completion: {finished in
            self.controller = nil
            controller.removeFromParentViewController()
            backgroundView.removeFromSuperview()
            
            onFinish?() // we call this before the short button animation since it doesn't belong to the main flow
            
            if self.animateButtonAtEnd {
                UIView.animate(withDuration: 0.15, animations: {
                    button.transform = CGAffineTransform(scaleX: 2, y: 2)
                    UIView.animate(withDuration: 0.15, animations: {
                        button.transform = CGAffineTransform(scaleX: 1, y: 1)
                    })
                })
            }
        })
    }
}
