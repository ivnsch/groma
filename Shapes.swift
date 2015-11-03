//
//  Shapes.swift
//  shoppin
//
//  Created by ischuetz on 03/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

struct Shapes {
    
    static func arrowToRightBGPath(size: CGSize, arrowWidth aw: CGFloat)  -> CGPath {
        
        let w = size.width
        let h = size.height
        
        let path = CGPathCreateMutable()
        
        CGPathMoveToPoint(path , nil, 0, 0)
        CGPathAddLineToPoint(path, nil, w - aw, 0)
        CGPathAddLineToPoint(path, nil, w, h / 2);
        CGPathAddLineToPoint(path, nil, w - aw, h)
        CGPathAddLineToPoint(path, nil, 0, h)
        
        CGPathCloseSubpath(path)
        
        return path
    }
}
