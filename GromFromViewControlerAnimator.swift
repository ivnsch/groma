//
//  GromFromViewControlerAnimator.swift
//  shoppin
//
//  Created by Ivan Schuetz on 22/01/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit

import Providers

// TODO use a transition? either way refactor all this... 
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
    
    func openWithBGImproved(button: UIView? = nil, srcView: UIView, contentFrame: CGRect, controllerCreator: (() -> UIViewController?)? = nil, onFinish: (() -> Void)? = nil) {
        if button != nil {
            self.button = button
        }
        
        if controllerCreator != nil {
            self.controllerCreator = controllerCreator
        }
        
        guard let parent = parent, let button = button, let controllerCreator = self.controllerCreator else {logger.e("No fields"); return}
        guard let controller = controllerCreator() else {logger.e("Couldn't create controller"); return}
        self.controller = controller

        let buttonPointInParent = parent.view.convert(CGPoint(x: button.center.x, y: button.center.y), from: srcView)

        let navBarOffset: CGFloat = Theme.navBarHeight
        
        let parentWidth = parent.view.frame.width
        let parentHeight = parent.view.frame.height
        let parentFrame = CGRect(x: 0, y: 0, width: parentWidth, height: parentHeight)
        
        let targetFrame = CGRect(x: parentFrame.origin.x, y: parentFrame.origin.y + Theme.navBarHeight, width: parentFrame.width, height: parentFrame.height - navBarOffset)

        let backgroundView = HandlingButton()
        backgroundView.tapHandler = {[weak self] in
            self?.close()
        }
        self.backgroundView = backgroundView

        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        backgroundView.frame = targetFrame
        parent.addChildViewController(controller)
        parent.view.addSubview(backgroundView)
        
        
        controller.view.frame = contentFrame
        backgroundView.addSubview(controller.view)

        let fractionX = (buttonPointInParent.x) / (parentWidth)
        let fractionY = (buttonPointInParent.y - navBarOffset) / (parentHeight - navBarOffset)
        
        backgroundView.layer.anchorPoint = CGPoint(x: fractionX, y: fractionY)
        backgroundView.frame = targetFrame
        backgroundView.alpha = 0

        backgroundView.transform = backgroundView.transform.scaledBy(x: 0.1, y: 0.1)
        
        UIView.animate(withDuration: 0.3, animations: {
            backgroundView.transform = CGAffineTransform(scaleX: 1, y: 1)
            backgroundView.alpha = 1
            onFinish?()
        })
    }
    
    func openWithBGImproved2(button: UIView? = nil, srcView: UIView, contentFrame: CGRect, controllerCreator: (() -> UIViewController?)? = nil, onFinish: (() -> Void)? = nil) {
        if button != nil {
            self.button = button
        }
        
        if controllerCreator != nil {
            self.controllerCreator = controllerCreator
        }
        
        guard let parent = parent, let button = button, let controllerCreator = self.controllerCreator else {logger.e("No fields"); return}
        guard let controller = controllerCreator() else {logger.e("Couldn't create controller"); return}
        self.controller = controller
        
        let buttonPointInParent = parent.view.convert(CGPoint(x: button.center.x, y: button.center.y), from: srcView)
        
        let navBarOffset: CGFloat = Theme.navBarHeight
        
        let parentWidth = parent.view.frame.width
        let parentHeight = parent.view.frame.height
        let parentFrame = CGRect(x: 0, y: 0, width: parentWidth, height: parentHeight)
        
        let targetFrame = CGRect(x: parentFrame.origin.x, y: parentFrame.origin.y + Theme.navBarHeight, width: parentFrame.width, height: parentFrame.height - navBarOffset)
        
        let backgroundView = HandlingButton()
        backgroundView.tapHandler = {[weak self] in
            self?.close()
        }
        self.backgroundView = backgroundView
        
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        backgroundView.frame = targetFrame
        parent.addChildViewController(controller)
        parent.view.addSubview(backgroundView)
        
        
        controller.view.frame = contentFrame
        parent.view.addSubview(controller.view)
        
        let fractionX = (buttonPointInParent.x) / (parentWidth)
        let fractionY = (buttonPointInParent.y - navBarOffset) / (parentHeight - navBarOffset)
        
        controller.view.layer.anchorPoint = CGPoint(x: fractionX, y: fractionY)
        controller.view.frame = targetFrame
        backgroundView.alpha = 0
        //controller.view.alpha = 0
        
        controller.view.transform = controller.view.transform.scaledBy(x: 0.1, y: 0.1)
        
        UIView.animate(withDuration: 0.3, animations: {
            controller.view.transform = CGAffineTransform(scaleX: 1, y: 1)
            //backgroundView.alpha = 1
            onFinish?()
        })
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
        
        guard let parent = parent, let button = button, let currentController = currentController, let controllerCreator = self.controllerCreator else {logger.e("No fields"); return}
        guard let controller = controllerCreator() else {logger.e("Couldn't create controller"); return}
        
        self.controller = controller
        
        let topBarHeight: CGFloat = addTopBarHeightToY ? Theme.navBarHeight : 0
        
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
    
    
    // Simplified (and working) version of above for when there's not background overlay
    func openNoOverlay(button: UIView? = nil, frame: CGRect? = nil, inset: Insets = (left: 0, top: 0, right: 0, bottom: 0), addTopBarHeightToY: Bool = true, scrollOffset: CGFloat = 0, controllerCreator: (() -> UIViewController?)? = nil, onFinish: (() -> Void)? = nil) {
        
        if button != nil {
            self.button = button
        }
        
        if controllerCreator != nil {
            self.controllerCreator = controllerCreator
        }
        
        guard let parent = parent, let button = button, let currentController = currentController, let controllerCreator = self.controllerCreator else {logger.e("No fields"); return}
        guard let controller = controllerCreator() else {logger.e("Couldn't create controller"); return}
        
        self.controller = controller
        
        let topBarHeight: CGFloat = addTopBarHeightToY ? Theme.navBarHeight : 0
        
        controller.view.frame = CGRect(x: 0, y: topBarHeight, width: parent.view.frame.width, height: parent.view.frame.height - topBarHeight)

        let controllerViewHeight = frame?.height ?? controller.view.height - inset.top - inset.bottom
        
  
        controller.view.frame = frame ?? CGRect(x: 0 + inset.left, y: inset.top, width: controller.view.width - inset.left - inset.right, height: controllerViewHeight)
        
        parent.addChildViewController(controller)
        parent.view.addSubview(controller.view)

        let buttonPointInParent = parent.view.convert(CGPoint(x: button.center.x, y: button.center.y - scrollOffset - topBarHeight), from: currentController.view)
        let fractionX = (buttonPointInParent.x) / (controller.view.width)
        let fractionY = (buttonPointInParent.y) / (controller.view.height)
        controller.view.layer.anchorPoint = CGPoint(x: fractionX, y: fractionY)
        
        controller.view.frame = CGRect(x: 0, y: topBarHeight, width: parent.view.frame.width, height: parent.view.frame.height - topBarHeight)
        controller.view.height = controllerViewHeight // hack - transparent overlay blocks touch and user interaction doesn't seem to be useful to avoid this
        
        
        controller.view.transform = CGAffineTransform(scaleX: 0, y: 0)
        
        UIView.animate(withDuration: 0.3, animations: {
            controller.view.transform = CGAffineTransform(scaleX: 1, y: 1)
            controller.view.alpha = 1
            onFinish?()
        })
    }
    
    func close(onFinish: (() -> Void)? = nil) {
        
        guard let controller = controller, let button = button else {logger.e("Fields missing, controller: \(String(describing: self.controller)), button: \(String(describing: self.button))"); return}

        UIView.animate(withDuration: 0.3, animations: {
            
            if let backgroundView = self.backgroundView {
                backgroundView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
                backgroundView.alpha = 0
            } else {
                controller.view.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
                controller.view.alpha = 0
            }
            
            
        }, completion: {finished in
            self.controller = nil
            controller.removeFromParentViewController()
            controller.view.removeFromSuperview()
            self.backgroundView?.removeFromSuperview()
            
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










// Simplified version of above. Only for UIView
class GromFromViewAnimator2 {
    
    weak var button: UIView?
    weak var parent: UIView?
    
    var controllerCreator: (() -> UIView?)?
    fileprivate(set) weak var view: UIView?
    
    var isShowing: Bool {
        return view != nil
    }
    
    var animateButtonAtEnd = true
    
    init(parent: UIView, animateButtonAtEnd: Bool = true, controllerCreator: (() -> UIView)? = nil) {
        self.parent = parent
        self.controllerCreator = controllerCreator
        self.animateButtonAtEnd = animateButtonAtEnd
    }
    
    /// Scroll offset: If button is in a scrollable view (table view, collection view) current content view offset
    /// frame has priority over inserts. If frame is passed, inset is ignored.
    func open(button: UIView? = nil, frame: CGRect, onFinish: (() -> Void)? = nil) {
        
        if button != nil {
            self.button = button
        }
        
        guard let button = button, let parent = parent, let controllerCreator = self.controllerCreator else {logger.e("No fields"); return}
        guard let view = controllerCreator() else {logger.e("Couldn't create controller"); return}
        
        self.view = view

        view.frame = frame
        
        view.center = button.center
        
        parent.addSubview(view)
        

        view.transform = CGAffineTransform(scaleX: 0.000001, y: 0.000001)
        UIView.animate(withDuration: 0.3, animations: {
            button.backgroundColor = Theme.lightBlue // TODO not here
            view.transform = CGAffineTransform(scaleX: 1, y: 1)
            view.alpha = 1
            view.center = frame.center
            onFinish?()
        })
    }
    
    func close(onFinish: (() -> Void)? = nil) {
        
        guard let view = view, let button = button else {logger.e("Fields missing, view: \(String(describing: self.view)), button: \(String(describing: self.button))"); return}
        
        UIView.animate(withDuration: 0.3, animations: {
            button.backgroundColor = UIColor.white // TODO not here
            view.transform = CGAffineTransform(scaleX: 0.000001, y: 0.000001)
            view.center = button.center
            view.alpha = 0
            
        }, completion: {finished in
            self.view = nil
            view.removeFromSuperview()
            
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

