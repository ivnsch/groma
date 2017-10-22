//
//  SwipeToIncrementHelper.swift
//  shoppin
//
//  Created by ischuetz on 02/05/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

protocol SwipeToIncrementHelperDelegate: class {
    func currentQuantity() -> Float
    func onQuantityUpdated(_ quantity: Float)
    func onFinishSwipe()
    var swipeToIncrementEnabled: Bool {get}
}


class SwipeToIncrementHelper: NSObject, UIGestureRecognizerDelegate {
    
    fileprivate weak var view: UIView?
    
    fileprivate var panRecognizer: UIPanGestureRecognizer!
    fileprivate var panStartPoint: CGPoint!
    
    fileprivate var initQuantitySlider: Float = 0 // capture quantity when we start sliding
    
    weak var delegate: SwipeToIncrementHelperDelegate?
    
    init(view: UIView, cancelTouches: Bool = true) {
        self.view = view
        
        super.init()
        
        panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(SwipeToIncrementHelper.onPanCell(_:)))
        panRecognizer.delegate = self
        panRecognizer.cancelsTouchesInView = cancelTouches
        view.addGestureRecognizer(self.panRecognizer)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @objc func onPanCell(_ recognizer: UIPanGestureRecognizer) {

        guard let view = view else {logger.e("No view"); return}
        guard let delegate = delegate else {logger.e("No delegate"); return}

        let movingHorizontally = abs(recognizer.velocity(in: view).x) > abs(recognizer.velocity(in: view).y)
        
        switch recognizer.state {
        case .began:
            panStartPoint = recognizer.translation(in: view)
            initQuantitySlider = delegate.currentQuantity()
            
        case .changed:
            guard delegate.swipeToIncrementEnabled else {return} // here (instead of in .began) because of interaction with SwipeToDeleteHelper
            
            if movingHorizontally {
                let currentPoint = recognizer.translation(in: view)
                let deltaX = currentPoint.x - panStartPoint.x
                let deltaForQuantity = Int(deltaX / 20)
                let updatedQuantity = max(0, initQuantitySlider + Float(deltaForQuantity))
                delegate.onQuantityUpdated(updatedQuantity)
            }
    
        case .failed:
            logger.w("Failed pan")

        case .cancelled:
            logger.w("Cancelled pan")
            
        case .ended:
            
            panStartPoint = nil
            
            guard delegate.swipeToIncrementEnabled else {return}

            if movingHorizontally {
                delegate.onFinishSwipe()
            }
            
        default:
            logger.w("Not handled: \(recognizer.state)")
        }
    }
    
}
