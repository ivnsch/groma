//
//  ContainerViewController.swift
//  shoppin
//
//  Created by ischuetz on 24.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit

enum SlideOutState {
    case Collapsed
//    case LeftPanelExpanded
    case RightPanelExpanded
}

@objc
protocol ItemsObserver {
    func itemsChanged()
}

protocol ItemsNotificator {
    func notifyItemUpdated(listItem:ListItem, sender:AnyObject)
}

protocol SideMenuManager {
    func setDoneItemsOpen(open:Bool)
}

protocol SideMenuObserver {
    func startSideMenuDrag()
    func changedSlideOutState(slideOutState: SlideOutState)
}


class ContainerViewController: UIViewController, ItemsNotificator, SideMenuManager {

    private var centerViewController: UINavigationController!
    private var rightViewController: DoneViewController!

    private let centerPanelExpandedOffset: CGFloat = 60
    
    var itemObservers:[ItemsObserver] = []

    var sideMenuObservers:[SideMenuObserver] = []
    
    
    var currentState: SlideOutState = .Collapsed {
        didSet {
            let shouldShowShadow = currentState != .Collapsed
            self.showShadowForCenterViewController(shouldShowShadow)
            
            if oldValue != currentState {
                self.sideMenuObservers.forEach {$0.changedSlideOutState(self.currentState)}
            }
        }
    }
    
    func notifyItemUpdated(listItem:ListItem, sender:AnyObject) {
        for itemObserver in self.itemObservers {
            if (sender !== (itemObserver as AnyObject)) { //don't notify the sender
                itemObserver.itemsChanged()
            }
        }
    }
    
    func setDoneItemsOpen(open: Bool) {
        self.addRightPanelViewController()
        self.animateRightPanel(shouldExpand: open)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let navigationViewController = UIStoryboard.navigationController()
        let viewControler = navigationViewController.viewControllers[0] as ViewController
        
        self.centerViewController = navigationViewController
        self.itemObservers.append(viewControler)
        self.sideMenuObservers.append(viewControler)

        viewControler.itemsNotificator = self
        viewControler.sideMenuManager = self
        self.addChildViewControllerAndView(centerViewController)
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: "handlePanGesture:")
        self.centerViewController.view.addGestureRecognizer(panGestureRecognizer)
    }
    
    func showShadowForCenterViewController(shouldShowShadow: Bool) {
        if (shouldShowShadow) {
            self.centerViewController.view.layer.shadowOpacity = 0.8
        } else {
            self.centerViewController.view.layer.shadowOpacity = 0.0
        }
    }
    
    
    func toggleRightPanel() {
        let notAlreadyExpanded = (currentState != .RightPanelExpanded)
        
        if notAlreadyExpanded {
            addRightPanelViewController()
        }

        animateRightPanel(shouldExpand: notAlreadyExpanded)
    }
    
    
    func addRightPanelViewController() {
        if (rightViewController == nil) {
            rightViewController = UIStoryboard.doneItemsViewController()
            self.itemObservers.append(rightViewController)
            self.sideMenuObservers.append(rightViewController)
            rightViewController.itemsNotificator = self
            rightViewController.view.backgroundColor = UIColor.whiteColor()

            self.view.insertSubview(rightViewController.view, atIndex: 0)
            rightViewController.view.setTranslatesAutoresizingMaskIntoConstraints(false)
            
            let views = ["view": rightViewController.view]
            for constraint in [
                "V:|[view]|",
                "H:|-(60)-[view]|"
                ] {
                self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(constraint, options: NSLayoutFormatOptions.allZeros, metrics: nil, views: views))
            }
        }
    }
    
    func animateRightPanel(#shouldExpand: Bool) {
        if (shouldExpand) {
            currentState = .RightPanelExpanded
            
            animateCenterPanelXPosition(targetPosition: -CGRectGetWidth(centerViewController.view.frame) + centerPanelExpandedOffset)
        } else {
            animateCenterPanelXPosition(targetPosition: 0) { _ in
                self.currentState = .Collapsed
                
//                self.rightViewController!.view.removeFromSuperview()
//                self.rightViewController = nil
            }
        }
    }
    
    func animateCenterPanelXPosition(#targetPosition: CGFloat, completion: ((Bool) -> Void)! = nil) {
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
            self.centerViewController.view.frame.origin.x = targetPosition
            }, completion: completion)
    }

    // MARK: Gesture recognizer
    
    func handlePanGesture(recognizer: UIPanGestureRecognizer) {
        // we can determine whether the user is revealing the left or right
        // panel by looking at the velocity of the gesture
        let gestureIsDraggingFromLeftToRight = (recognizer.velocityInView(view).x > 0)
        
//        println("velocity:\(recognizer.velocityInView(view).x) left to right:\(gestureIsDraggingFromLeftToRight)")
        
        
        switch(recognizer.state) {
        case .Began:
            
            self.sideMenuObservers.forEach {$0.startSideMenuDrag()}

            if (currentState == .Collapsed) {
                // If the user starts panning, and neither panel is visible
                // then show the correct panel based on the pan direction
                
                if (gestureIsDraggingFromLeftToRight) {
//                    addLeftPanelViewController()
                    showShadowForCenterViewController(true)

                } else {
                    addRightPanelViewController()
                }
                
            }
        case .Changed:
            // If the user is already panning, translate the center view controller's
            // view by the amount that the user has panned
            if (currentState == .RightPanelExpanded //while right expanded, allos swipe in both directions
                ||
                (!gestureIsDraggingFromLeftToRight //otherwise only gesture to open right menu -> swipe from right to left
                    && recognizer.translationInView(view).x < 0) //and only when the translation is negative, otherwise if user swipes to right and back to left in one gesture, we process the positive translation (to right) here
//                recognizer.view!.center.x < 180
//                    || currentState == .RightPanelExpanded
                ) {
            
//            println("---------------")
//            println(recognizer.view!.center.x)
//            println(recognizer.translationInView(view).x)
            
                
                    
                    
                recognizer.view!.center.x = recognizer.view!.center.x + recognizer.translationInView(view).x
                recognizer.setTranslation(CGPointZero, inView: view)
            }
            
        case .Ended:
            
            println("\nTouch ended!")
            
            // When the pan ends, check whether the left or right view controller is visible
//            if (leftViewController != nil) {
            if (false) {
                // animate the side panel open or closed based on whether the view has moved more or less than halfway
                let hasMovedGreaterThanHalfway = recognizer.view!.center.x > view.bounds.size.width
//                animateLeftPanel(shouldExpand: hasMovedGreaterThanHalfway)
            } else if (rightViewController != nil) {
                let hasMovedGreaterThanHalfway = recognizer.view!.center.x < 0
                animateRightPanel(shouldExpand: hasMovedGreaterThanHalfway)
            }
        default:
            break
        }
    }

}