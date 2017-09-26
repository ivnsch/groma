//
//  SwipeToDeleteHelper.swift
//  shoppin
//
//  Created by Ivan Schuetz on 03/03/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit


protocol SwipeToDeleteHelperDelegate: class {
    var isSwipeToDeleteEnabled: Bool {get}
    func onOpen(_ open: Bool)
}

class SwipeToDeleteHelper: NSObject, UIGestureRecognizerDelegate {
    
    fileprivate weak var parentView: UIView!
    fileprivate weak var button: UIView!
    fileprivate weak var leftLayoutConstraint: NSLayoutConstraint!
    fileprivate weak var rightLayoutConstraint: NSLayoutConstraint!
    
    fileprivate var panRecognizer: UIPanGestureRecognizer!
    fileprivate var panStartPoint: CGPoint!
    fileprivate var startingLeftLayoutConstraint: CGFloat!
    
    var limit: CGFloat = 120
    
    weak var delegate: SwipeToDeleteHelperDelegate?
    
    var isOpen: Bool {
        return leftLayoutConstraint.constant != 0
    }
    
    init(parentView: UIView, button: UIView, leftLayoutConstraint: NSLayoutConstraint, rightLayoutConstraint: NSLayoutConstraint, cancelTouches: Bool = true) {
        super.init()
        
        self.parentView = parentView
        self.button = button
        self.leftLayoutConstraint = leftLayoutConstraint
        self.rightLayoutConstraint = rightLayoutConstraint
        
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(CellUncoverer.onPanCell(_:)))
        panRecognizer.delegate = self
        panRecognizer.cancelsTouchesInView = cancelTouches
        self.button.addGestureRecognizer(panRecognizer)
        self.panRecognizer = panRecognizer
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func onPanCell(_ recognizer: UIPanGestureRecognizer) {
        
        
        var movingHorizontally = false
        if let panStartPoint = self.panStartPoint {
            movingHorizontally = fabsf(Float(panStartPoint.y)) < fabsf(Float(panStartPoint.x))
        }
        
        switch recognizer.state {
        case .began: break
        case .changed:
            
            guard delegate?.isSwipeToDeleteEnabled ?? false else {return}  // here (instead of in .began) because of interaction with SwipeToIncrementHelper
            
            if panStartPoint == nil {
                self.panStartPoint = recognizer.translation(in: self.button)
                self.startingLeftLayoutConstraint = self.leftLayoutConstraint.constant
            }
            
            if movingHorizontally {
                let currentPoint = recognizer.translation(in: parentView)
                let deltaX = abs(currentPoint.x - self.panStartPoint.x)
                let panningLeft = currentPoint.x < self.panStartPoint.x
                
                if panningLeft {
                    leftLayoutConstraint.constant = startingLeftLayoutConstraint - deltaX
                    rightLayoutConstraint.constant = -leftLayoutConstraint.constant
                }
            }
            
        case .ended: fallthrough
        case .cancelled:
            panStartPoint = nil
            startingLeftLayoutConstraint = nil
            
            snap(movingHorizontally: movingHorizontally)

        default:
            print("Not handled")
        }
    }
    
    fileprivate func snap(movingHorizontally: Bool) {
        if movingHorizontally {
            setOpen(abs(leftLayoutConstraint.constant) >= limit, animated: true)
        }
    }
    
    func setOpen(_ open: Bool, animated: Bool = true) {

        if open {
            leftLayoutConstraint.constant = -parentView.width
        } else {
            leftLayoutConstraint.constant = 0
        }
        rightLayoutConstraint.constant = -leftLayoutConstraint.constant
        
        animIf(animated, Theme.defaultAnimDuration, {[weak self] in
            self?.parentView.layoutIfNeeded()
        }) {[weak self] in
            self?.delegate?.onOpen(open)
        }
    }
    
}
