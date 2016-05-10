//
//  CellUncoverer.swift
//  shoppin
//
//  Created by ischuetz on 09/04/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

protocol CellUncovererDelegate: class {
    func onOpen(open: Bool)
}

class CellUncoverer: NSObject, UIGestureRecognizerDelegate {
    
    private weak var parentView: UIView!
    private weak var button: UIView!
    private weak var leftLayoutConstraint: NSLayoutConstraint!
    
    private var panRecognizer: UIPanGestureRecognizer!
    private var panStartPoint: CGPoint!
    private var startingLeftLayoutConstraint: CGFloat!
    
    var allowOpen: Bool = false
    
    var stashViewWidth: CGFloat = 60
    
    weak var delegate: CellUncovererDelegate?
    
    init(parentView: UIView, button: UIView, leftLayoutConstraint: NSLayoutConstraint) {
        super.init()

        self.parentView = parentView
        self.button = button
        self.leftLayoutConstraint = leftLayoutConstraint
        
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(CellUncoverer.onPanCell(_:)))
        panRecognizer.delegate = self
        panRecognizer.cancelsTouchesInView = true
        self.button.addGestureRecognizer(panRecognizer)
        self.panRecognizer = panRecognizer
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func onPanCell(recognizer: UIPanGestureRecognizer) {
        
        guard allowOpen else {return}
        
        var movingHorizontally = false
        if let panStartPoint = self.panStartPoint {
            movingHorizontally = fabsf(Float(panStartPoint.y)) < fabsf(Float(panStartPoint.x))
        }
        
        switch recognizer.state {
        case .Began:
            self.panStartPoint = recognizer.translationInView(self.button)
            self.startingLeftLayoutConstraint = self.leftLayoutConstraint.constant
            
        case .Changed:
            if movingHorizontally {
                let currentPoint = recognizer.translationInView(parentView)
                let deltaX = abs(currentPoint.x - self.panStartPoint.x)
                let panningLeft = currentPoint.x < self.panStartPoint.x
                
                if panningLeft {
                    if deltaX < stashViewWidth {
                        leftLayoutConstraint.constant = startingLeftLayoutConstraint - deltaX
                    } else {
                        
                        leftLayoutConstraint.constant = startingLeftLayoutConstraint - ((stashViewWidth + (deltaX - stashViewWidth) / 2))
                    }
                } else {
                    leftLayoutConstraint.constant = min(0, startingLeftLayoutConstraint + deltaX)
                }
            }
            
        case .Ended:
            if movingHorizontally {
                if abs(leftLayoutConstraint.constant) < stashViewWidth {
                    leftLayoutConstraint.constant = 0
                } else if abs(leftLayoutConstraint.constant) >= stashViewWidth {
                    leftLayoutConstraint.constant = -stashViewWidth
                    delegate?.onOpen(true)
                }
                UIView.animateWithDuration(0.3) {[weak self] in
                    self?.parentView.layoutIfNeeded()
                }
            }
            
        case .Cancelled:
            if movingHorizontally {
                if leftLayoutConstraint.constant < stashViewWidth {
                    leftLayoutConstraint.constant = 0
                } else if leftLayoutConstraint.constant >= stashViewWidth {
                    leftLayoutConstraint.constant = -stashViewWidth
                    delegate?.onOpen(true)
                }
                UIView.animateWithDuration(0.3) {[weak self] in
                    self?.parentView.layoutIfNeeded()
                }
            }
            
        default:
            "Not handled"
        }
    }

    func setOpen(open: Bool, animated: Bool = true) {
        parentView.layoutIfNeeded()
        if open {
            leftLayoutConstraint.constant = -stashViewWidth
        } else {
            leftLayoutConstraint.constant = 0
        }
        UIView.animateWithDuration(0.3) {[weak self] in
            self?.parentView.layoutIfNeeded()
        }
    }

}

