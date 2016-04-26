//
//  AddEditListControllerView.swift
//  shoppin
//
//  Created by ischuetz on 26/04/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

// Custom view for hit area including the popup. clipToBounds = false shows the popup but the overflowing area is not interactive, so we need this.
class AddEditListControllerView: UIView {

    var popupFrame: CGRect?
    
    override init(frame: CGRect) {

        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        
        let f = self.bounds
        
        if let pf = popupFrame {
            
            let bezierPath = UIBezierPath()
            
            bezierPath.moveToPoint(f.origin)
            bezierPath.addLineToPoint(f.rightTop)
            bezierPath.addLineToPoint(f.rightBottom)
            
            bezierPath.addLineToPoint(CGPointMake(pf.maxX, f.height)) // top right popup (starting from view's bottom)
            bezierPath.addLineToPoint(CGPointMake(pf.maxX, pf.maxY)) // bottom right popup
            bezierPath.addLineToPoint(CGPointMake(pf.minX, pf.maxY)) // bottom left popup
            bezierPath.addLineToPoint(CGPointMake(pf.minX, f.height)) // top left popup
            
            bezierPath.addLineToPoint(f.leftBottom)
            
            bezierPath.closePath()
            
            return bezierPath.containsPoint(point)
            
        } else {
            return f.contains(point)
        }
    }
}