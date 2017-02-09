//
//  SwipeToIncrementHelper.swift
//  shoppin
//
//  Created by ischuetz on 02/05/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

protocol SwipeToIncrementHelperDelegate: class {
    func currentQuantity() -> Float
    func onQuantityUpdated(_ quantity: Float)
    func onFinishSwipe()
}


class SwipeToIncrementHelper: NSObject, UIGestureRecognizerDelegate {
    
    fileprivate weak var view: UIView?
    
    fileprivate var panRecognizer: UIPanGestureRecognizer!
    fileprivate var panStartPoint: CGPoint!
    
    fileprivate var initQuantitySlider: Float = 0 // capture quantity when we start sliding
    
    weak var delegate: SwipeToIncrementHelperDelegate?
    
    var enabled: Bool = true
    
    init(view: UIView) {
        super.init()
        
        panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(SwipeToIncrementHelper.onPanCell(_:)))
        panRecognizer.delegate = self
        panRecognizer.cancelsTouchesInView = true
        view.addGestureRecognizer(self.panRecognizer)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func onPanCell(_ recognizer: UIPanGestureRecognizer) {
        
        guard enabled else {return}
        guard let delegate = delegate else {QL4("No delegate"); return}

        var movingHorizontally = false
        if let panStartPoint = panStartPoint {
            movingHorizontally = fabsf(Float(panStartPoint.y)) < fabsf(Float(panStartPoint.x))
        }
        
        switch recognizer.state {
        case .began:
            panStartPoint = recognizer.translation(in: view)
            initQuantitySlider = delegate.currentQuantity()
            
        case .changed:
            
            if movingHorizontally {
                let currentPoint = recognizer.translation(in: view)
                let deltaX = currentPoint.x - panStartPoint.x
                let deltaForQuantity = Int(deltaX / 20)
                let updatedQuantity = max(0, initQuantitySlider + Float(deltaForQuantity))
                delegate.onQuantityUpdated(updatedQuantity)
            }
    
        case .failed:
            QL3("Failed pan")

        case .cancelled:
            QL3("Cancelled pan")
            
        case .ended:
            if movingHorizontally {
                delegate.onFinishSwipe()
            }
            
        default:
            QL3("Not handled: \(recognizer.state)")
        }
    }
    
}
