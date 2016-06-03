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
    func currentQuantity() -> Int
    func onQuantityUpdated(quantity: Int)
    func onFinishSwipe()
}


class SwipeToIncrementHelper: NSObject, UIGestureRecognizerDelegate {
    
    private weak var view: UIView?
    
    private var panRecognizer: UIPanGestureRecognizer!
    private var panStartPoint: CGPoint!
    
    private var initQuantitySlider: Int = 0 // capture quantity when we start sliding
    
    weak var delegate: SwipeToIncrementHelperDelegate?
    
    var enabled: Bool = true
    
    init(view: UIView) {
        super.init()
        
        panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(SwipeToIncrementHelper.onPanCell(_:)))
        panRecognizer.delegate = self
        panRecognizer.cancelsTouchesInView = true
        view.addGestureRecognizer(self.panRecognizer)
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func onPanCell(recognizer: UIPanGestureRecognizer) {
        
        guard enabled else {return}
        guard let delegate = delegate else {QL4("No delegate"); return}

        var movingHorizontally = false
        if let panStartPoint = panStartPoint {
            movingHorizontally = fabsf(Float(panStartPoint.y)) < fabsf(Float(panStartPoint.x))
        }
        
        switch recognizer.state {
        case .Began:
            panStartPoint = recognizer.translationInView(view)
            initQuantitySlider = delegate.currentQuantity()
            
        case .Changed:
            
            if movingHorizontally {
                let currentPoint = recognizer.translationInView(view)
                let deltaX = currentPoint.x - panStartPoint.x
                let deltaForQuantity = Int(deltaX / 20)
                let updatedQuantity = max(0, initQuantitySlider + deltaForQuantity)
                delegate.onQuantityUpdated(updatedQuantity)
            }
    
        case .Failed:
            QL3("Failed pan")

        case .Cancelled:
            QL3("Cancelled pan")
            
        case .Ended:
            if movingHorizontally {
                delegate.onFinishSwipe()
            }
            
        default:
            QL3("Not handled: \(recognizer.state)")
        }
    }
    
}
