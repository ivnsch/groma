//
//  SwipeToIncrementHelper.swift
//  shoppin
//
//  Created by ischuetz on 02/05/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

protocol SwipeToIncrementHelperDelegate {
    func currentQuantity() -> Int
    func onQuantityUpdated(quantity: Int)
    func onFinishSwipe()
}


class SwipeToIncrementHelper: NSObject, UIGestureRecognizerDelegate {
    
    private weak var view: UIView?
    
    private var panRecognizer: UIPanGestureRecognizer!
    private var panStartPoint: CGPoint!
    
    private var initQuantitySlider: Int = 0 // capture quantity when we start sliding
    
    var delegate: SwipeToIncrementHelperDelegate?
    
    var enabled: Bool = true
    
    init(view: UIView) {
        super.init()
        
        panRecognizer = UIPanGestureRecognizer(target: self, action: "onPanCell:")
        panRecognizer.delegate = self
        view.addGestureRecognizer(self.panRecognizer)
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
                let deltaForQuantity = Int(deltaX / 10)
                let updatedQuantity = max(0, initQuantitySlider + deltaForQuantity)
                delegate.onQuantityUpdated(updatedQuantity)
            }
            
        case .Ended:
            if movingHorizontally {
                delegate.onFinishSwipe()
            }
            
        case .Cancelled:
            QL3("Cancelled pan")
            
        default:
            QL3("Not handled: \(recognizer.state)")
        }
    }
    
}
