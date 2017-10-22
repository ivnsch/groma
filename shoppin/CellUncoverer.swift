//
//  CellUncoverer.swift
//  shoppin
//
//  Created by ischuetz on 09/04/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

protocol CellUncovererDelegate: class {
    func onOpen(_ open: Bool)
}

class CellUncoverer: NSObject, UIGestureRecognizerDelegate {
    
    fileprivate weak var parentView: UIView!
    fileprivate weak var button: UIView!
    fileprivate weak var leftLayoutConstraint: NSLayoutConstraint!
    
    fileprivate var panRecognizer: UIPanGestureRecognizer!
    fileprivate var panStartPoint: CGPoint!
    fileprivate var startingLeftLayoutConstraint: CGFloat!
    
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
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @objc func onPanCell(_ recognizer: UIPanGestureRecognizer) {
        
        guard allowOpen else {return}
        
        var movingHorizontally = false
        if let panStartPoint = self.panStartPoint {
            movingHorizontally = fabsf(Float(panStartPoint.y)) < fabsf(Float(panStartPoint.x))
        }
        
        switch recognizer.state {
        case .began:
            self.panStartPoint = recognizer.translation(in: self.button)
            self.startingLeftLayoutConstraint = self.leftLayoutConstraint.constant
            
        case .changed:
            if movingHorizontally {
                let currentPoint = recognizer.translation(in: parentView)
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
            
        case .ended:
            if movingHorizontally {
                if abs(leftLayoutConstraint.constant) < stashViewWidth {
                    leftLayoutConstraint.constant = 0
                } else if abs(leftLayoutConstraint.constant) >= stashViewWidth {
                    leftLayoutConstraint.constant = -stashViewWidth
                    delegate?.onOpen(true)
                }
                UIView.animate(withDuration: 0.3, animations: {[weak self] in
                    self?.parentView.layoutIfNeeded()
                }) 
            }
            
        case .cancelled:
            if movingHorizontally {
                if leftLayoutConstraint.constant < stashViewWidth {
                    leftLayoutConstraint.constant = 0
                } else if leftLayoutConstraint.constant >= stashViewWidth {
                    leftLayoutConstraint.constant = -stashViewWidth
                    delegate?.onOpen(true)
                }
                UIView.animate(withDuration: 0.3, animations: {[weak self] in
                    self?.parentView.layoutIfNeeded()
                }) 
            }
            
        default:
            print("Not handled")
        }
    }

    func setOpen(_ open: Bool, animated: Bool = true) {
        parentView.layoutIfNeeded()
        if open {
            leftLayoutConstraint.constant = -stashViewWidth
        } else {
            leftLayoutConstraint.constant = 0
        }
        UIView.animate(withDuration: 0.3, animations: {[weak self] in
            self?.parentView.layoutIfNeeded()
        }) 
    }

}

