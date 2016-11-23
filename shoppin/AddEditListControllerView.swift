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
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        
        let f = self.bounds
        
        if let pf = popupFrame {
            
            let bezierPath = UIBezierPath()
            
            bezierPath.move(to: f.origin)
            bezierPath.addLine(to: f.rightTop)
            bezierPath.addLine(to: f.rightBottom)
            
            bezierPath.addLine(to: CGPoint(x: pf.maxX, y: f.height)) // top right popup (starting from view's bottom)
            bezierPath.addLine(to: CGPoint(x: pf.maxX, y: pf.maxY)) // bottom right popup
            bezierPath.addLine(to: CGPoint(x: pf.minX, y: pf.maxY)) // bottom left popup
            bezierPath.addLine(to: CGPoint(x: pf.minX, y: f.height)) // top left popup
            
            bezierPath.addLine(to: f.leftBottom)
            
            bezierPath.close()
            
            return bezierPath.contains(point)
            
        } else {
            return f.contains(point)
        }
    }
}
