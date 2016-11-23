//
//  Shapes.swift
//  shoppin
//
//  Created by ischuetz on 03/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

struct Shapes {
    
    static func arrowToRightBGPath(_ size: CGSize, arrowWidth aw: CGFloat)  -> CGPath {
        
        let w = size.width
        let h = size.height
        
        let path = CGMutablePath()
        
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: w - aw, y: 0))
        path.addLine(to: CGPoint(x: w, y: h / 2))
        path.addLine(to: CGPoint(x: w - aw, y: h))
        path.addLine(to: CGPoint(x: 0, y: h))
        
        path.closeSubpath()
        
        return path
    }
}
